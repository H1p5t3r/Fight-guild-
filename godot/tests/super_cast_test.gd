extends SceneTree

var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;printerr(label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var args:=OS.get_cmdline_user_args()
	var character:=int(args[args.find("--character")+1]) if args.has("--character") else 1
	var slot:=int(args[args.find("--slot")+1]) if args.has("--slot") else 31
	var model:=CombatModel.new()
	var batch:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	check(model.load_file("res://data/workshop/"+str(batch.file)).is_empty(),"Import")
	var fingerprint:=model.fingerprint();var move:=model.move(character,slot)
	var spec:=SuperAnimation.profile(character,slot);var body:=FighterArt.sheet(character,spec.phase)
	var arena=load("res://scripts/arena.gd").new();arena.size=Vector2(1280,720);root.add_child(arena)
	await process_frame
	var seen:={};var wave_seen:={}
	for owner in 2:
		for facing in [-1,1]:
			for blocked in [false,true]:
				model.reset([character,4] if owner==0 else [4,character])
				model.core.preview_place(owner,50000-facing*11000,0,10000)
				model.core.preview_place(1-owner,50000+facing*11000,0,0)
				check(model.core.preview_begin(owner,slot)==1,"Start")
				var spawn_sounds:=0;var plant_sounds:=0;var free_with_wave:=false
				var restored:=PackedByteArray();var replay_hash:=0
				for tick in 250:
					var state:=model.state();var saved:PackedByteArray=model.core.snapshot();var cue:=SuperAnimation.selection(model,state,owner)
					arena.refresh(model,state,false,false)
					check(model.core.snapshot()==saved,"Art mutated simulation")
					check(int(state.pairKind)==0,"Utility cast captured receiver")
					if not cue.is_empty():
						seen[int(cue.pose)]=true
						check(is_equal_approx(arena.sprites[owner].scale.y,150.0/body.body_height*arena.size.x/1000.0*arena.camera_zoom),"Scale changed")
						if int(state.players[owner].age)==int(move.startup):check(int(cue.pose)==int(spec.active_pose),"First active missed ground strike")
						arena.refresh(model,state,false,true)
						check(int(arena.sprites[owner].get_meta("pose"))==int(cue.pose),"Pause altered pose")
					if not state.projectiles.is_empty():
						if int(state.players[owner].move)<0:free_with_wave=true
						for q in state.projectiles:
							var art:=FighterArt.projectile_art(character,slot,q.life,q.age)
							wave_seen[str(art.region)]=true
							check(art.file.contains("supers-v2"),"Old projectile art")
					if tick==80:restored=saved
					if tick==110:replay_hash=model.state_hash()
					var guard:=(2 if facing>0 else 1)|4
					model.step(guard if blocked and owner==1 else 0,guard if blocked and owner==0 else 0)
					for event in model.cues.events_at(model.frame()-1):
						if event.has("sound"):spawn_sounds+=1
						if int(event.kind)==8:
							check(CombatAudio.layers(event)[0].file.ends_with(str(spec.sounds.cast)+".wav"),"Cast sound routing")
							plant_sounds+=1
						if int(event.kind) in [1,2,3,4]:check(not CombatAudio.layers(event).is_empty(),"Lost projectile contact audio")
						if spec.sounds.has("pulse") and int(event.kind) in [1,2,3,4] and (int(event.get("flags",0))&1)!=0:
							var layers:=CombatAudio.layers(event)
							check(layers.any(func(layer:Dictionary)->bool:return str(layer.file).ends_with(str(spec.sounds.pulse)+".wav")),"Missing field contact pulse")
							if int(event.kind)==2:check(layers.size()>1,"Pulse replaced guard feedback")
				check(free_with_wave,"Caster remained locked to projectile")
				check(spawn_sounds==1 and plant_sounds==1,"Repeated/missing cast sounds")
				var damage:=1000-int(model.state().players[1-owner].health)
				print("owner ",owner," face ",facing," block ",blocked," damage ",damage," expected ",(move.chipDamage if blocked else move.damage)*int(move.projectileHits))
				check(damage==int(move.chipDamage)*int(move.projectileHits) if blocked else damage==int(move.damage)*int(move.projectileHits),"Contact damage changed")
				check(model.core.restore(restored),"Restore")
				var guard:=(2 if facing>0 else 1)|4
				for tick in 30:model.step(guard if blocked and owner==1 else 0,guard if blocked and owner==0 else 0)
				check(model.state_hash()==replay_hash,"Replay diverged")
	print("Body keys ",seen.keys())
	check(seen.size()==body.frames.size(),"Missing body key")
	model.reset([character,4]);model.core.preview_place(0,15000,0,10000);model.core.preview_place(1,85000,0,0);model.core.preview_begin(0,slot)
	for tick in 230:
		var state:=model.state()
		for q in state.projectiles:
			var art:=FighterArt.projectile_art(character,slot,q.life,q.age)
			wave_seen[str(art.region)]=true
		model.step(0,0)
	check(int(model.state().players[1].health)==1000,"Whiff dealt damage")
	check(wave_seen.size()==6,"Missing projectile key")
	check(model.fingerprint()==fingerprint,"Data changed")
	if character==2 and slot==31:
		for placement in [[1,15000],[0,25000],[2,35000]]:
			model.reset([character,4]);model.core.preview_place(0,15000,0,10000);model.core.preview_place(1,85000,0,0);model.core.preview_begin(0,slot)
			for tick in 100:
				model.step(int(placement[0]),0)
				if not model.state().projectiles.is_empty():break
			var field:Dictionary=model.state().projectiles[0]
			check(int(field.x)==15000+int(placement[1]) and int(field.vx)==0,"Stationary field placement changed")
		model.reset([character,4]);model.core.preview_place(0,15000,0,10000);model.core.preview_place(1,85000,0,0);model.core.preview_begin(0,slot)
		for tick in 100:model.step(0,0)
		check(not model.state().projectiles.is_empty(),"Field ended before interruption test")
		model.core.preview_place(1,int(model.state().players[0].x)+4000,0,0)
		model.core.preview_begin(1,0)
		var interrupted:=false
		for tick in 40:
			model.step(0,0)
			if int(model.state().players[0].health)<1000:
				interrupted=true;check(model.state().projectiles.is_empty(),"Cloud survived Smoke being hit");break
		check(interrupted,"Interruption strike missed Smoke")
	for timing in [[24,1,18,32],[10,2,20,18]]:
		var data:=model.data()
		for i in 4:data.characters[character].moves[slot][["startup","active","recovery","projectileSpawnFrame"][i]]=timing[i]
		check(model.load_data(data).is_empty(),"Edited cast import")
		model.reset([character,4]);model.core.preview_place(0,15000,0,10000);model.core.preview_place(1,85000,0,0);model.core.preview_begin(0,slot)
		var first_active:=false;var spawn_sounds:=0
		for tick in 200:
			var state:=model.state();var actor:Dictionary=state.players[0]
			if int(actor.move)==slot and int(actor.age)==int(timing[0]):
				check(int(SuperAnimation.selection(model,state,0).pose)==int(spec.active_pose),"Edited first active desynchronized")
				first_active=true
			model.step(0,0)
			for event in model.cues.events_at(model.frame()-1):
				if event.has("sound"):
					check(int(model.state().players[0].age)==int(timing[3]),"Spawn sound not on actual edited spawn")
					spawn_sounds+=1
		check(first_active and spawn_sounds==1,"Edited cast lost strike or sound")
	arena.queue_free();await process_frame
	print("%s cast animation: %d checks / %d failures"%[CombatSupers.title(character,slot),checks,failures])
	quit(1 if failures else 0)
