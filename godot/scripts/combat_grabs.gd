class_name CombatGrabs
extends RefCounted

# A / Collar Fold is a render-only paired atlas. Collision art and physics roots
# remain in FighterArt/the core; capture duration is read from the saved clocks.
const DIRECTORY := "res://assets/fighters/grabs-v1/"
static var manifest: Dictionary = {}
static var textures: Dictionary = {}

static func catalog() -> Dictionary:
	if manifest.is_empty(): manifest = JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY + "manifest.json"))
	return manifest

static func capture(model: CombatModel, state: Dictionary) -> Dictionary:
	var kind := int(state.get("pairKind", 0))
	if kind == 3: return {} # Wound retains its downed-to-standing presentation.
	if kind > 0:
		var owner := int(state.pairOwner)
		var slot := int(state.pairMove)
		var move := model.move(int(state.players[owner].character), slot)
		var total := int(state.pairTicks)
		if kind == 4 and int(move.actionType) == 4: total += int(move.grabFrames)
		return {"owner": owner, "slot": slot, "tick": int(state.pairClock), "total": maxi(1, total), "kind": kind, "facing": int(state.pairFacing)}
	for owner in 2:
		var fighter: Dictionary = state.players[owner]
		var receiver: Dictionary = state.players[1 - owner]
		if int(fighter.grabTime) <= 0 or int(receiver.reaction) != 6 or int(receiver.grabOwner) != owner: continue
		var move := model.move(int(fighter.character), int(fighter.move))
		var gate := 6 if int(fighter.move) in [23, 24] else 0
		var total := maxi(1, int(move.grabFrames) + gate)
		return {"owner": owner, "slot": int(fighter.move), "tick": total - int(fighter.grabTime), "total": total, "kind": 0, "facing": int(fighter.facing)}
	return {}

static func frame_for(character: int, key: int) -> Dictionary:
	var clip: Dictionary = catalog().get("fighters", {}).get(str(character), {})
	if clip.is_empty(): return {}
	var frame: Dictionary = clip.frames[key].duplicate()
	frame.file = frame.get("file", clip.file)
	frame.body_height = frame.get("body_height", clip.body_height)
	return frame

static func apply_frame(sprite: Sprite2D, frame: Dictionary, world_scale: float, facing: int) -> void:
	var identity := "%s/%s" % [frame.file, str(frame.region)]
	if not textures.has(identity):
		var texture := AtlasTexture.new()
		texture.atlas = load(DIRECTORY + str(frame.file))
		texture.region = Rect2(frame.region[0], frame.region[1], frame.region[2], frame.region[3])
		texture.filter_clip = true
		textures[identity] = texture
	sprite.texture = textures[identity]
	sprite.centered = false
	sprite.offset = -Vector2(frame.pivot[0], frame.pivot[1])
	var factor := 150.0 / float(frame.body_height) * world_scale
	sprite.scale = Vector2(factor * facing, factor)
	for child in sprite.get_children():
		if child is Sprite2D: child.visible = false

static func contact_point(sprite: Sprite2D, frame: Dictionary) -> Vector2:
	return sprite.position + (Vector2(frame.contact[0], frame.contact[1]) + sprite.offset) * sprite.scale

