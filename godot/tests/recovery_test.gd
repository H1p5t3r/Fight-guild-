extends SceneTree

var failures := 0
func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr(message)

func _initialize() -> void:
	var model := CombatModel.new()
	check(model.state().players[0].character == 5 and model.state().players[1].character == 4, "Default matchup must be Fillet / Shark")
	var original := model.data()
	var legacy := original.duplicate(true)
	legacy.schema = 5
	legacy.coreVersion = 5
	legacy.erase("recoveryRules")
	for character in legacy.characters:
		character.moves.resize(22)
		for move in character.moves:
			for field in CombatModel.FIELDS.slice(32): move.erase(field)
	legacy.characters[5].moves[0].damage = 137
	legacy.characters[5].moves[0].pushback = 1700
	check(model.load_data(legacy).is_empty(), "Schema-5 migration rejected")
	var migrated := model.move(5, 0)
	check(migrated.damage == 137 and migrated.pushback == 1700 and migrated.airPushback == 1700 and migrated.blockPushback == 1700, "Migration lost existing move tuning")
	check(migrated.launch == 0 and model.move(5, 22).knockdown == 2 and model.move(4, 24).category == 4, "Migration must preserve old reactions and append sweep / throws")
	var fingerprint := model.fingerprint()
	for field in ["knockdown", "launch", "knockdownFrames", "wallDamage"]:
		var invalid := model.data()
		invalid.characters[5].moves[0][field] = -1
		check(not model.load_data(invalid).is_empty() and model.fingerprint() == fingerprint, "Invalid reaction edit was not atomic: " + field)
	var invalid_rule := model.data()
	invalid_rule.recoveryRules.gravityCap = 99
	check(not model.load_data(invalid_rule).is_empty() and model.fingerprint() == fingerprint, "Invalid gravity cap changed live data")
	var settings := original.duplicate(true)
	settings.recoveryRules.wallBreakFrames = 90 # This fixture also verifies authored legacy durations.
	settings.recoveryRules.wallThreshold = 100
	for slot in [0, 1]:
		var move: Dictionary = settings.characters[5].moves[slot]
		move.damage = 20
		move.wallDamage = 100
		move.reach = 50000
		move.bottom = 0
		move.height = 50000
		move.startup = 5
		move.launch = 1 # A launching hit may splat immediately under the grounded-prime rule.
		move.starterProration = 100
		move.comboScaling = 0
	check(model.load_data(settings).is_empty(), "Valid wall tuning rejected")
	model.reset()
	for _tick in 200: model.step(2, 2)
	for _tick in 5: model.step(16, 0)
	check(model.state().players[1].reaction == 4, "Real inputs did not cause wall splat")
	while model.state().hitstop > 0: model.step(0, 0)
	var snapshot := model.core.snapshot()
	for _tick in 5: model.step(32, 0)
	check(model.state().wallBreakTime == 90 and model.state().players[1].health == 910, "Follow-up failed to break the wall")
	for _tick in 90: model.step(0, 0)
	var expected := model.state_hash()
	var state := model.state()
	check(state.stage == 1 and state.players[0].positiveTime == 360 and state.players[1].reaction == 0, "Wall break did not reset neutral / award positive bonus")
	check(model.core.restore(snapshot), "Wall-splat snapshot rejected")
	for _tick in 5: model.step(32, 0)
	for _tick in 90: model.step(0, 0)
	check(model.state_hash() == expected, "Wall-break replay diverged")
	verify_wall_rollback(settings)
	var saved := "user://test-recovery.json"
	check(model.save_file(saved).is_empty(), "Recovery save failed")
	var data_hash := model.fingerprint()
	model.restore_defaults()
	check(model.load_file(saved).is_empty() and model.fingerprint() == data_hash, "Recovery settings did not survive file round trip")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(saved))
	print("Godot recovery, walls, focus fighters and migration: ", failures, " failures")
	quit(1 if failures else 0)

func verify_wall_rollback(settings: Dictionary) -> void:
	for delay in [1, 8, 12]:
		var reference := CombatModel.new()
		var predicted := CombatModel.new()
		reference.load_data(settings)
		predicted.load_data(settings)
		var session := RollbackSession.new(predicted)
		session.max_prediction = 20
		var pending: Array[Dictionary] = []
		var saw_splat := false
		var saw_break := false
		for frame in 350:
			var attack := 2 if frame < 200 else 16 if frame < 205 else 32 if frame >= 211 and frame < 216 else 0
			var defense := 2 if frame < 200 else 0
			reference.step(attack, defense)
			saw_splat = saw_splat or reference.state().players[1].reaction == 4
			saw_break = saw_break or reference.state().wallBreakTime > 0
			session.submit(1, frame, defense)
			pending.append({"at": frame + delay + frame % 3, "frame": frame, "input": attack})
			for i in range(pending.size() - 1, -1, -1):
				if pending[i].at <= frame:
					session.submit(0, pending[i].frame, pending[i].input)
					pending.remove_at(i)
			check(session.advance(), "Wall rollback stalled: " + session.error)
		for packet in pending: session.submit(0, packet.frame, packet.input)
		check(saw_splat and saw_break and reference.state().stage == 1, "Rollback fixture did not exercise wall transition")
		check(session.error.is_empty() and session.rollbacks > 0 and reference.state_hash() == predicted.state_hash(), "Delayed wall combo diverged at delay %d" % delay)
