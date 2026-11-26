class_name SuperAnimation
extends RefCounted

# Authored presentation tracks use only saved combat clocks. They intentionally
# live outside the compiled collision pose table; no image changes gameplay.
static var enabled := true

static func profile(character: int, slot: int) -> Dictionary:
	if not enabled: return {}
	return FighterArt.catalog().fighters[character].get("super_presentations", {}).get(str(slot), {})

static func selection(model: CombatModel, state: Dictionary, owner: int) -> Dictionary:
	var fighter: Dictionary = state.players[owner]
	var slot := int(fighter.move)
	var captured := int(state.get("pairKind", 0)) > 0 and int(state.get("pairOwner", -1)) == owner
	if captured: slot = int(state.pairMove)
	elif int(fighter.pairRecovery) > 0 and int(fighter.contact) != 0 and int(fighter.reaction) == 0 and int(fighter.stun) == 0:
		slot = int(fighter.lastMove)
	var spec := profile(int(fighter.character), slot)
	if spec.is_empty(): return {}
	var result := {"owner":owner,"character":int(fighter.character),"slot":slot,"spec":spec,"pose":0,"stage":"windup","tick":0,"facing":int(fighter.facing)}
	if captured:
		result.stage = "paired"
		result.facing = int(state.pairFacing)
		result.tick = paired_tick(int(state.pairClock),int(state.pairTicks),spec)
		result.pose = exposure(spec.paired, int(result.tick))
	elif int(fighter.pairRecovery) > 0:
		result.stage = "connected"
		result.tick = maxi(0, int(spec.owner_recovery)-int(fighter.pairRecovery))
		result.pose = exposure(spec.connected, int(result.tick))
	else:
		var move := model.move(int(fighter.character), slot)
		var age := int(fighter.age)
		var active := int(move.startup)
		if str(spec.get("mode",""))=="cast":
			if age<active:
				result.tick=age
				result.pose=exposure(spec.windup,age*100/maxi(1,active))
			else:
				result.stage="cast";result.tick=age-active
				result.pose=int(spec.active_pose)
				if age>=active+int(move.active):
					result.pose=exposure(spec.recovery,(age-active-int(move.active))*100/maxi(1,int(move.recovery)))
			return result
		if age >= active and age < active + int(move.active):
			result.stage = "active"; result.pose = 1; result.tick = age-active
			# Optional active-frame exposures follow the authored hitbox timeline.
			# Hitstop holds this same saved age, including separate blocked hits.
			if spec.has("active_keys"):result.pose=exposure(spec.active_keys,int(result.tick))
		elif age >= active + int(move.active):
			result.stage = "whiff"
			result.tick = age-active-int(move.active)
			var percent := int(result.tick)*100/maxi(1,int(move.recovery))
			result.pose = exposure(spec.whiff,percent) if spec.has("whiff") else 1 if percent < 16 else 0 if percent < 65 else 15
	return result

static func paired_tick(tick: int, total: int, spec: Dictionary) -> int:
	if str(spec.get("mode","carry"))!="strike": return tick
	var authored := int(spec.pair_ticks)
	var actual := [0,total*45/100,total*78/100,total]
	var target := [0,authored*45/100,authored*78/100,authored]
	# Preserve the native impact boundaries even when edited durations round to
	# different integer ticks. A linear percentage alone can show the load on hit.
	for i in 3:
		if tick<=int(actual[i+1]):
			return int(target[i])+(tick-int(actual[i]))*(int(target[i+1])-int(target[i]))/maxi(1,int(actual[i+1])-int(actual[i]))
	return authored

static func exposure(keys: Array, tick: int) -> int:
	var pose := int(keys[0][1])
	for key in keys:
		if tick < int(key[0]): break
		pose = int(key[1])
	return pose

static func replaces_impact(cue: Dictionary, sprites: Array[Sprite2D]) -> bool:
	var animation: Dictionary = sprites[int(cue.actor)].get_meta("super_animation",{})
	if animation.is_empty() or int(cue.move)!=int(animation.slot) or int(cue.kind) not in [1,3,4]: return false
	return str(animation.stage)=="connected" or (str(animation.stage)=="paired" and animation.spec.has("effects"))

