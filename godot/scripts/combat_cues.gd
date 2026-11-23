class_name CombatCues
extends RefCounted

# Output history mirrors rollback's input frames, but never enters its checksum.
const KEYS := ["frame", "kind", "actor", "character", "move", "serial", "x", "y", "facing", "strength", "flags", "variant"]
const HISTORY := 360
var frames := {}
var epoch := 0
var latest := -1

func reset() -> void:
	frames.clear()
	latest = -1
	epoch += 1

func capture(frame: int, frozen: bool, values: PackedInt32Array) -> void:
	# A replay replaces the predicted future, including contacts that disappeared.
	if frame <= latest:
		for key in frames.keys():
			if int(key) >= frame: frames.erase(key)
	var active: Array = frames.get(frame - 1, {}).get("active", []).duplicate(true)
	for cue in active: cue.age += 0 if frozen else 1
	active = active.filter(func(cue: Dictionary) -> bool: return cue.age < 12)
	var events := []
	for offset in range(0, values.size(), KEYS.size()):
		var cue := {"age": 0, "id": "%d:%d:%d" % [epoch, frame, offset / KEYS.size()]}
		for field in KEYS.size(): cue[KEYS[field]] = values[offset + field]
		events.append(cue)
		if cue.kind != 8 and cue.kind != 9: active.append(cue.duplicate())
	# Enough for trades and overlapping projectiles; bounded even with zero hitstop.
	if active.size() > 32: active = active.slice(active.size() - 32)
	frames[frame] = {"events": events, "active": active}
	frames.erase(frame - HISTORY)
	latest = frame

func visible_at(frame: int) -> Array:
	return frames.get(frame - 1, {}).get("active", [])

func events_at(frame: int) -> Array:
	return frames.get(frame, {}).get("events", [])
