extends SceneTree

var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; printerr(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var model := CombatModel.new()
	var defaults := model.data()
	check(defaults.schema == 22 and model.move(5, 0).starterProration == 70, "New default tuning missing")
	var legacy := defaults.duplicate(true)
	legacy.schema = 7
	legacy.coreVersion = 7
	legacy.erase("tuningRules")
	legacy.momentumRules.fdDrain = 17
	legacy.characters[5].moves[0].damage = 123
	legacy.characters[5].moves[0].counterHitstun = 13
	for character in legacy.characters:
		character.moves.resize(32)
		for move in character.moves:
			for field in CombatModel.FIELDS.slice(51): move.erase(field)
	check(model.load_data(legacy).is_empty(), "Schema-7 save failed to migrate")
	var migrated := model.move(5, 0)
	check(migrated.damage == 123 and migrated.counterHitstun == 13, "Migration changed authored damage/counter values")
	check(migrated.starterProration == 100 and migrated.comboScaling == 0 and migrated.normalCancelEnd == 0, "Migration changed legacy scaling/cancel behavior")
	check(model.data().tuningRules.fdAirDrain == 17 and model.data().tuningRules.fdLevelCost == 0, "Migration changed saved FD costs")
	check(model.data().jumpRules.prejumpFrames == 0, "Legacy instant jump changed")
	var version8 := defaults.duplicate(true)
	version8.schema = 8
	version8.coreVersion = 8
	for character in version8.characters: character.moves.resize(32)
	version8.erase("jumpRules")
	version8.tuningRules.throwGraceFrames = 7
	check(model.load_data(version8).is_empty() and model.data().jumpRules.prejumpFrames == 0 and model.data().tuningRules.throwGraceFrames == 7, "Schema-8 tuning lost during jump migration")
	check(model.load_data(defaults).is_empty(), "New tuning round trip failed")
	var invalid_jump := defaults.duplicate(true)
	invalid_jump.jumpRules.prejumpFrames = 31
	check(not model.load_data(invalid_jump).is_empty() and model.data() == defaults, "Invalid jump timing changed configuration")
	for field in ["starterProration", "comboScaling", "normalCancelEnd", "landingRecovery", "counterVulnerable"]:
		var invalid := defaults.duplicate(true)
		invalid.characters[5].moves[0][field] = 9999
		var fingerprint := model.fingerprint()
		check(not model.load_data(invalid).is_empty() and model.fingerprint() == fingerprint, "Invalid tuning edit was not atomic: " + field)
	var invalid_rule := defaults.duplicate(true)
	invalid_rule.tuningRules.throwGraceFrames = -1
	check(not model.load_data(invalid_rule).is_empty(), "Invalid throw grace accepted")
	var path := "user://test-tuning.json"
	check(model.save_file(path).is_empty(), "Tuning save failed")
	check(model.load_file(path).is_empty() and model.data() == defaults, "Tuning save/load lost fields")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for delay in [1, 8, 12]:
		check(RollbackSession.trial(defaults, delay, 4, 1200).get("pass", false), "Tuning snapshot state diverged under rollback")
	var app = load("res://scripts/main.gd").new()
	root.add_child(app)
	await process_frame
	app.activity = "development"
	app.screen = "play"
	app.configure_activity()
	app.paused = true
	app.edit_character.select(4)
	app.edit_move.select(29)
	app.populate_editor()
	check(app.fields.landingRecovery.control.value == 12, "Air-hook landing recovery missing from editor")
	app.fields.landingRecovery.control.value = 17
	app.fields.starterProration.control.value = 65
	app.fields.followCancelEnd.control.value = 38
	app.apply_move()
	check(app.model.move(4, 29).landingRecovery == 17 and app.model.move(4, 29).starterProration == 65 and app.model.move(4, 29).followCancelEnd == 38, "Editor did not apply move tuning")
	app.tuning_fields.throwGraceFrames.control.value = 7
	app.tuning_fields.blockCarryover.control.button_pressed = false
	app.jump_fields.prejumpFrames.value = 6
	app.jump_fields.emptyLandingFrames.value = 2
	app.apply_tuning()
	check(app.model.data().jumpRules.prejumpFrames == 6 and app.model.data().jumpRules.emptyLandingFrames == 2, "Jump editor did not apply")
	check(app.model.data().tuningRules.throwGraceFrames == 7 and app.model.data().tuningRules.blockCarryover == 0, "Global tuning controls did not apply")
	app.fields.attackLevel.control.value = 4
	app.fields.counterTier.control.value = 3
	app.apply_timing_presets()
	check(app.fields.hitstop.control.value == 15 and app.fields.blockstun.control.value == 18 and app.fields.counterFreezeFrames.control.value == 31 and app.fields.counterSlowFrames.control.value == 35, "Timing presets did not populate editable fields")
	app.lock_online(true)
	check(not app.tuning_fields.throwGraceFrames.control.editable and app.tuning_fields.blockCarryover.control.disabled and not app.jump_fields.prejumpFrames.editable, "Online tuning controls were left editable")
	app.queue_free()
	await process_frame
	print("Tuning migration, editor, presets and rollback: ", failures, " failures")
	quit(int(failures != 0))
