extends SceneTree

var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("Anvil: " + message)

func run() -> void:
	var model := CombatModel.new()
	var batch: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/" + batch.file))
	var load_error := model.load_data(source)
	check(load_error.is_empty(), "Current batch failed validation: " + load_error)
	var earlier: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/" + batch.sourceFile))
	for c in range(1, 6):
		var intact := true
		for slot in CombatModel.MOVE_IDS.size():
			if not CombatSupers.info(c, slot).is_empty(): continue
			var old_move: Dictionary = earlier.characters[c].moves[slot].duplicate(true)
			old_move.simpleDirection = 0.0
			old_move.simpleButton = 0.0
			intact = intact and source.characters[c].moves[slot] == old_move
		check(intact, "Changed another fighter's non-super moves")
	check(model.move_name(0, 14) == "63214P" and model.move_name(0, 15) == "63214K", "Ground-grab notation")
	check(model.move_name(0, 16).begins_with("63214Hs") and model.move_name(0, 28) == "[4]6Hs", "Super/rush notation")
	var fingerprint := model.fingerprint()
	var round_trip := model.data()
	load_error = model.load_data(round_trip)
	check(load_error.is_empty() and model.fingerprint() == fingerprint, "Extended grappler data round trip: " + load_error)
	model.reset([0, 2])
	model.core.preview_begin(0, 13)
	for tick in 6: model.step(256, 0)
	check(model.state().players[0].armorAvailable == 2, "Shield stance did not expose two armor hits")
	model.core.preview_begin(0, 28)
	check(model.state().players[0].carriedArmor == 1 and model.state().players[0].armorAvailable == 2, "Carry stacked more or less than one hit")
	var snapshot: PackedByteArray = model.core.snapshot()
	for tick in 9: model.step(0, 0)
	check(model.core.restore(snapshot), "Carried-armor snapshot rejected")
	check(model.state().players[0].carriedArmor == 1, "Carried armor missing after restore")
	model.reset([0, 2])
	model.core.preview_place(0, 35000, 0, 10000)
	model.core.preview_place(1, 56000, 16000, 0)
	check(model.core.preview_begin(0, 16) == 1, "Super did not begin")
	snapshot = model.core.snapshot()
	check(model.state().superFreezeTime == 54 and model.state().players[0].momentum == 3333, "Super cost/freeze")
	for tick in 12: model.step(0, 0)
	check(model.core.restore(snapshot), "Super snapshot rejected")
	check(model.state().superFreezeTime == 54 and model.state().superFreezeActor == 0, "Super snapshot clocks lost")
	for tick in 59: model.step(0, 0)
	check(model.state().pairKind == 7, "Anti-air capture missing")
	snapshot = model.core.snapshot()
	for tick in 30: model.step(0, 0)
	check(model.core.restore(snapshot), "Grappler pair snapshot rejected")
	for tick in 160: model.step(0, 0)
	var hash_a := model.state_hash()
	check(model.core.restore(snapshot), "Pair rewind failed")
	for tick in 160: model.step(0, 0)
	check(model.state_hash() == hash_a, "Grappler rollback diverged")
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	game.load_workshop_draft()
	game.motion.instant = true
	game.characters = [0, 2]
	game.activity = "training"
	game.configure_activity()
	game.show_screen("play")
	game.finish_menu_motion()
	game.reset_round()
	game.model.core.preview_place(0, 35000, 0, 10000)
	game.model.core.preview_place(1, 56000, 16000, 0)
	game.model.core.preview_begin(0, 16)
	game._process(0.0)
	check(game.super_freeze.visible and game.super_freeze.character == 0, "Real super did not trigger cut-in")
	check(not game.preview_super_freeze(1), "Manual preview interrupted a real super")
	for tick in 54: game.model.step(0, 0)
	game._process(0.0)
	check(not game.super_freeze.visible, "Cut-in outlasted deterministic freeze")
	game.queue_free()
	await process_frame
	# Headless frames can run faster than the audio mixer retires a decoder.
	await create_timer(0.5).timeout
	print("Anvil native: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