static func audio_events(core: Object, previous_kind: int, previous_clock: int) -> Array:
	var paired_kind: int = core.read_value(-1,22)
	if paired_kind==8 or previous_kind==8:
		for p in 2:
			var character: int = core.read_value(p,13)
			var slot: int = core.read_value(-1,25) if paired_kind==8 else core.read_value(p,11)
			var spec := profile(character,slot)
			if not spec.has("sounds"): continue
			var sample := ""
			if paired_kind==8 and core.read_value(-1,24)==p:
				var tick: int = core.read_value(-1,23)
				for mark in spec.sounds:
					if mark=="finish": continue
					var target := int(mark)
					var total: int = core.read_value(-1,26)
					if target==int(spec.pair_ticks)*45/100: target=total*45/100
					elif target==int(spec.pair_ticks)*78/100: target=total*78/100
					if (target==0 and previous_kind!=8) or (target>0 and previous_clock<target and tick>=target): sample=str(spec.sounds[mark])
			elif paired_kind==0 and core.read_value(p,92)>0:
				sample=str(spec.sounds.get("finish",""))
			if not sample.is_empty():
				return [{"kind":13,"actor":p,"character":character,"move":slot,"serial":core.read_value(p,91),"strength":4,"sound":"../supers-v2/"+sample+".wav"}]
		return []
	if core.read_value(-1,22)!=7: return []
	var owner: int = core.read_value(-1,24)
	if core.read_value(owner,13)!=0 or core.read_value(-1,25)!=16 or profile(0,16).is_empty(): return []
	var clock: int = core.read_value(-1,23)
	var sound := ""
	if previous_kind!=7: sound="clamp"
	elif previous_clock<12 and clock>=12: sound="lift"
	elif previous_clock<88 and clock>=88: sound="fall"
	if sound.is_empty(): return []
	return [{"kind":13,"actor":owner,"character":0,"move":16,
		"serial":core.read_value(owner,CombatModel.STATE_FIELDS.find("attackSerial")),
		"strength":3,"sound":"../supers-v2/sky_foundry_"+sound+".wav"}]

static func cast_audio(core: Object, previous_projectiles: Array) -> Array:
	var events:=[]
	for i in 16:
		var index:=-2-i
		if core.read_value(index,0)<=0 or int(previous_projectiles[i])>0:continue
		var owner:int=core.read_value(index,1)
		var character:int=core.read_value(owner,13)
		var slot:int=core.read_value(index,8)
		var spec:=profile(character,slot)
		if str(spec.get("mode",""))!="cast" or not spec.get("sounds",{}).has("spawn"):continue
		events.append({"kind":13,"actor":owner,"character":character,"move":slot,"serial":core.read_value(owner,91),"strength":3,"sound":"../supers-v2/"+str(spec.sounds.spawn)+".wav"})
	return events

static func foreground(state: Dictionary) -> int:
	var owner := int(state.get("pairOwner", -1))
	if int(state.get("pairKind",0)) != 7 or owner not in [0,1]: return -1
	if profile(int(state.players[owner].character), int(state.pairMove)).is_empty(): return -1
	var tick := int(state.pairClock)
	return owner if tick >= 12 and tick < 88 else 1-owner

static func grip(sprite: Sprite2D, character: int) -> Vector2:
	var frame: Dictionary = FighterArt.sheet(character, str(sprite.get_meta("phase"))).frames[int(sprite.get_meta("pose"))]
	return sprite.position + (Vector2(frame.grip[0],frame.grip[1])+sprite.offset)*sprite.scale

static func present(sprites: Array[Sprite2D], model: CombatModel, state: Dictionary, world_scale: float) -> void:
	for sprite in sprites: sprite.set_meta("super_animation", {})
	for owner in 2:
		var cue := selection(model,state,owner)
		if cue.is_empty(): continue
		var fighter: Dictionary = state.players[owner]
		var sprite := sprites[owner]
		FighterArt.apply(sprite,int(fighter.character),str(cue.spec.phase),int(cue.pose),world_scale,int(cue.facing))
		sprite.set_meta("super_animation",cue)
		if str(cue.stage)=="connected" and int(cue.tick)==0 and int(state.hitstop)>0 and cue.spec.get("finish_receiver","") in ["chest","head"]:
			var reaction: Dictionary = state.players[1-owner].duplicate()
			reaction.reaction=0;reaction.stun=1;reaction.guarding=0
			CombatReactions.apply(sprites[1-owner],reaction,{"flags":6 if cue.spec.finish_receiver=="head" else 4,"age":2},world_scale)
			sprites[1-owner].set_meta("super_role","receiver")
		if str(cue.stage) != "paired" or str(cue.spec.get("mode","carry")) != "carry": continue
		var victim := sprites[1-owner]
		var receiver := int(state.players[1-owner].character)
		var original := victim.position
		FighterArt.apply(victim,receiver,"knockdown_back",0,world_scale,-int(cue.facing))
		var frame: Dictionary = FighterArt.sheet(receiver,"knockdown_back").frames[0]
		var bounds: Array = frame.bounds
		var anchor := Vector2(frame.pivot[0],lerpf(float(bounds[1]),float(bounds[3]),0.82))
		# The hand supports the underside of the torso through the entire lift.
		# Rotation is a rigid carried-body turn; no limb warping or size changes.
		var angle := 0.0
		if int(cue.tick) >= 65: angle = -0.12*float(cue.facing)
		victim.rotation = angle
		victim.position = grip(sprite,int(fighter.character)) - ((anchor+victim.offset)*victim.scale).rotated(angle)
		victim.set_meta("grab_offset",victim.position-original)
		victim.set_meta("super_role","receiver")
		for child in victim.get_children():
			if child is Sprite2D: child.visible = false

