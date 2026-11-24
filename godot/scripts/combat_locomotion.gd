class_name CombatLocomotion
extends RefCounted

# Visual history follows the same replay window as combat cues. Distance comes
# from resolved roots, never wall-clock time or absolute position on the stage.
# No part of this history is included in gameplay state/collision/checksums.
const HISTORY := 360
const SAMPLE_FIELDS := {0: "x", 1: "y", 2: "facing", 4: "move", 6: "stun", 7: "guarding", 12: "raw", 13: "character", 16: "faultless", 17: "blockReaction", 31: "reaction", 39: "vx", 40: "running", 41: "dashTicks", 51: "landingTime", 62: "prejumpTime", 64: "counterSlowHeld", 68: "dashKind", 69: "dashAge", 81: "stance", 92: "pairRecovery", 98: "displayMove"}
var frames := {}
var latest := -1

func reset() -> void:
	frames.clear()
	latest = -1

static func free_ground(f: Dictionary) -> bool:
	return int(f.y) == 0 and int(f.move) < 0 and int(f.get("displayMove", -1)) < 0 and int(f.stun) == 0 and int(f.reaction) == 0 and int(f.pairRecovery) == 0 and int(f.prejumpTime) == 0 and int(f.landingTime) == 0 and int(f.faultless) == 0 and not (int(f.guarding) and int(f.blockReaction)) and not (int(f.raw) & 4)

static func mode(f: Dictionary) -> String:
	if not free_ground(f) or int(f.vx) == 0: return ""
	if int(f.dashTicks) > 0: return "" # Dash drawings use their saved action age.
	var forward := int(f.vx) * int(f.facing) > 0
	if int(f.character) == 1:
		return "hammer_back" if not forward else "hammer_run" if int(f.running) else "hammer_walk"
	if int(f.character) == 3 and int(f.stance) != 0:
		return "tapper_forward" if forward else "tapper_back"
	return ""

static func stride(mode_name: String, profile: Dictionary) -> int:
	match mode_name:
		"hammer_run": return maxi(1, int(profile.runSpeed) * 3)
		"hammer_back": return maxi(1, int(profile.backWalkSpeed) * 5)
		"tapper_forward": return 600
		"tapper_back": return 500
	return maxi(1, int(profile.walkSpeed) * 5)

func capture(frame: int, frozen: bool, core: FightCore, previous_x: Array, profiles: Array) -> void:
	if frame <= latest:
		for key in frames.keys():
			if int(key) >= frame: frames.erase(key)
	var previous: Array = frames.get(frame - 1, [{}, {}])
	var result := []
	for player in 2:
		var f := {}
		for field in SAMPLE_FIELDS: f[SAMPLE_FIELDS[field]] = core.read_value(player, field)
		var prior: Dictionary = previous[player]
		if frozen or int(f.counterSlowHeld) != 0:
			result.append(prior.duplicate(true))
			continue
		var current := mode(f)
		var state := {"character": f.character, "mode": current, "key": 0, "distance": 0, "settle": 0}
		var compatible := int(prior.get("character", -1)) == int(f.character)
		if not current.is_empty():
			# Enter on a grounded contact key. Subsequent keys reflect distance
			# actually covered, so acceleration and corner obstruction stay legible.
			if compatible and prior.get("mode", "") == current:
				var spacing := stride(current, profiles[player])
				var travelled := absi(int(f.x) - int(previous_x[player]))
				var distance := int(prior.distance) + travelled
				state.key = (int(prior.key) + distance / spacing) % (4 if current.begins_with("tapper") else 8)
				state.distance = distance % spacing
				if travelled == 0:
					# A wall/opponent can stop roots while requested run velocity
					# remains nonzero. Plant a contact; never freeze a flight key.
					state.key = 0 if current.begins_with("tapper") or int(state.key) < 4 else 4
					state.distance = 0
		elif compatible and free_ground(f) and int(f.dashTicks) == 0:
			if not str(prior.get("mode", "")).is_empty():
				state.settle = 2
			elif int(prior.get("settle", 0)) > 0:
				state.settle = int(prior.settle) - 1
		result.append(state)
	frames[frame] = result
	frames.erase(frame - HISTORY)
	latest = frame

func at(frame: int, player: int) -> Dictionary:
	return frames.get(frame - 1, [{}, {}])[player]
