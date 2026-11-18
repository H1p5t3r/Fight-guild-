extends SceneTree

var failures := 0
func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr(description)

func _initialize() -> void:
	var model := CombatModel.new()
	var original := model.data()
	var original_hash := model.fingerprint()
	var edited := original.duplicate(true)
	var boxes := {"legs": [-1000, 0, 1000, 5000], "torsoArms": [-2000, 5000, 2000, 11000], "head": [-1000, 11000, 1000, 14000]}
	for phase in CombatModel.HURT_PHASES:
		edited.characters[5].moves[0].hurtboxes[phase] = boxes.duplicate(true)
	edited.characters[5].moves[0].hurtboxes.active.extension = [2000, 7000, 4000, 9000]
	check(model.load_data(edited).is_empty(), "Custom hurtboxes rejected")
	check(model.fingerprint() != original_hash, "Hurtboxes missing from online fingerprint")
	check(model.move(5, 4).hurtboxes.is_empty(), "Shared-sprite move changed")
	var custom_hash := model.fingerprint()
	model.reset([5, 0])
	for tick in range(1, 16):
		model.step(16 if tick == 1 else 0, 0)
		var f: Dictionary = model.state().players[0]
		var rects := model.core.boxes(0, 0)
		check(rects.size() == (16 if tick >= 5 and tick < 8 else 12), "Wrong hurtbox count at phase boundary")
		check(rects[0] == f.x - 1000 and rects[2] == f.x + 1000 and rects[1] == 0 and rects[3] == 5000, "Edited geometry not used by live fighter")
		if tick == 5:
			var snapshot := model.core.snapshot()
			model.step(0, 0)
			var expected := model.state_hash()
			check(model.core.restore(snapshot), "Snapshot restore failed")
			model.step(0, 0)
			check(model.state_hash() == expected, "Rollback differs with custom hurtboxes")
			check(model.core.restore(snapshot), "Could not resume fixture")
	var invalid := edited.duplicate(true)
	invalid.characters[5].moves[31].hurtboxes = {"active": boxes.duplicate(true)}
	invalid.characters[5].moves[31].hurtboxes.active.weapon = [0, 0, 100, 100]
	check(not model.load_data(invalid).is_empty() and model.fingerprint() == custom_hash, "Unknown/fifth body region accepted or partially applied")
	invalid.characters[5].moves[31].hurtboxes.active.erase("weapon")
	invalid.characters[5].moves[31].hurtboxes.active.head[3] = 50001
	check(not model.load_data(invalid).is_empty() and model.fingerprint() == custom_hash, "Oversized hurtbox accepted or partially applied")
	invalid.characters[5].moves[31].hurtboxes.active.head = [0, 0, 100, 99]
	check(not model.load_data(invalid).is_empty() and model.fingerprint() == custom_hash, "Subpixel hurtbox accepted")
	var saved := "user://hurtbox-roundtrip-test.json"
	check(model.save_file(saved).is_empty(), "Hurtbox save failed")
	model.restore_defaults()
	check(model.load_file(saved).is_empty() and model.fingerprint() == custom_hash, "Hurtbox save/load lost data")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(saved))
	var legacy := original.duplicate(true)
	legacy.schema = 12
	legacy.coreVersion = 12
	legacy.characters[5].moves[0].damage = 77
	for character in legacy.characters:
		character.moves.resize(32)
		for move in character.moves: move.erase("hurtboxes")
	check(model.load_data(legacy).is_empty() and model.move(5, 0).damage == 77 and model.move(5, 0).hurtboxes.is_empty(), "Version-12 migration changed tuning or body defaults")
	print("Godot attack hurtboxes, saves and rollback: %d failures" % failures)
	quit(1 if failures else 0)
