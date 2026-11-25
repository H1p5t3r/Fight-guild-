class_name CombatGrabs
extends RefCounted

# A / Collar Fold is a render-only paired atlas. Collision art and physics roots
# remain in FighterArt/the core; capture duration is read from the saved clocks.
const DIRECTORY := "res://assets/fighters/grabs-v1/"
static var manifest: Dictionary = {}
static var textures: Dictionary = {}

# Saved capture clocks control occlusion, including hitstop and rollback.
# Outside a capture the arena uses the latest connected attack as before.
static func foreground_player(state: Dictionary) -> int:
	var owner := int(state.get("pairOwner", -1))
	if int(state.get("pairKind", 0)) > 0 and owner in [0, 1]:
		if int(state.players[owner].character) == 0 and int(state.pairMove) in [23, 24, 41, 42]:
			return 1-owner if int(state.pairClock) >= int(state.pairTicks)-8 else owner
		if int(state.players[owner].character) == 0 and int(state.pairKind) in [6, 7]:
			var tick := int(state.pairClock)
			match int(state.pairMove):
				14: return 1-owner if tick < 12 or tick >= 70 else owner
				15: return owner if tick >= 32 and tick < 58 else 1-owner
				16: return owner if tick >= 12 and tick < 88 else 1-owner
		return owner
	for fighter in state.get("players", []):
		owner = int(fighter.get("grabOwner", -1))
		if int(fighter.get("reaction", 0)) == 6 and owner in [0, 1]:
			var attacker: Dictionary = state.players[owner]
			if int(attacker.character) == 0 and int(attacker.get("grabTime", 0)) <= 8: return 1-owner
			return owner
	return int(state.get("foregroundPlayer", -1))

static func anvil_receiver(sprites: Array[Sprite2D], state: Dictionary, info: Dictionary, world_scale: float) -> void:
	var owner := int(info.owner)
	var receiver: Dictionary = state.players[1-owner]
	var slot := int(info.slot)
	var tick := int(info.tick)
	var facing := int(info.facing)
	var lift_tick: int = {14:26, 15:32, 16:0}[slot]
	var finish_tick: int = {14:82, 15:76, 16:100}[slot]
	var victim := sprites[1-owner]
	var owner_frame: Dictionary = FighterArt.sheet(0, str(sprites[owner].get_meta("phase"))).frames[int(sprites[owner].get_meta("pose"))]
	var original := victim.position
	if tick >= finish_tick:
		FighterArt.apply(victim, int(receiver.character), "knockdown", 0, world_scale, facing if slot == 15 else -facing)
	elif tick >= lift_tick:
		FighterArt.apply(victim, int(receiver.character), "knockdown_back", 0, world_scale, -facing)
		var frame: Dictionary = FighterArt.sheet(int(receiver.character), "knockdown_back").frames[0]
		var b: Array = frame.bounds
		# Support the underside of the carried torso at the actual gripping hand.
		# The sprite's feet pivot is unsuitable for a horizontal body. Scale is
		# unchanged; its saved physics root still drives the release/landing.
		var body_anchor := Vector2(frame.pivot[0], lerpf(float(b[1]), float(b[3]), 0.82))
		var hand := sprites[owner].position + (Vector2(owner_frame.grip[0], owner_frame.grip[1]) + sprites[owner].offset) * sprites[owner].scale
		var carry := hand - (body_anchor + victim.offset) * victim.scale
		# Release over the last six capture ticks, avoiding a floor-position pop.
		var release := clampf(float(tick - (finish_tick - 6)) / 6.0, 0.0, 1.0)
		victim.position = carry.lerp(original, release)
	else:
		var frame := frame_for(int(receiver.character), 4)
		apply_frame(victim, frame, world_scale, -facing)
		var hand := sprites[owner].position + (Vector2(owner_frame.grip[0], owner_frame.grip[1]) + sprites[owner].offset) * sprites[owner].scale
		# Register the standing collar horizontally without pulling feet up.
		victim.position.x += clampf(hand.x - contact_point(victim, frame).x, -42.0*world_scale, 42.0*world_scale)
	for p in 2:
		sprites[p].set_meta("grab_role", "owner" if p == owner else "receiver")
		sprites[p].set_meta("grab_key", tick)
	victim.set_meta("grab_offset", victim.position - original)

static func catalog() -> Dictionary:
	if manifest.is_empty(): manifest = JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY + "manifest.json"))
	return manifest

static func capture(model: CombatModel, state: Dictionary) -> Dictionary:
	var kind := int(state.get("pairKind", 0))
	if kind in [3, 8]: return {} # Wound and strike supers own their presentation.
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
		if int(info.slot) == 16 and int(info.tick) < 12:
			# Sky Foundry catches an airborne body. Begin with the raised palm,
			# not the ground-grab reach plus an upright victim floating above it.
			var catch_pose: Dictionary = FighterArt.catalog().fighters[0].paired_animations["16"].keys[1]
			FighterArt.apply(sprites[owner], 0, str(catch_pose.phase), int(catch_pose.pose), world_scale, facing)
		anvil_receiver(sprites, state, info, world_scale)
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
