extends SceneTree

var failures := 0
func check(value: bool, message: String) -> void:
	if not value: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var batch: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/" + batch.file))
	var model := CombatModel.new()
	check(model.load_data(source).is_empty(), "Uploaded batch did not import")
	var actual := model.data()
	var serialized: Dictionary = JSON.parse_string(JSON.stringify(actual))
	check(actual.schema == 20, "Batch was not upgraded")
	for group in ["inputRules", "momentumRules", "recoveryRules", "tuningRules", "jumpRules"]:
		for key in source[group]: check(actual[group][key] == source[group][key], "Global rule changed")
	for c in 6:
		for key in CombatModel.MOVEMENT_FIELDS:
			check(actual.characters[c].movement[key] == source.characters[c].movement[key], "Movement edit lost")
		for m in CombatModel.MOVE_IDS.size():
			var before: Dictionary = source.characters[c].moves[m]
			var after: Dictionary = actual.characters[c].moves[m]
			for key in CombatModel.FIELDS: check(before[key] == after[key], "Uploaded move value changed: %s/%s/%s" % [c,m,key])
			check(before.hurtboxes == serialized.characters[c].moves[m].hurtboxes, "Authored hurtboxes changed")
			check(before.hitboxTimeline == serialized.characters[c].moves[m].hitboxTimeline, "Authored hit timeline changed")
		if c == 2: check(actual.characters[c].moves[8].hurtWindowMask == 1 and actual.characters[c].moves[8].hurtWindowEnd == 17, "Smoke timed anti-air protection missing")
		elif c == 3: check(actual.characters[c].moves[8].hurtWindowMask == 1 and actual.characters[c].moves[8].hurtWindowEnd == 14, "Tapper timed anti-air protection missing")
		else: check(actual.characters[c].moves[8].hurtMaskWindup == 1 and actual.characters[c].moves[8].hurtMaskActive == 1 and actual.characters[c].moves[8].hurtMaskRecovery == 15, "Universal 6P protection missing")
	var game = load("res://scripts/main.gd").new()
	root.add_child(game)
	await process_frame
	game.load_workshop_draft()
	check(game.model.fingerprint() == model.fingerprint(), "Native batch loader differs from the submitted data")
	game.queue_free()
	await process_frame
	var edited := model.data()
	edited.characters[4].moves[8].hurtMaskActive = 0
	check(model.load_data(edited).is_empty(), "All-off hurtbox phase rejected")
	model.reset([4,5])
	model.step(2 | 16, 0)
	for tick in range(1, 9): model.step(0, 0)
	check(model.state().players[0].move == 8 and model.core.boxes(0,0).is_empty(), "Native active phase did not disable hurtboxes")
	check(model.core.boxes(0,1).size() == 4, "Hurtbox toggles changed the pushbox")
	var fingerprint := model.fingerprint()
	var invalid := model.data()
	invalid.characters[4].moves[8].hurtMaskActive = 16
	check(not model.load_data(invalid).is_empty() and model.fingerprint() == fingerprint, "Invalid vulnerability mask changed live data")
	var save := "user://batch-roundtrip-test.json"
	check(model.save_file(save).is_empty(), "Batch save failed")
	model.restore_defaults()
	check(model.load_file(save).is_empty() and model.fingerprint() == fingerprint, "Vulnerability masks lost on save/load")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save))
	print("Workshop batch, native loader and hurtbox switches: %d failures" % failures)
	quit(1 if failures else 0)
