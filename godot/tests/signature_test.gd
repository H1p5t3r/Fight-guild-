extends SceneTree

var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)

func _initialize() -> void:
	var model := LegacyFixture.create()
	var original := model.data()
	var legacy := original.duplicate(true)
	legacy.schema = 6
	legacy.coreVersion = 6
	LegacyFixture.strip_extensions(legacy)
	for character in legacy.characters:
		character.moves.resize(25)
		character.erase("movement")
		for move in character.moves:
			for field in CombatModel.FIELDS.slice(41): move.erase(field)
	legacy.characters[5].moves[15].damage = 137
	legacy.recoveryRules.gravityAfter = 9
	check(model.load_data(legacy).is_empty(), "Schema-6 migration rejected")
	check(model.move(5, 15).damage == 137 and model.data().recoveryRules.gravityAfter == 9, "Migration lost existing combat tuning")
	check(model.move(5, 25).enabled == 1 and model.move(4, 28).motion == 214 and model.movement(4).forwardStyle == 0, "Migration omitted signatures or movement")
	var data := model.data()
	data.characters[4].movement.runSpeed = 1300
	data.characters[5].moves[25].inertiaPercent = 75
	check(model.load_data(data).is_empty(), "Movement/attack edit rejected")
	var fingerprint := model.fingerprint()
	var file := "user://test-signatures.json"
	check(model.save_file(file).is_empty(), "Signature save failed")
	LegacyFixture.reset(model)
	check(model.load_file(file).is_empty() and model.fingerprint() == fingerprint, "Movement / signatures did not round trip")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	for field in ["forwardStyle", "runSpeed", "stepFrames"]:
		var invalid := model.data()
		invalid.characters[4].movement[field] = -1
		check(not model.load_data(invalid).is_empty() and model.fingerprint() == fingerprint, "Movement import was not atomic: " + field)
	for field in ["artPose", "followFrom", "pullFrames", "hitAngle", "inertiaPercent"]:
		var invalid := model.data()
		invalid.characters[5].moves[25][field] = 9999
		check(not model.load_data(invalid).is_empty() and model.fingerprint() == fingerprint, "Invalid signature field accepted: " + field)
	check(model.load_data(original).is_empty(), "Default signature data rejected")
	for air in [false, true]:
		verify_hook_rollback(air)
	print("Godot signature configuration, real-input hook combos and rollback: ", failures, " failures")
	quit(1 if failures else 0)

func verify_hook_rollback(air: bool) -> void:
	for delay in [1, 8, 12]:
		var reference := LegacyFixture.create()
		var predicted := LegacyFixture.create()
		reference.reset([4, 5])
		predicted.reset([4, 5])
		var session := RollbackSession.new(predicted)
		session.max_prediction = 20
		var packets: Array[Dictionary] = []
		var followed := false
		var saw_pull := false
		var saw_weapon := false
		var saw_combo := false
		for frame in 110:
			var input := 0
			var other := 0
			if air:
				# The saved j.214P slot now uses S, matching the authored kit.
				input = 8 if frame == 0 else 4 if frame == 5 else 5 if frame == 6 else 65 if frame == 7 else 0
			else:
				input = 4 if frame == 0 else 5 if frame == 1 else 65 if frame == 2 else 0
				# Begin the four-frame prejump earlier to preserve the recorded hook contact height.
				other = 8 if frame == 8 else 0
			var before := reference.state()
			if before.players[0].contact and before.hitstop == 0 and not followed:
				input = 16
				followed = true
			reference.step(input, other)
			var state := reference.state()
			saw_pull = saw_pull or state.players[1].reaction == 5
			saw_weapon = saw_weapon or state.players[0].weaponVisible == 1
			saw_combo = saw_combo or state.players[0].combo == 2
			session.submit(1, frame, other)
			packets.append({"at": frame + delay + frame % 3, "frame": frame, "input": input})
			for i in range(packets.size() - 1, -1, -1):
				if packets[i].at <= frame:
					session.submit(0, packets[i].frame, packets[i].input)
					packets.remove_at(i)
			check(session.advance(), "Signature rollback stalled: " + session.error)
		for packet in packets: session.submit(0, packet.frame, packet.input)
		check(saw_pull and saw_weapon and saw_combo and reference.state().players[1].health == 948, "Real input hook / scaled stab did not connect: air=%s delay=%d" % [air, delay])
		check(session.error.is_empty() and session.rollbacks > 0 and reference.state_hash() == predicted.state_hash(), "Hook rollback diverged: air=%s delay=%d" % [air, delay])
