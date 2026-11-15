extends SceneTree

var failures := 0
func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr(description)

func _initialize() -> void:
	var model := CombatModel.new()
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/fighter_collision.json"))
	# Catch stale native binaries, wrong pivots/scale and dropped authored body parts.
	for character in 6:
		for phase_index in 3:
			var phase: String = ["active", "windup", "block"][phase_index]
			var art := FighterArt.sheet(character, phase)
			var poses: Array = source.fighters[character].poses[phase]
			for pose in poses.size():
				var expected := PackedInt32Array()
				var pivot: Array = art.frames[pose].pivot
				for rect in poses[pose].hurt:
					expected.append(floori((float(rect[0]) - pivot[0]) * 15000.0 / art.body_height))
					expected.append(floori((float(pivot[1]) - rect[3]) * 15000.0 / art.body_height))
					expected.append(ceili((float(rect[2]) - pivot[0]) * 15000.0 / art.body_height))
					expected.append(ceili((float(pivot[1]) - rect[1]) * 15000.0 / art.body_height))
				check(model.core.pose_boxes(character, phase_index, pose) == expected, "Compiled body differs from sprite source: %d / %s / %d" % [character, phase, pose])
		model.reset([character, (character + 1) % 6])
		var push: PackedInt32Array = model.core.boxes(0, 1)
		check(push[2] - push[0] == source.fighters[character].push.halfWidth * 2, "Push width differs from source")
		check(push[3] - push[1] == source.fighters[character].push.standingHeight, "Push height differs from source")
		for slot in CombatModel.MOVE_IDS.size():
			var move := model.move(character, slot)
			check(move.startup >= 5, "Invalid shipped startup")
			check(move.hitboxBack < move.reach and move.height > 0, "Empty shipped hitbox")
	print("Godot compiled collision: ", failures, " failures; 144 pose mappings, push profiles, 132 move definitions")
	quit(1 if failures else 0)
