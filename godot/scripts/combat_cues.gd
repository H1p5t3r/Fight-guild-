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

func capture(frame: int, frozen: bool, values: PackedInt32Array, held: Array = [false, false], receiving: Array = [true, true]) -> void:
	# A replay replaces the predicted future, including contacts that disappeared.
	if frame <= latest:
		for key in frames.keys():
			if int(key) >= frame: frames.erase(key)
	var active: Array = frames.get(frame - 1, {}).get("active", []).duplicate(true)
	var releases: Array = frames.get(frame - 1, {}).get("releases", []).duplicate(true)
	var reactions: Array = frames.get(frame - 1, {}).get("reactions", [{}, {}]).duplicate(true)
	for p in 2:
		if not receiving[p]: reactions[p] = {}
		elif not reactions[p].is_empty() and not frozen and not held[p]: reactions[p].age += 1
	for cue in active:
		cue.age += 0 if frozen else 1
		cue.screen_age = int(cue.get("screen_age", 0)) + 1
	for cue in releases:
		cue.age += 0 if frozen else 1
		cue.screen_age = int(cue.get("screen_age", 0)) + 1
	active = active.filter(func(cue: Dictionary) -> bool: return cue.age < 12)
	releases = releases.filter(func(cue: Dictionary) -> bool: return cue.age < 5 and cue.screen_age < 8)
	var events := []
	for offset in range(0, values.size(), KEYS.size()):
		var cue := {"age": 0, "screen_age": 0, "id": "%d:%d:%d" % [epoch, frame, offset / KEYS.size()]}
		for field in KEYS.size(): cue[KEYS[field]] = values[offset + field]
		events.append(cue)
		if cue.kind != 8 and cue.kind != 9: active.append(cue.duplicate())
		if cue.kind == 8:
			releases = releases.filter(func(old: Dictionary) -> bool: return old.actor != cue.actor)
			if cue.strength >= 2: releases.append(cue.duplicate())
		elif cue.kind in [1, 2, 3, 4, 5, 6, 7]:
			releases = releases.filter(func(old: Dictionary) -> bool: return old.actor != cue.actor or old.serial != cue.serial)
		# Only unguarded strikes create a receiver animation. Throws may emit
		# damage here, but their knockdown/capture states take visual precedence.
		var receiver := 1 - int(cue.actor)
		if cue.kind in [1, 3, 4] and receiving[receiver]: reactions[receiver] = cue.duplicate()
	# Enough for trades and overlapping projectiles; bounded even with zero hitstop.
	if active.size() > 32: active = active.slice(active.size() - 32)
	frames[frame] = {"events": events, "active": active, "reactions": reactions, "releases": releases}
	frames.erase(frame - HISTORY)
	latest = frame

func visible_at(frame: int) -> Array:
	return frames.get(frame - 1, {}).get("active", [])

func events_at(frame: int) -> Array:
	return frames.get(frame, {}).get("events", [])

func releases_at(frame: int) -> Array:
	return frames.get(frame - 1, {}).get("releases", [])

func reaction_at(frame: int, receiver: int) -> Dictionary:
	return frames.get(frame - 1, {}).get("reactions", [{}, {}])[receiver]