static func draw_effect(canvas: CanvasItem, cue: Dictionary, key: int, box: Rect2, opacity: float, origin: Vector2, scale: float) -> void:
	var texture := FighterArt.texture(int(cue.character),str(cue.spec.fx_phase),key)
	canvas.draw_set_transform(origin,0.0,Vector2(float(cue.facing)*scale,scale))
	canvas.draw_texture_rect(texture,box,false,Color(1,1,1,opacity))
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_projectile_contacts(canvas: CanvasItem, cues: Array, project: Callable, scale: float) -> void:
	for contact in CombatImpacts.visible(cues):
		if int(contact.kind) not in [1,2,3,4,6] or (int(contact.flags)&1)==0:continue
		var spec:=profile(int(contact.character),int(contact.move))
		if not spec.has("projectile_contact"):continue
		var age:=int(contact.age)
		if age>=10:continue
		var track:Dictionary=spec.projectile_contact
		var key:=int(track.keys[0] if age<3 else track.keys[1])
		var box:Array=track.box
		var cue:={"character":contact.character,"facing":contact.facing,"spec":spec}
		draw_effect(canvas,cue,key,Rect2(box[0],box[1],box[2],box[3]),0.75 if age<3 else 0.6*float(10-age)/7.0,project.call(Vector2(contact.x,contact.y)),scale)

static func draw_behind(canvas: Control, sprites: Array[Sprite2D], _state: Dictionary, scale: float) -> void:
	for owner in 2:
		var cue: Dictionary = sprites[owner].get_meta("super_animation",{})
		if cue.is_empty():continue
		var tick := int(cue.tick)
		if str(cue.stage)=="paired":
			var shade := minf(float(tick)/12.0,float(int(cue.spec.pair_ticks)-tick)/12.0)*0.24
			canvas.draw_rect(Rect2(Vector2.ZERO,canvas.size),Color(0.025,0.029,0.035,clampf(shade,0.0,0.24)))
		if cue.spec.has("effects"):
			draw_track(canvas,sprites,cue,_state,scale,true)
			continue
		if str(cue.stage)!="paired":continue
		var point := sprites[owner].position
		if tick >= 12 and tick < 30:
			draw_effect(canvas,cue,0,Rect2(-75,-175,160,205),0.75*float(30-tick)/18.0,point,scale)
		elif tick >= 88 and tick < 100:
			draw_effect(canvas,cue,1,Rect2(-80,-210,180,220),0.8,point,scale)

static func draw_front(canvas: CanvasItem, sprites: Array[Sprite2D], state: Dictionary, scale: float) -> void:
	for owner in 2:
		var cue: Dictionary = sprites[owner].get_meta("super_animation",{})
		if cue.is_empty(): continue
		if cue.spec.has("effects"):
			draw_track(canvas,sprites,cue,state,scale,false)
			continue
		var tick := int(cue.tick)
		if str(cue.stage) == "paired" and tick < 6:
			draw_effect(canvas,cue,2,Rect2(-17,-17,34,34),0.88,grip(sprites[owner],0),scale)
		elif str(cue.stage) == "connected":
			var age := int(cue.spec.release_freeze)-mini(int(state.hitstop),int(cue.spec.release_freeze)) if tick == 0 else int(cue.spec.release_freeze)+tick
			if age >= 30: continue
			var key := 3 if age < 4 else 4 if age < 12 else 5
			var alpha := 0.95 if age < 12 else 0.7*float(30-age)/18.0
			draw_effect(canvas,cue,key,Rect2(-110,-85,260,92),alpha,sprites[owner].position,scale)

static func draw_track(canvas: CanvasItem, sprites: Array[Sprite2D], cue: Dictionary, state: Dictionary, scale: float, behind: bool) -> void:
	var tick := int(cue.tick)
	if str(cue.stage)=="connected":
		tick = int(cue.spec.release_freeze)-mini(int(state.hitstop),int(cue.spec.release_freeze)) if tick==0 else int(cue.spec.release_freeze)+tick
	for item in cue.spec.effects:
		if str(item.stage)!=str(cue.stage) or bool(item.get("behind",false))!=behind: continue
		if tick<int(item.start) or tick>=int(item.end): continue
		var origin := sprites[int(cue.owner)].position
		if item.get("anchor", "owner")=="receiver": origin=sprites[1-int(cue.owner)].position
		var box: Array = item.box
		if item.has("contact_box") and int(state.players[int(cue.owner)].contact)!=0:
			origin=sprites[1-int(cue.owner)].position
			box=item.contact_box
		if item.get("stop_at_guard",false) and (int(state.players[int(cue.owner)].contact)!=0 or str(cue.stage)=="paired"):
			# Keep the hook trail connected to its owner and end at the guard.
			# This is a drawing rectangle only; collision and pushback stay native.
			var distance:float=(sprites[1-int(cue.owner)].position.x-origin.x)*float(cue.facing)/scale
			box=[box[0],box[1],maxf(1.0,distance-20.0-float(box[0])),box[3]]
		var opacity: float = item.get("opacity",0.85)
		if item.get("fade",false): opacity*=float(int(item.end)-tick)/maxi(1,int(item.end)-int(item.start))
		draw_effect(canvas,cue,int(item.key),Rect2(box[0],box[1],box[2],box[3]),opacity,origin,scale)
