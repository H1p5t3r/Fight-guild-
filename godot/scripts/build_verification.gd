extends RefCounted

var failures := 0
var game: Control
var tree: SceneTree

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("UI check: " + description)

func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func ticks(count: int) -> void:
	for _i in count: game.advance_one()
	game._process(0.0)

func release_hitstop() -> void:
	while game.model.state().hitstop > 0: ticks(1)

func timing_fixture() -> Dictionary:
	var data: Dictionary = game.model.data().duplicate(true)
	for character in data.characters:
		for definition in character.moves:
			definition.damage = 0
			definition.pushback = 0
		for slot in [0, 4]:
			character.moves[slot].startup = 1
			character.moves[slot].reach = 50000
	data.characters[1].moves[3].reach = 100 # Dummy Hs whiffs so its recovery can be punished.
	data.characters[0].moves[13].advance = 10000 # Authored crossing move for the side-switch check.
	return data

func combo_inputs(hits: int = 2) -> void:
	for hit in hits:
		if hit > 0: release_hitstop()
		key(KEY_S, hit % 2 == 1)
		key(KEY_J, true)
		ticks(1)
		key(KEY_J, false)
		key(KEY_S, false)

func verify_timing_feedback() -> void:
	var original: Dictionary = game.model.data()
	game.fields.counterHitstun.control.value = 9
	game.fields.counterHitstop.control.value = 5
	game.fields.reversalEligible.control.button_pressed = true
	game.apply_move()
	check(game.model.move(0, 0).counterHitstun == 9 and game.model.move(0, 0).counterHitstop == 5 and game.model.move(0, 0).reversalEligible == 1, "Timing editor fields did not apply")
	game.lock_online(true)
	check(not game.fields.counterHitstun.control.editable and game.fields.reversalEligible.control.disabled, "Timing editor remains editable online")
	game.lock_online(false)
	game.model.load_data(original)
	check(game.model.load_data(timing_fixture()).is_empty(), "Timing fixture rejected")
	game.populate_editor()
	game.dummy.select(5)
	game.reset_round()
	combo_inputs()
	var cards: Array = game.arena.feedback.cards.duplicate(true)
	check(game.model.state().players[0].combo == 2 and cards[0].number == 2 and cards[1].number == 0, "Background counter is not owned by the combo attacker")
	check(cards[0].left and cards[0].hit == 3 and cards[0].font_size >= 125, "Counter hit / large left-side combo feedback missing")
	var snapshot: PackedByteArray = game.model.core.snapshot()
	ticks(90)
	check(game.model.core.restore(snapshot), "Feedback snapshot rejected")
	game._process(0.0)
	check(game.arena.feedback.cards == cards, "Rollback did not restore visible feedback clocks/layout")
	game.reset_round()
	ticks(18)
	key(KEY_J, true)
	ticks(1)
	key(KEY_J, false)
	check(game.model.state().players[0].event == 4 and game.arena.feedback.cards[0].hit == 4, "Recovery contact did not show PUNISH")
	game.dummy.select(6)
	game.reset_round()
	key(KEY_J, true)
	ticks(1)
	key(KEY_J, false)
	check(game.model.state().players[1].guarding == 1, "Reversal dummy did not begin by guarding")
	ticks(19)
	check(game.model.state().players[1].move == 14 and game.arena.feedback.cards[1].reversal and game.arena.feedback.cards[1].input_age == 1, "Guard dummy did not execute/display a buffered reversal")
	# Cross behind the opponent using an authored advance, then perform a real right-side combo.
	game.dummy.select(0)
	game.reset_round()
	key(KEY_D, true)
	ticks(32)
	key(KEY_D, false)
	key(KEY_O, true)
	ticks(1)
	key(KEY_O, false)
	var crossing: Dictionary = game.model.move(0, 13)
	ticks(crossing.startup + crossing.active + crossing.recovery)
	check(game.model.state().players[0].x > game.model.state().players[1].x, "Side-switch fixture did not cross")
	check(game.model.state().players[0].move == -1, "Crossing move did not finish recovery")
	combo_inputs()
	check(game.arena.feedback.cards[0].number == 2 and not game.arena.feedback.cards[0].left, "Combo stayed on a fixed player side after crossing")
	ticks(120)
	check(game.arena.feedback.cards[0].number == 0, "Completed combo did not expire")
	game.model.load_data(original)
	game.populate_editor()
	game.dummy.select(0)
	game.reset_round()

