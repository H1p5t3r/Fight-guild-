extends SceneTree

var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr(message)

func run() -> void:
	var model := CombatModel.new()
	var batch: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/" + batch.file))
	check(model.load_data(data).is_empty(), "Super batch failed import")
	var fingerprint := model.fingerprint()
	check(model.load_data(model.data()).is_empty() and model.fingerprint() == fingerprint, "Super data round trip changed configuration")
	var trainer = load("res://scripts/main.gd").new()
	# Exercise the input planner without entering the full UI; own the nodes
	# normally attached by _ready so this fixture also frees them.
	for child in [trainer.fighter_inputs, trainer.connection, trainer.combat_audio, trainer.fighter_music]: trainer.add_child(child)
	trainer.model = model
	for meter in [0, 10000]:
		model.reset([2, 0])
		model.core.set_training_momentum(0, meter)
		for remaining in range(6, 0, -1):
			var fighter: Dictionary = model.state().players[0].duplicate()
			fighter.stun = remaining
			model.step(trainer.dummy_reversal_input(fighter, 1), 0)
		var selected: int = model.state().players[0].move
		check(selected >= 0 and model.move(2, selected).category == 2, "Training dummy failed to enter its reversal motion")
		check((selected == 12) == (meter == 10000), "Training dummy selected an unaffordable super")
	trainer.free()
	var arena = load("res://scripts/arena.gd").new()
	arena.size = Vector2(1280, 720)
	root.add_child(arena)
	await process_frame
	CombatSupers.info(0, 16)
	for entry in CombatSupers.roster:
		var c := int(entry.character)
		var slot := int(entry.slot)
		model.reset([c, (c+1)%6], [true, true])
		check(model.state().players[0].simple == 0 and model.state().players[1].simple == 0, "Retired controls restored")
		model.core.preview_place(0, 35000, 0, 10000)
		model.core.preview_place(1, 60000 if entry.role == 5 else 47000, 16000 if entry.role == 0 else 0, 0)
		check(model.core.preview_begin(0, slot) == 1, "Super rejected: " + entry.name)
		check(model.state().players[0].momentum == 3333 and model.state().superFreezeTime == 54, "Super cost/freeze: " + entry.name)
		check(model.move_name(c, slot).contains(entry.name), "Missing command-list name")
		var pair_seen := false
		var utility_action := false
		for tick in 260:
			var saved: PackedByteArray = model.core.snapshot()
			check(model.core.restore(saved), "Live snapshot rejected: %s tick %d" % [entry.name, tick])
			if failures: break
			var state := model.state()
			arena.refresh(model, state, false, false)
			check(model.core.snapshot() == saved, "Super rendering changed simulation")
			pair_seen = pair_seen or state.pairKind > 0
			if state.pairKind == 8:
				var presentation := SuperAnimation.profile(c,slot)
				check(arena.sprites[0].get_meta("phase") == presentation.get("phase","attack_animation"), "Cinematic owner replaced with generic grab")
				check(arena.sprites[1].get_meta("super_role", "") == "receiver", "Missing cinematic receiver")
			if not entry.cinematic and state.players[0].move < 0 and not state.projectiles.is_empty(): utility_action = true
			model.step(0, 0)
		check(pair_seen == bool(entry.cinematic), "Wrong cinematic rule: " + entry.name)
		if not entry.cinematic: check(utility_action, "Utility failed to return control while its projectile remained")
		if failures: break
	# Motion-only policy also applies to files authored before the shortcut removal.
	var legacy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/" + batch.sourceFile))
	check(model.load_data(legacy).is_empty(), "Earlier move file no longer imports")
	model.reset([0, 4], [true, true])
	model.step(1024|1|16, 0)
	check(model.state().players[0].move != 14 and model.state().players[0].raw & 1024 == 0, "Legacy shortcut still invokes command grab")
	arena.queue_free()
	await process_frame
	print("Native supers: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
