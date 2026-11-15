extends SceneTree

var failures := 0
func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr(description)

func _initialize() -> void:
	var model := CombatModel.new()
	var original := model.data()
	check(CombatModel.RULE_COUNT == CombatModel.RULES.size() + CombatModel.MOMENTUM_RULES.size() + CombatModel.RECOVERY_RULES.size() + CombatModel.TUNING_RULES.size() + CombatModel.JUMP_RULES.size(), "Rule layout differs from the adapter")
	var fingerprint := model.fingerprint()
	var edited := original.duplicate(true)
	edited.characters[0].moves[0].damage = 177
	check(model.load_data(edited).is_empty(), "Valid edit rejected")
	check(model.move(0, 0).damage == 177 and model.fingerprint() != fingerprint, "Edit did not apply")
	var invalid := original.duplicate(true)
	invalid.characters[1].moves[21].startup = 0
	check(not model.load_data(invalid).is_empty() and model.move(0, 0).damage == 177, "Invalid import changed live data")
	for startup in [1, 2, 3, 4]:
		invalid.characters[1].moves[21].startup = startup
		check(model.load_data(invalid).contains("at least 5 frames") and model.move(0, 0).damage == 177, "Sub-5f startup accepted or changed live data")
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
	legacy.erase("momentumRules")
	for character in legacy.characters:
		character.moves.resize(22)
		for definition in character.moves:
			definition.erase("chipDamage")
			definition.erase("guardBreak")
			definition.reserved = 0
	check(model.load_data(legacy).is_empty() and model.move(0, 0).damage == 177, "Legacy edits lost during migration")
	var expected_new_move: Dictionary = original.characters[5].moves[0].duplicate()
	expected_new_move.erase("id")
	check(model.move(5, 0) == expected_new_move, "New fighters missing migration defaults")
	legacy.schema = 2
	legacy.coreVersion = 2
	legacy.characters = edited.characters.duplicate(true)
	for character in legacy.characters:
		character.moves.resize(22)
		for definition in character.moves:
			definition.erase("chipDamage")
			definition.erase("guardBreak")
			definition.reserved = 0
	legacy.characters[5].moves[14].damage = 190
	check(model.load_data(JSON.parse_string(JSON.stringify(legacy))).is_empty(), "Schema-2 JSON migration rejected")
	check(model.move(5, 14).damage == 190 and model.move(5, 14).chipDamage == 19, "Migration lost edits or failed to add chip")
	var previous := edited.duplicate(true)
	previous.schema = 3
	previous.coreVersion = 3
	previous.momentumRules.fdDrain = 25
	previous.characters[0].moves[0].guardBreak = 1
	previous.characters[0].moves[0].chipDamage = 17
	previous.characters[0].moves[0].category = 3
	for character in previous.characters:
		character.moves.resize(22)
		for definition in character.moves:
			for field in ["counterHitstun", "counterHitstop", "reversalEligible"]: definition.erase(field)
	check(model.load_data(JSON.parse_string(JSON.stringify(previous))).is_empty(), "Schema-3 migration rejected")
	check(model.move(0, 0).damage == 177 and model.move(0, 0).guardBreak == 1 and model.move(0, 0).chipDamage == 17 and model.data().momentumRules.fdDrain == 25, "Migration lost defensive edits")
	check(model.move(0, 0).counterHitstun == 4 and model.move(0, 0).counterHitstop == 3 and model.move(0, 0).reversalEligible == 1, "Timing migration did not respect saved move category")
	var v4 := edited.duplicate(true)
	v4.schema = 4
	v4.coreVersion = 4
	v4.characters[0].moves[0].counterHitstun = 19
	v4.characters[0].moves[0].counterHitstop = 9
	for character in v4.characters:
		character.moves.resize(22)
		for definition in character.moves: definition.erase("hitboxBack")
	check(model.load_data(v4).is_empty(), "Schema-4 migration rejected")
	check(model.move(0, 0).counterHitstun == 19 and model.move(0, 0).counterHitstop == 9 and model.move(0, 0).hitboxBack == 1200, "Schema-4 migration lost timing edits or old hitbox origin")
	var invalid_timing := model.data()
	invalid_timing.characters[0].moves[0].counterHitstun = 61
	var timing_hash := model.fingerprint()
	check(not model.load_data(invalid_timing).is_empty() and model.fingerprint() == timing_hash, "Invalid counter-hit edit was not atomic")
	var invalid_momentum := model.data()
	invalid_momentum.momentumRules.fdDrain = 0
	check(not model.load_data(invalid_momentum).is_empty(), "Free Faultless Defense configuration accepted")
	for c in CombatModel.CHARACTERS.size():
		model.reset([c, (c + 1) % 6])
		var snapshot: PackedByteArray = model.core.snapshot()
		model.step(16, 0)
		check(model.core.restore(snapshot) and model.state().players[0].character == c, "Roster snapshot restore failed")
	check(model.load_data(original).is_empty(), "Could not restore full roster")
	check(model.core.set_training_momentum(0, 5000), "Training Momentum setter rejected valid value")
	var momentum_snapshot: PackedByteArray = model.core.snapshot()
	model.step(1 | 2048, 0)
	check(model.state().players[0].faultless == 1 and model.state().players[0].momentum < 5000, "Faultless Defense did not drain meter")
	check(model.core.restore(momentum_snapshot) and model.state().players[0].momentum == 5000, "Snapshot lost Momentum")
	check(not model.core.set_training_momentum(0, 10001), "Overfilled Momentum accepted")
	var extreme := original.duplicate(true)
	var strike: Dictionary = extreme.characters[0].moves[0]
	strike.startup = 5
	strike.reach = 50000
	strike.hitstun = 180
	strike.counterHitstun = 60
	strike.hitstop = 30
	strike.counterHitstop = 30
	check(model.load_data(extreme).is_empty(), "Maximum legal counter-hit values rejected")
	model.reset([0, 1])
	for _tick in 5: model.step(16, 64)
	check(model.state().players[0].event == 3 and model.state().players[1].stun == 240 and model.state().hitstop == 60, "Counter-hit classification/bonuses missing")
	var counter_snapshot: PackedByteArray = model.core.snapshot()
	model.step(0, 0)
	var counter_hash := model.state_hash()
	check(model.core.restore(counter_snapshot), "Valid extended stun/hitstop snapshot rejected")
	model.step(0, 0)
	check(model.state_hash() == counter_hash and model.state().players[0].hitNoticeTime == 60, "Counter-hit feedback diverged on restore")
	for latency in [0, 1, 4, 8, 12]:
		var result := RollbackSession.trial(original, latency, 4, 1200)
		check(result.get("pass", false), "Rollback divergence: " + str(result))
	var breaking := original.duplicate(true)
	for character in breaking.characters:
		for definition in character.moves:
			definition.guardBreak = 1
			definition.reach = 50000
	check(RollbackSession.trial(breaking, 8, 4, 1200).get("pass", false), "Guard-break rollback divergence")
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