func run(runtime: SceneTree, existing: Control = null) -> void:
	tree = runtime
	game = existing
	if game == null:
		var scene := load("res://main.tscn") as PackedScene
		game = scene.instantiate()
		tree.root.add_child(game)
	if not game.has_method("advance_one"):
		printerr("Playable scene did not load its script")
		tree.quit(1)
		return
	game.set_physics_process(false)
	await tree.process_frame
	var transitions = load("res://scripts/transition_verification.gd").new()
	failures += await transitions.run(tree, game)
	var menus = load("res://scripts/menu_verification.gd").new()
	failures += await menus.run(tree, game)
	game.release_focus_from_ui()
	key(KEY_D, true)
	ticks(20)
	key(KEY_D, false)
	key(KEY_J, true)
	ticks(4)
	check(game.model.state().players[1].health == 1000, "Attack hit before startup")
	ticks(1)
	key(KEY_J, false)
	check(game.model.state().players[1].health == 965, "Native keyboard attack did not hit")
	game.fields.damage.control.value = 177
	game.apply_move()
	check(game.model.move(0, 0).damage == 177, "Editor did not apply move")
	key(KEY_D, true)
	ticks(20)
	key(KEY_D, false)
	key(KEY_J, true)
	ticks(5)
	key(KEY_J, false)
	check(game.model.state().players[1].health == 823, "Edited damage did not affect combat")
	game.reset_round()
	game.fields.damage.control.get_line_edit().grab_focus()
	key(KEY_J, true)
	game.release_focus_from_ui()
	ticks(1)
	key(KEY_J, false)
	check(game.model.state().players[0].move == -1, "Typing in editor leaked into game input")
	game.selection_simple[0].button_pressed = true
	game.selection_simple[1].button_pressed = false
	game.confirm_selection()
	key(KEY_SHIFT, true)
	key(KEY_W, true)
	key(KEY_I, true)
	ticks(1)
	for code in [KEY_SHIFT, KEY_W, KEY_I]: key(code, false)
	var state: Dictionary = game.model.state()
	check(state.players[0].move == 16 and state.players[0].y == 0, "Simple up+Hs should invoke special, not jump")
	check(state.players[0].simple == 1 and state.players[1].simple == 0, "Simple controls are not independent")
	game.reset_round()
	key(KEY_S, true)
	ticks(1)
	key(KEY_D, true)
	ticks(1)
	key(KEY_S, false)
	key(KEY_J, true)
	ticks(1)
	key(KEY_J, false)
	key(KEY_D, false)
	check(game.model.state().players[0].move == 14, "Traditional motions no longer work in simple mode")
	game.run_trial()
	check(game.trial_status.text.begins_with("PASS"), "Rollback workbench failed")
	game.lock_online(true)
	check(not game.fields.damage.control.editable, "Editor remains editable during network play")
	game.lock_online(false)
	game.training_momentum.select(1)
	game.reset_round()
	check(game.model.state().players[0].momentum == 5000, "Training Momentum did not reset to 50%")
	key(KEY_A, true)
	key(KEY_Q, true)
	ticks(1)
	for code in [KEY_A, KEY_Q]: key(code, false)
	check(game.model.state().players[0].faultless == 1 and game.model.state().players[0].momentum == 4990, "Keyboard FD macro failed")
	check(game.arena.sprites[0].get_meta("phase") == "block", "FD has no guard pose")
	game.mode.select(1)
	game.reset_round()
	check(game.model.state().players[0].momentum == 0, "Training meter leaked into local versus")
	game.mode.select(0)
	game.lock_online(true)
	check(game.training_momentum.disabled and not game.momentum_fields.fdDrain.control.editable and game.fields.guardBreak.control.disabled, "Defense settings remain editable online")
	game.lock_online(false)
	game.momentum_fields.fdDrain.control.value = 0.2
	game.apply_momentum()
	check(game.model.data().momentumRules.fdDrain == 20, "Momentum editor failed to apply rate")
	game.momentum_fields.fdDrain.control.value = 0.1
	game.apply_momentum()
	# Real contacts drive both poses of all three reaction clips for every defender.
	game.fields.reach.control.value = 500
	game.dummy.select(2)
	for character in CombatModel.CHARACTERS.size():
		game.selection_characters[1].select(character)
		game.confirm_selection()
		for reaction in range(1, 4):
			game.fields.blockstun.control.value = 10 if reaction == 1 else 16
			game.fields.guardBreak.control.button_pressed = reaction == 3
			game.apply_move()
			key(KEY_J, true)
			ticks(5)
			key(KEY_J, false)
			var defender: Dictionary = game.model.state().players[1]
			check(defender.blockReaction == reaction and defender.throwInvulnerable == int(reaction != 3), "Incorrect block reaction / throw eligibility")
			var block_visual: Sprite2D = game.arena.sprites[1]
			check(block_visual.get_meta("phase") == "block" and block_visual.get_meta("pose") == (reaction - 1) * 2, "Missing block contact frame")
			ticks(10)
			check(block_visual.get_meta("pose") == (reaction - 1) * 2 + 1, "Block clip did not settle after hitstop")
	game.fields.chipDamage.control.value = 12
	game.apply_move()
	game.dummy.select(4)
	key(KEY_J, true)
	ticks(5)
	key(KEY_J, false)
	check(game.model.state().players[1].health == 1000 and game.model.state().players[1].faultless == 1, "FD dummy did not prevent chip")
	game.model.restore_defaults()
	game.populate_editor()
	game.training_momentum.select(0)
	game.dummy.select(0)
	game.selection_characters[1].select(1)
	game.confirm_selection()
	# Exercise actual keyboard -> selected fighter -> windup/active artwork for all 30 basic buttons.
	var button_keys := [KEY_J, KEY_K, KEY_L, KEY_I, KEY_O]
	var slots := [0, 1, 2, 3, 13]
	for character in CombatModel.CHARACTERS.size():
		game.selection_characters[0].select(character)
		game.selection_simple[0].button_pressed = false
		game.confirm_selection()
		for b in button_keys.size():
			game.reset_round()
			key(button_keys[b], true)
			ticks(1)
			key(button_keys[b], false)
			var fighter: Dictionary = game.model.state().players[0]
			check(fighter.character == character and fighter.move == slots[b], "Missing basic button for " + CombatModel.CHARACTERS[character])
			var visual: Sprite2D = game.arena.sprites[0]
			check(visual.get_meta("phase") == "windup" and visual.get_meta("pose") == b + 1, "Attack has no windup pose")
			var anticipation: Texture2D = visual.texture
			ticks(game.model.move(character, slots[b]).startup - 1)
			check(visual.get_meta("phase") == "active" and visual.get_meta("pose") == b + 1 and visual.texture != anticipation, "Attack did not change to its active image")
	game.selection_characters[0].select(0)
	game.confirm_selection()
	game.reset_round()
	verify_timing_feedback()
	game.show_controls()
	check(game.has_open_dialog(), "Controls dialog did not open")
	for child in game.get_children():
		if child is AcceptDialog and child != game.file_dialog: child.queue_free()
	await tree.process_frame
	var args := OS.get_cmdline_user_args()
	if args.has("--combo"):
		game.model.load_data(timing_fixture())
		game.populate_editor()
		game.dummy.select(5)
		game.reset_round()
		game.show_boxes = false
		combo_inputs(6)
	if args.has("--defense"):
		game.training_momentum.select(1)
		game.dummy.select(4)
		game.fields.reach.control.value = 500
		game.fields.blockstun.control.value = 16
		game.fields.guardBreak.control.button_pressed = true
		game.apply_move()
		key(KEY_J, true)
		ticks(5)
		key(KEY_J, false)
	if args.has("--review"):
		game.show_sprite_review(3 if args.has("--block-review") else 0)
		check(game.has_open_dialog(), "Sprite review did not open")
	game.motion.instant = false
	if args.has("--home"): game.go_home()
	if args.has("--fighters"): game.go_home(); game.choose_activity("local")
	if args.has("--training"): game.go_home(); game.choose_activity("training"); game.confirm_selection()
	if args.has("--match"): game.go_home(); game.choose_activity("local"); game.confirm_selection()
	if args.has("--matches"): game.go_home(); game.show_screen("matches")
	if args.has("--connection"): game.go_home(); game.choose_activity("online"); game.confirm_selection()
	if args.has("--controls"): game.go_home(); game.show_controls()
	if args.has("--screenshot"):
		await game.wait_for_menu_motion()
		await tree.process_frame
		await RenderingServer.frame_post_draw
		var path: String = args[args.find("--screenshot") + 1]
		check(tree.root.get_texture().get_image().save_png(path) == OK, "Could not save native screenshot")
	print("Godot playable scene: ", failures, " failures; combat, counter/punish/reversal, combo display/side-switch, editing, FD, block clips, rollback")
	tree.quit(1 if failures else 0)
