class_name PoseSmear
extends RefCounted

static var bodies: Dictionary = {}

static func patch(f: Dictionary, part: int) -> Dictionary:
	if bodies.is_empty(): bodies = JSON.parse_string(FileAccess.get_file_as_string("res://data/fighter_collision.json"))
	var phase: String = FighterArt.PHASES[f.posePhase]
	var sheet := FighterArt.sheet(f.character, phase)
	var tile: Dictionary = sheet.frames[f.poseIndex]
	var body: Dictionary = bodies.fighters[f.character].poses[phase][f.poseIndex]
	var r: Array
	if part == 2:
		r = body.hurt.legs.duplicate()
		r[1] += (r[3] - r[1]) * 0.4
	elif part == 3:
		r = body.strike.duplicate() if body.has("strike") else [tile.bounds[0] + (tile.bounds[2] - tile.bounds[0]) * 0.65, body.hurt.head[3], tile.bounds[2], body.hurt.legs[1] + (body.hurt.legs[3] - body.hurt.legs[1]) * 0.4]
	else:
		r = body.hurt.get("extension", body.hurt.torsoArms).duplicate()
		if not body.hurt.has("extension"): r[0] += (r[2] - r[0]) * 0.6
		r[1] = maxf(r[1], body.hurt.head[3])
	r = [maxf(0, r[0]), maxf(0, r[1]), minf(tile.region[2], r[2]), minf(tile.region[3], r[3])]
	if r[2] - r[0] < 2 or r[3] - r[1] < 2: return {}
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	var factor: float = 150.0 / sheet.body_height
	for xy in [Vector2(r[0], r[1]), Vector2(r[2], r[1]), Vector2(r[2], r[3]), Vector2(r[0], r[3])]:
		points.append(Vector2(f.x / 100.0 + f.facing * (xy.x - tile.pivot[0]) * factor, f.y / 100.0 - (xy.y - tile.pivot[1]) * factor))
		uv.append(xy + Vector2(tile.region[0], tile.region[1]))
	return {"file": tile.get("file", sheet.file), "center": (points[0] + points[2]) * 0.5, "points": points, "uv": uv}

static func plan(previous: Dictionary, current: Dictionary, model: CombatModel) -> Dictionary:
	if previous.is_empty() or previous.character != current.character or previous.facing != current.facing or current.teleported: return {}
	var changed: bool = previous.posePhase != current.posePhase or previous.poseIndex != current.poseIndex
	var slot: int = current.move if current.move >= 0 else previous.move
	var settings := model.move(current.character, slot) if slot >= 0 else model.movement(current.character)
	if settings.smearMode == 0: return {}
	if slot >= 0 and settings.smearMode == 2:
		var beat := false
		for i in range(1, 5):
			if settings["smearFrame%d" % i] > 0 and current.move >= 0 and current.age == settings["smearFrame%d" % i] and previous.age != current.age: beat = true
		if not beat: return {}
	elif not changed: return {}
	var part: int = settings.smearPart
	if part == 0: part = 2 if slot < 0 and current.posePhase in [6, 7] else 1
	var source := patch(previous, part)
	var target := patch(current, part)
	if source.is_empty() or target.is_empty(): return {}
	var delta: Vector2 = target.center - source.center
	var axis := delta.normalized() if delta.length() > 1.0 else Vector2(current.facing, 0)
	var span := maxf(8.0, source.points[1].distance_to(source.points[0]))
	var stretch: float = minf(4.0, 1.0 + delta.length() / span) * settings.smearStretch / 100.0
	var center: Vector2 = (source.center + target.center) * 0.5
	var points := PackedVector2Array()
	for point in source.points:
		var offset: Vector2 = point - source.center
		points.append(center + offset + axis * offset.dot(axis) * (stretch - 1.0))
	source.points = points
	return source