static func present(sprites: Array[Sprite2D], model: CombatModel, state: Dictionary, world_scale: float) -> void:
	for sprite in sprites:
		sprite.set_meta("grab_role", "")
		sprite.set_meta("grab_offset", Vector2.ZERO)
	var info := capture(model, state)
	if info.is_empty(): return
	var owner := int(info.owner)
	var attacker: Dictionary = state.players[owner]
	var receiver: Dictionary = state.players[1 - owner]
	var remaining := int(info.total) - int(info.tick)
	var back := int(info.slot) == 23
	var facing := int(info.facing)
	if int(attacker.character) == 0 and int(info.kind) in [6, 7]:
		# The core selects A/B/super owner drawings on the shared capture clock.
		# Keep those distinct lifts/slams instead of the generic collar overlay.
		FighterArt.apply(sprites[owner], 0, FighterArt.PHASES[int(attacker.posePhase)], int(attacker.poseIndex), world_scale, facing)
		var lifted := int(receiver.y) > int(attacker.y) + 4000
		var finish_tick: int = {14:82, 15:76, 16:100}.get(int(info.slot), int(info.total) - 7)
		if int(info.tick) >= int(finish_tick):
			FighterArt.apply(sprites[1-owner], int(receiver.character), "knockdown", 0, world_scale, -facing)
		elif lifted:
			FighterArt.apply(sprites[1-owner], int(receiver.character), "knockdown_back", 0, world_scale, -facing)
			# The saved airborne capture root is the carried pelvis, not a sole.
			# Register the horizontal body around it without resizing the drawing.
			var victim_sheet := FighterArt.sheet(int(receiver.character), "knockdown_back")
			var victim_frame: Dictionary = victim_sheet.frames[0]
			var b: Array = victim_frame.bounds
			sprites[1-owner].offset.y = -float(b[1] + b[3]) * 0.5
		else:
			apply_frame(sprites[1-owner], frame_for(int(receiver.character), 4), world_scale, -facing)
		for p in 2:
			sprites[p].set_meta("grab_role", "owner" if p == owner else "receiver")
			sprites[p].set_meta("grab_key", int(info.tick))
		return
	# Side switching is already authored in the simulation. The turning drawing
	# follows that crossing instead of holding a grip facing away from the victim.
	if back and int(info.tick) > int(info.total) / 2 and absi(int(receiver.x) - int(attacker.x)) > 1500:
		facing = 1 if int(receiver.x) > int(attacker.x) else -1
	var key := 0 if int(info.tick) < mini(8, int(info.total) / 3) else 2 if remaining <= 8 else 1
	var held := 3 if key == 0 else 5 if back and key == 2 else 4
	var owner_frame := frame_for(int(attacker.character), key)
	var victim_frame := frame_for(int(receiver.character), held)
	if owner_frame.is_empty() or victim_frame.is_empty(): return
	apply_frame(sprites[owner], owner_frame, world_scale, facing)
	apply_frame(sprites[1 - owner], victim_frame, world_scale, -facing)
	sprites[owner].set_meta("grab_role", "owner")
	sprites[1 - owner].set_meta("grab_role", "receiver")
	sprites[owner].set_meta("grab_key", key)
	sprites[1 - owner].set_meta("grab_key", held)
	# Preserve Fillet's approved knife finish and Tapper's headbutt/tackle instead
	# of replacing those distinct actions with a generic collar release.
	if int(attacker.character) == 5 and int(info.slot) in [45, 46] and remaining <= 16:
		var clock := 28 - remaining
		var clip: Dictionary = FighterArt.catalog().fighters[5].paired_animations[str(info.slot)]
		for index in range(clip.keys.size() - 1, -1, -1):
			var pose: Dictionary = clip.keys[index]
			if int(pose.tick) <= clock:
				FighterArt.apply(sprites[owner], 5, pose.phase, pose.pose, world_scale, facing)
				break
		return
	if int(attacker.character) == 3:
		if int(info.slot) == 40 and remaining <= 16:
			FighterArt.apply(sprites[owner], 3, "signature_active" if remaining <= 4 else "signature_windup", 30, world_scale, facing)
			FighterArt.apply(sprites[1 - owner], int(receiver.character), "knockdown_back", 0, world_scale, -facing)
			return
		if remaining <= 4:
			FighterArt.apply(sprites[owner], 3, "signature_active", 22, world_scale, facing)
			return
	# Register the hand/forearm horizontally against the receiver's front collar.
	# Both soles remain on their simulated floor; no stretching or vertical lift.
	# Bounded offsets avoid dragging a sprite away from its physical position at
	# corners or during a side switch. The residual is retained for review checks.
	var delta := contact_point(sprites[owner], owner_frame) - contact_point(sprites[1 - owner], victim_frame)
	var shift := clampf(delta.x * 0.5, -18.0 * world_scale, 18.0 * world_scale)
	sprites[owner].position.x -= shift
	sprites[1 - owner].position.x += shift
	sprites[owner].set_meta("grab_offset", Vector2(-shift, 0))
	sprites[1 - owner].set_meta("grab_offset", Vector2(shift, 0))
	sprites[owner].set_meta("grip_residual", contact_point(sprites[owner], owner_frame) - contact_point(sprites[1 - owner], victim_frame))
