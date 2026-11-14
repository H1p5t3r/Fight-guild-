extends SceneTree

var failures := 0
var game: Control

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

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene := load("res://main.tscn") as PackedScene
	game = scene.instantiate()
	root.add_child(game)
	if not game.has_method("advance_one"):
		printerr("Playable scene did not load its script")
		quit(1)
		return
	game.set_physics_process(false)
	await process_frame
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
	game.selection_dialog.confirmed.emit()
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
	game.reset_round()
	game.show_controls()
	check(game.has_open_dialog(), "Controls dialog did not open")
	for child in game.get_children():
		if child is AcceptDialog and child != game.selection_dialog and child != game.file_dialog: child.queue_free()
	await process_frame
	var args := OS.get_cmdline_user_args()
	if args.has("--screenshot"):
		await process_frame
		await RenderingServer.frame_post_draw
		var path: String = args[args.find("--screenshot") + 1]
		check(root.get_texture().get_image().save_png(path) == OK, "Could not save native screenshot")
	print("Godot playable scene: ", failures, " failures; combat, editing, keyboard, motions, simple controls, rollback, dialogs")
	quit(1 if failures else 0)
