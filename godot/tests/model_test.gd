extends SceneTree

var failures := 0
func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr(description)

func _initialize() -> void:
	var model := CombatModel.new()
	var original := model.data()
	var fingerprint := model.fingerprint()
	var edited := original.duplicate(true)
	edited.characters[0].moves[0].damage = 177
	check(model.load_data(edited).is_empty(), "Valid edit rejected")
	check(model.move(0, 0).damage == 177 and model.fingerprint() != fingerprint, "Edit did not apply")
	var invalid := original.duplicate(true)
	invalid.characters[1].moves[21].startup = 0
	check(not model.load_data(invalid).is_empty() and model.move(0, 0).damage == 177, "Invalid import changed live data")
	invalid.characters[1].moves[21].startup = 4294967301
	check(not model.load_data(invalid).is_empty(), "Integer overflow accepted")
	var saved := "user://test-moves.json"
	check(model.save_file(saved).is_empty(), "Save failed")
	model.restore_defaults()
	check(model.load_file(saved).is_empty() and model.move(0, 0).damage == 177, "Save/load failed")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(saved))
	check(model.load_data(original).is_empty() and model.fingerprint() == fingerprint, "Round trip changed default data")
	check(original.characters.size() == 6, "Six-fighter data missing")
	var legacy := edited.duplicate(true)
	legacy.schema = 1
	legacy.coreVersion = 1
	legacy.characters.resize(2)
	check(model.load_data(legacy).is_empty() and model.move(0, 0).damage == 177, "Legacy edits lost during migration")
	var expected_new_move: Dictionary = original.characters[5].moves[0].duplicate()
	expected_new_move.erase("id")
	check(model.move(5, 0) == expected_new_move, "New fighters missing migration defaults")
	for c in CombatModel.CHARACTERS.size():
		model.reset([c, (c + 1) % 6])
		var snapshot: PackedByteArray = model.core.snapshot()
		model.step(16, 0)
		check(model.core.restore(snapshot) and model.state().players[0].character == c, "Roster snapshot restore failed")
	check(model.load_data(original).is_empty(), "Could not restore full roster")
	for latency in [0, 1, 4, 8, 12]:
		var result := RollbackSession.trial(original, latency, 4, 1200)
		check(result.get("pass", false), "Rollback divergence: " + str(result))
	var session := RollbackSession.new(CombatModel.new())
	session.max_prediction = 3
	for frame in 3:
		session.submit(0, frame, 2)
		check(session.advance(), "Early prediction stall")
	check(not session.advance(), "Prediction limit ignored")
	for frame in 3:
		session.submit(1, frame, 1)
	check(session.advance(), "Session did not recover")
	check(not session.submit(1, 0, 2), "Conflicting actual input accepted")
	print("Godot data, independent simulations, rollback: ", failures, " failures")
	quit(1 if failures else 0)
