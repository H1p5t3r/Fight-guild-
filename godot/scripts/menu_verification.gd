extends RefCounted

var failures := 0
var game: Control
var tree: SceneTree

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("Menu check: " + description)

func press(action: String) -> void:
	game.menus.buttons[action].pressed.emit()

func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func run(runtime: SceneTree, subject: Control) -> int:
	tree = runtime
	game = subject
	check(game.screen == "home" and game.menus.visible and not game.play_root.visible, "Startup did not reach main menu")
	var initial_frame: int = game.model.frame()
	key(KEY_J, true)
	game._physics_process(1.0 / 60.0)
	check(game.model.frame() == initial_frame and game.held.is_empty(), "Home advanced combat or accepted attack input")
	key(KEY_J, false)
	key(KEY_ENTER, true)
	key(KEY_ENTER, false)
	await tree.process_frame
	check(game.screen == "matches" and game.menus.buttons.local.has_focus(), "Keyboard confirm did not enter Matches with focus")
	key(KEY_RIGHT, true)
	key(KEY_RIGHT, false)
	check(game.menus.buttons.online.has_focus(), "Keyboard arrows did not navigate match choices")
	key(KEY_ESCAPE, true)
	key(KEY_ESCAPE, false)
	check(game.screen == "home", "Escape did not return to main menu")
	await verify_controls_dialog()
	press("training")
	await tree.process_frame
	check(game.screen == "fighters" and game.menus.selection.tiles[game.menus.selection.chosen[0]].has_focus(), "Training selection or keyboard focus missing")
	await verify_roster()
	game.menus.selection.choose_fighter(0, 2)
	game.menus.selection.choose_fighter(1, 5)
	game.selection_simple[0].button_pressed = true
	game.selection_simple[1].button_pressed = false
	# A menu key that remains held across the transition is ignored until released.
	key(KEY_J, true)
	press("confirm_fighters")
	check(game.input_release_required and game.read_input(0) == 0, "Held menu key leaked into gameplay")
	key(KEY_J, false)
	game._physics_process(1.0 / 60.0)
	var state: Dictionary = game.model.state()
	check(game.screen == "play" and game.activity == "training" and game.practice.visible and not game.editor_shell.visible and not game.sprite_button.visible, "Training shows incorrect tools")
	check(state.players[0].character == 2 and state.players[1].character == 5 and state.players[0].simple == 1 and state.players[1].simple == 0 and state.players[0].move == -1, "Selection was not applied independently")
	key(KEY_ESCAPE, true)
	key(KEY_ESCAPE, false)
	check(game.screen == "pause", "Escape did not pause")
	var before: int = game.model.state_hash()
	game._physics_process(1.0 / 60.0)
	check(game.model.state_hash() == before, "Offline pause advanced the round")
	press("change_fighters")
	game.menus.selection.choose_fighter(0, 4)
	press("back")
	check(game.screen == "pause" and game.characters[0] == 2 and game.model.state_hash() == before, "Cancel selection changed the fight or lost its return path")
	press("resume")
	check(game.screen == "play" and game.model.state_hash() == before, "Resume reset the fight")
	await verify_controller()
	game.open_pause()
	press("pause_home")
	press("development")
	press("confirm_fighters")
	check(game.editor_shell.visible and game.sprite_button.visible and game.diagnostics.visible, "Development tools are missing")
	game.fields.damage.control.value = 71
	game.apply_move()
	var fingerprint: String = game.model.fingerprint()
	game.training_momentum.select(2)
	game.go_home()
	press("matches")
	press("local")
	game.menus.selection.choose_fighter(0, 0)
	game.menus.selection.choose_fighter(1, 1)
	press("confirm_fighters")
	check(game.activity == "local" and not game.practice.visible and not game.editor_shell.visible and not game.inputs.visible and not game.show_boxes, "Local match contains lab controls")
	check(game.model.state().players[0].momentum == 0 and game.model.fingerprint() == fingerprint, "Practice meter leaked into match or move edits were lost")
	var original: Dictionary = game.model.data()
	var fixture: Dictionary = original.duplicate(true)
	fixture.characters[0].moves[0].damage = 1000
	fixture.characters[0].moves[0].startup = 1
	fixture.characters[0].moves[0].reach = 50000
	game.model.load_data(fixture)
	game.reset_round()
	key(KEY_J, true)
	game._physics_process(1.0 / 60.0)
	key(KEY_J, false)
	game._process(0.0)
	check(game.screen == "results" and game.menus.result_title.text == "Anvil wins.", "KO did not produce a winner/result screen")
	press("rematch")
	check(game.screen == "play" and game.model.state().winner == -1 and game.model.frame() == 0, "Rematch did not reset the round")
	game.model.load_data(original)
	game.go_home()
	await verify_online()
	# Leave the broader UI suite in its familiar lab fixture.
	game.go_home()
	game.model.restore_defaults()
	game.populate_editor()
	game.training_momentum.select(0)
	game.dummy.select(0)
	press("development")
	for p in 2:
		game.menus.selection.choose_fighter(p, p)
		game.selection_simple[p].button_pressed = false
	press("confirm_fighters")
	await tree.process_frame
	check(game.get_viewport().gui_get_focus_owner() == null, "Menu focus still captures gameplay controls")
	print("Godot menu flows: ", failures, " failures; entry, selection, input isolation, pause, results, online connection/recovery")
	return failures

