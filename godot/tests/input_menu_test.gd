extends SceneTree

var failures := 0
var checks := 0
var game: Control
const A := {"id": 3, "name": "Test controller A", "guid": "test-a"}
const B := {"id": 7, "name": "Test controller B", "guid": "test-b"}

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr(message)
func _initialize() -> void: call_deferred("run")
func key(code: int, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code; event.physical_keycode = code; event.pressed = pressed
	return event
func pad(id: int, button: int, pressed: bool) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = id; event.button_index = button; event.pressed = pressed
	return event
func send(event: InputEvent) -> void:
	Input.parse_input_event(event.duplicate())
	Input.flush_buffered_events()

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.motion.instant = true
	game.finish_menu_motion()
	var controls: FighterInputs = game.fighter_inputs
	controls.refresh_devices([A, B])
	var before: Array = controls.profiles.duplicate(true)
	game.menu_action("matches")
	game.menu_action("local")
	var sides: SideSelect = game.menus.sides
	check(game.screen == "sides" and sides.ready_to_continue(), "Local path missed default side setup")
	check(sides.owners.pad3 == 0 and sides.owners.pad7 == 1, "Side screen missed controller assignments")
	send(pad(3, JOY_BUTTON_DPAD_RIGHT, true)); send(pad(3, JOY_BUTTON_DPAD_RIGHT, false))
	check(sides.owners.pad3 == -1 and sides.owners.pad7 == 1, "Controller did not move independently into neutral")
	send(pad(3, JOY_BUTTON_DPAD_RIGHT, true)); send(pad(3, JOY_BUTTON_DPAD_RIGHT, false))
	check(sides.owners.pad3 == 1 and sides.owners.pad7 == -1, "Moving into an occupied side did not return its controller to neutral")
	game.menu_back()
	check(game.screen == "matches" and controls.profiles == before and controls.assigned == [3, 7], "Canceling side selection changed live controls")
	game.menu_action("local")
	# Physical keyboard layouts can exchange sides as well.
	send(key(KEY_D, true)); send(key(KEY_D, false))
	send(key(KEY_D, true)); send(key(KEY_D, false))
	check(sides.owners.key0 == 1 and sides.owners.key1 == -1, "Keyboard layout did not move to P2")
	sides.move_source("key1", 0)
	game.confirm_sides()
	check(game.screen == "fighters" and game.selection_return == "sides", "Side confirm did not lead to fighter select")
	check(controls.profiles[1].keys[4] == KEY_J and controls.profiles[0].keys[4] == KEY_KP_1, "Swapped keyboard layouts control wrong sides")
	game.menu_back()
	game.confirm_sides()
	check(controls.profiles[1].keys[4] == KEY_J, "Back/confirm swapped the keyboard a second time")
	game.menu_back()
	sides.move_source("key0", -1); sides.move_source("key1", -1)
	controls.refresh_devices([B])
	check(not sides.owners.has("pad3") and not sides.ready_to_continue() and sides.continue_button.disabled, "Disconnected side could still confirm")
	var replug := A.duplicate(); replug.id = 11
	controls.refresh_devices([B, replug])
	check(sides.owners.pad11 == -1, "New side-select controller joined a side without choosing")
	var axis := InputEventJoypadMotion.new()
	axis.device = 11; axis.axis = JOY_AXIS_LEFT_X; axis.axis_value = -0.9
	send(axis)
	check(sides.owners.pad11 == 0 and sides.ready_to_continue(), "Stick failed to choose a side")
	for tick in 5: send(axis)
	check(sides.owners.pad11 == 0, "Held side-select stick repeated")
	axis.axis_value = 0; send(axis)
	send(pad(11, JOY_BUTTON_START, true)); send(pad(11, JOY_BUTTON_START, false))
	check(game.screen == "fighters" and controls.assigned == [11, 7] and not controls.profiles[0].keyboard and not controls.profiles[1].keyboard, "Start did not apply two independent controller-only sides")
	game.confirm_selection()
	await process_frame
	game.release_focus_from_ui()
	game._physics_process(1.0 / 60)
	send(pad(11, JOY_BUTTON_X, true))
	check(game.read_input(0) == 32 and game.read_input(1) == 0, "Assigned controller did not reach the correct fighter")
	send(pad(11, JOY_BUTTON_X, false))
	send(pad(3, JOY_BUTTON_X, true))
	check(game.read_input(0) == 0 and game.read_input(1) == 0, "Unassigned controller controlled a fighter")
	send(pad(3, JOY_BUTTON_X, false))
	var frame: int = game.model.frame()
	controls.refresh_devices([B])
	check(game.screen == "pause" and controls.assigned[1] == 7 and game.menus.pause_note.text.contains("disconnected"), "Disconnected controller did not pause offline safely")
	game._physics_process(1.0 / 60)
	check(game.model.frame() == frame, "Disconnected offline match advanced")
	controls.refresh_devices([B, replug])
	check(controls.assigned == [11, 7], "Reconnecting controller moved the opponent")
	game.menu_action("resume")
	game._physics_process(1.0 / 60)
	game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	send(pad(11, JOY_BUTTON_A, true))
	check(game.read_input(0) == 0 and game.screen == "pause", "Background window still accepted combat input")
	game._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	game.menu_action("resume")
	check(game.read_input(0) == 0 and game.input_release_required, "Held button leaked across focus/resume")
	send(pad(11, JOY_BUTTON_A, false))
	game._physics_process(1.0 / 60)
	game.show_controls()
	await process_frame
	var dialog: AcceptDialog
	for child in game.get_children():
		if child.has_method("begin_binding"): dialog = child
	check(dialog != null, "Controls settings failed to open")
	if dialog != null:
		dialog.begin_binding("keys", 4)
		send(key(KEY_F, true)); send(key(KEY_F, false))
		check(controls.profiles[0].keys[4] == KEY_F and dialog.listening.is_empty(), "Capture did not apply keyboard remap")
		dialog.begin_binding("pad", 4)
		dialog.capture(pad(7, JOY_BUTTON_X, true))
		check(dialog.listening == "pad", "Other player's pad captured a binding")
		dialog.capture(pad(11, JOY_BUTTON_X, true))
		check(controls.profiles[0].pad[4] == JOY_BUTTON_X and controls.profiles[0].pad[5] == JOY_BUTTON_A, "Pad remap did not swap duplicate")
		dialog.begin_binding("keys", 5)
		dialog.capture(key(KEY_ESCAPE, true))
		check(dialog.visible and dialog.listening.is_empty(), "Cancel binding closed settings")
		dialog.test_button.pressed.emit()
		dialog._input(pad(11, JOY_BUTTON_B, true))
		check(dialog.visible and dialog.testing, "Input test treated Hs as Back")
		dialog._input(pad(11, JOY_BUTTON_START, true))
		check(not dialog.testing and dialog.visible, "Start did not leave input test safely")
		send(pad(11, JOY_BUTTON_X, true))
		check(game.read_input(0) == 0, "Settings leaked controller input into game")
		dialog.confirmed.emit()
		await process_frame; await process_frame
		check(game.input_release_required and game.read_input(0) == 0, "Remap confirmation leaked held button")
		send(pad(11, JOY_BUTTON_X, false))
		game._physics_process(1.0 / 60)
		send(pad(11, JOY_BUTTON_X, true))
		check(game.read_input(0) == 16, "Remapped physical controller failed in live game")
		send(pad(11, JOY_BUTTON_X, false))
	if OS.get_cmdline_user_args().has("--screenshots"):
		game.go_home()
		controls.profiles = [FighterInputs.defaults(0), FighterInputs.defaults(1)]
		controls.assigned = [-1, -1]
		controls.reservations = ["", ""]
		controls.refresh_devices([A, B])
		game.menu_action("matches"); game.menu_action("local")
		for tick in 12: await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_visible_rect().encloses(sides.continue_button.get_global_rect()), "Side select overflows the viewport")
		check(root.get_texture().get_image().save_png("/tmp/fg-side-select.png") == OK, "Side-select screenshot failed")
		game.show_controls()
		for tick in 12: await process_frame
		await RenderingServer.frame_post_draw
		for child in game.get_children():
			if child.has_method("begin_binding"):
				check(root.get_visible_rect().encloses(Rect2(Vector2(child.position), Vector2(child.size))), "Controls window overflows the viewport")
		check(root.get_texture().get_image().save_png("/tmp/fg-control-settings.png") == OK, "Controls screenshot failed")
	print("Native controls and side-select menus: %d failures; %d checks; local flow, remap capture, hotplug, focus and held-input isolation" % [failures, checks])
	quit(1 if failures else 0)
