class_name CombatMovement
extends RefCounted

# Presentation-only movement drawings. The core's canonical poses, hurtboxes,
# travel and action clocks remain authoritative. Nothing here advances on a
# render timer, so pause, hitstop and restored snapshots produce the same art.
const DIRECTORY := "res://assets/fighters/movement-v1/"
static var manifest: Dictionary = {}
static var textures: Dictionary = {}

static func catalog() -> Dictionary:
	if manifest.is_empty(): manifest = JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY + "manifest.json"))
	return manifest

static func selection(fighter: Dictionary, movement: Dictionary) -> Dictionary:
	if int(fighter.character) != 5: return {}
	# Do not replace an action's final displayed tick, guard, hit reaction, grab,
	# knockdown or recovery lock with an idle flight/landing drawing.
	if int(fighter.move) >= 0 or int(fighter.get("displayMove", -1)) >= 0: return {}
	if int(fighter.reaction) != 0 or int(fighter.stun) > 0 or int(fighter.get("pairRecovery", 0)) > 0: return {}
	if int(fighter.faultless) != 0 or (int(fighter.guarding) != 0 and int(fighter.blockReaction) > 0): return {}
	if int(fighter.prejumpTime) > 0:
		# Hold compression for the authored preparation, then extend on its
		# last two ticks. Works with both inherited and edited prejump lengths.
		return {"sheet": "fillet_ground", "key": 1 if int(fighter.prejumpTime) > 2 else 2, "beat": "takeoff"}
	if int(fighter.y) > 0:
		var key := 2
		var beat := "flight"
		if int(fighter.dashTicks) > 0:
			# The arrest is stationary in the simulation; only its subsequent
			# velocity burst gets the forward-leaning drawing.
			var arrested := int(fighter.dashPause) > 0 or int(fighter.vx) == 0
			key = 5 if not arrested and int(fighter.vx) * int(fighter.facing) > 0 else 2
			# Fillet's back-airdash is disabled in the current kit. If enabled
			# in tuning, retain guard rather than leaning into the wrong direction.
			beat = "dash pause" if arrested else "dash burst" if key == 5 else "dash retreat"
		else:
			var velocity := int(fighter.vy)
			var threshold := maxi(1, int(movement.jumpSpeed) * 600 / 1450)
			var gravity := maxi(1, int(movement.gravity))
			key = 0 if velocity > threshold else 1 if velocity > 0 else 2 if velocity >= -gravity else 3 if velocity >= -threshold else 4
		return {"sheet": "fillet_flight", "key": key, "beat": beat}
	if int(fighter.landingTime) > 0:
		return {"sheet": "fillet_ground", "key": 3 if int(fighter.landingTime) > 1 else 4, "beat": "landing"}
	return {}

static func apply(sprite: Sprite2D, fighter: Dictionary, movement: Dictionary, world_scale: float) -> bool:
	var selected := selection(fighter, movement)
	sprite.set_meta("movement_beat", selected.get("beat", ""))
	if selected.is_empty(): return false
	var sheet: Dictionary = catalog().sheets[selected.sheet]
	var frame: Dictionary = sheet.frames[int(selected.key)]
	var identity := "%s/%d" % [selected.sheet, selected.key]
	if not textures.has(identity):
		var atlas := AtlasTexture.new()
		atlas.atlas = load(DIRECTORY + str(sheet.file))
		var rect: Array = frame.region
		atlas.region = Rect2(rect[0], rect[1], rect[2], rect[3])
		atlas.filter_clip = true
		textures[identity] = atlas
	sprite.texture = textures[identity]
	sprite.centered = false
	sprite.offset = -Vector2(frame.pivot[0], frame.pivot[1])
	var factor := 150.0 / float(sheet.body_height) * world_scale
	sprite.scale = Vector2(factor * int(fighter.facing), factor)
	return true