func joy(button: int, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func verify_roster() -> void:
	var selection: FighterSelect = game.menus.selection
	await tree.process_frame
	check(game.get_viewport_rect().encloses(selection.start_button.get_global_rect()), "Character select action is outside the viewport")
	for step in [[KEY_RIGHT, 1], [KEY_DOWN, 3], [KEY_LEFT, 2], [KEY_DOWN, 4], [KEY_RIGHT, 5]]:
		var index: int = step[1]
		key(step[0], true)
		key(step[0], false)
		check(selection.chosen == [index, 1] and selection.tiles[index].has_focus(), "Roster navigation changed the wrong player's fighter")
	key(KEY_DOWN, true)
	key(KEY_DOWN, false)
	check(selection.start_button.has_focus(), "Roster Down did not reach Start")
	key(KEY_UP, true)
	key(KEY_UP, false)
	check(selection.tiles[5].has_focus(), "Start Up did not return to the current fighter")
	selection.slot_buttons[1].pressed.emit()
	check(selection.active_player == 1 and selection.tiles[1].has_focus(), "Switching player did not focus their retained selection")
	for _i in 2:
		joy(JOY_BUTTON_DPAD_DOWN, true)
		joy(JOY_BUTTON_DPAD_DOWN, false)
	check(selection.chosen == [5, 5] and selection.tiles[5].markers == [true, true], "Mirror selection lost a player or marker")
	selection.simple_checks[1].grab_focus()
	key(KEY_SPACE, true)
	key(KEY_SPACE, false)
	check(selection.simple_checks[1].button_pressed and not selection.simple_checks[0].button_pressed, "Input toggle changed both players")
	selection.set_active_player(0)
	selection.focus_selection()

func verify_controls_dialog() -> void:
	game.menus.buttons.controls.grab_focus()
	press("controls")
	await tree.process_frame
	var dialog: AcceptDialog
	for child in game.get_children():
		if child.has_method("show_bindings"): dialog = child
	check(dialog != null and game.has_open_dialog(), "Controls guide did not open")
	if dialog == null: return
	dialog.tabs[1].pressed.emit()
	check(dialog.bindings.get_child(0).text.begins_with("PLAYER 2"), "Controls tab did not switch bindings")
	dialog.tabs[2].pressed.emit()
	check(dialog.bindings.get_child(0).text.begins_with("GAMEPAD"), "Gamepad bindings missing")
	await tree.process_frame
	var scroll: ScrollContainer = dialog.find_child("ControlsBody", true, false)
	var close: Button = dialog.find_child("CloseAction", true, false)
	var close_position := close.global_position
	var tabs_position: Vector2 = dialog.tabs[0].global_position
	scroll.scroll_vertical = 500
	await tree.process_frame
	check(close.global_position == close_position and dialog.tabs[0].global_position == tabs_position and close.size.y >= 40, "Controls body moved its fixed navigation/Close action")
	dialog.canceled.emit()
	await tree.process_frame
	await tree.process_frame
	check(not game.has_open_dialog() and game.menus.buttons.controls.has_focus(), "Closing Controls did not return focus to its trigger")

func verify_controller() -> void:
	# Exercise real Godot UI actions with a synthetic pad; hardware testing is separate.
	joy(JOY_BUTTON_START, true)
	joy(JOY_BUTTON_START, false)
	await tree.process_frame
	check(game.screen == "pause" and game.menus.buttons.resume.has_focus(), "Controller Start did not open/focus pause")
	joy(JOY_BUTTON_DPAD_DOWN, true)
	joy(JOY_BUTTON_DPAD_DOWN, false)
	check(game.menus.buttons.restart.has_focus(), "Controller D-pad did not move menu focus")
	joy(JOY_BUTTON_DPAD_UP, true)
	joy(JOY_BUTTON_DPAD_UP, false)
	joy(JOY_BUTTON_A, true)
	check((game.screen == "pause" or game.input_release_required) and game.read_input(0) == 0, "Held controller confirm leaked into combat")
	joy(JOY_BUTTON_A, false)
	check(game.screen == "play" and game.read_input(0) == 0, "Controller confirm did not resume safely")
	game._physics_process(1.0 / 60.0)
	check(not game.input_release_required and game.model.state().players[0].move == -1, "Controller confirm became an attack after resume")
	game.go_home()
	press("matches")
	joy(JOY_BUTTON_B, true)
	joy(JOY_BUTTON_B, false)
	check(game.screen == "home", "Controller cancel did not return to main menu")
	press("training")
	press("confirm_fighters")

func verify_online() -> void:
	press("matches")
	press("online")
	check(not game.menus.selection.hero_panels[1].visible, "Online asks local user to select the remote fighter")
	game.menus.selection.choose_fighter(0, 4)
	press("confirm_fighters")
	game.address.text = " "
	press("join")
	check(not game.connection.active and game.net_status.text.contains("Enter the host address"), "Blank join address did not produce a useful error")
	game.address.text = "127.0.0.1"
	var socket := PacketPeerUDP.new()
	check(socket.bind(0) == OK, "Could not reserve a loopback test port")
	var chosen_port := socket.get_local_port()
	game.port.value = chosen_port
	socket.close()
	press("host")
	check(game.connection.active and game.screen == "online" and game.menus.buttons.host.disabled and not game.leave_button.disabled, "Host waiting/cancel state is incorrect")
	check(game.connection.active and game.connection.peer.host.get_local_port() == chosen_port, "Host ignored the selected port in favor of stale SpinBox text")
	var frame: int = game.model.frame()
	game._physics_process(1.0 / 60.0)
	check(game.model.frame() == frame, "Waiting for opponent advanced the fight")
	press("cancel_connection")
	check(not game.connection.active and not game.menus.buttons.host.disabled and game.address.editable, "Cancel did not restore connection form")
	press("host")
	var remote := NativePeer.new()
	var remote_model := CombatModel.new()
	remote_model.load_data(game.model.data())
	tree.root.add_child(remote)
	check(remote.begin(remote_model, false, "127.0.0.1", int(game.port.value), 3, true) == OK, "Loopback client could not join")
	for _i in 300:
		if game.connection.session != null and remote.session != null: break
		await tree.create_timer(0.01).timeout
	check(game.screen == "play" and game.connection.session != null and remote.session != null, "Handshake did not enter online match")
	if game.connection.session != null and remote.session != null:
		check(game.model.state().players[0].character == 4 and game.model.state().players[1].character == 3, "Online handshake ignored fighter choices")
		game.motion.instant = false
		game.open_pause()
		check(game.changing_layers(), "Online pause did not animate")
		check(not game.menus.buttons.restart.visible and not game.menus.buttons.change_fighters.visible and game.menus.pause_note.text.contains("continues"), "Online menu offers a local reset or hides continuing match")
		key(KEY_J, true)
		frame = game.model.frame()
		for _i in 6:
			game._physics_process(1.0 / 60.0)
			remote.tick(0)
			await tree.create_timer(0.01).timeout
		key(KEY_J, false)
		check(game.model.frame() > frame and game.model.state().players[0].move == -1, "Online menu froze network or sent attacks")
		remote.close()
		for _i in 300:
			if not game.connection.active: break
			await tree.create_timer(0.01).timeout
		check(game.screen == "online" and not game.connection.active and game.net_status.text.contains("disconnected") and not game.menus.buttons.join.disabled, "Disconnect did not return to a recoverable lobby")
	await game.wait_for_menu_motion()
	game.motion.instant = true
	game.finish_menu_motion()
	remote.close()
	remote.queue_free()
	game.cancel_connection()
	press("back")
	check(game.screen == "fighters" and game.menus.selection.chosen[0] == 4, "Lobby back lost local fighter")
	press("back")
	check(game.screen == "matches", "Online fighter selection back path is incorrect")
