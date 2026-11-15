extends RefCounted

var failures := 0
var tree: SceneTree
var game: Control

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("Match entry check: " + description)

func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func wait_for_phase(phase: String) -> void:
	for _i in 300:
		if game.match_entry.phase == phase: return
		await tree.create_timer(0.01).timeout
	check(false, "Timed out waiting for " + phase)

func run(runtime: SceneTree, subject: Control) -> int:
	tree = runtime
	game = subject
	game.motion.instant = false
	game.choose_activity("local")
	game.menus.selection.choose_fighter(0, 2)
	game.menus.selection.choose_fighter(1, 5)
	await game.wait_for_menu_motion()
	key(KEY_J, true)
	game.confirm_selection()
	check(game.screen == "entry" and game.match_entry.phase == "loading", "Selection skipped the loading screen")
	var before: int = game.model.state_hash()
	game._physics_process(1.0 / 60.0)
	check(game.model.state_hash() == before and game.read_input(0) == 0, "Loading accepted combat input or advanced the clock")
	await wait_for_phase("intro")
	var entry: MatchEntry = game.match_entry
	entry.set_process(false)
	check(entry.load_progress == 1.0 and entry.intro_player == 0 and entry.characters == [2, 5], "Assets or first fighter intro do not match selection")
	entry._process(float(MatchCeremony.script().introSeconds) + 0.01)
	check(entry.phase == "intro" and entry.intro_player == 1, "Second fighter intro did not follow the first")
	entry._process(float(MatchCeremony.script().introSeconds) + 0.01)
	check(entry.phase == "opening" and entry.beat == 0, "First opening phrase is missing")
	for beat in 3:
		check(entry.phase == "opening" and entry.beat == beat, "Opening order is not phrase, phrase, numbered call")
		game._physics_process(1.0 / 60.0)
		check(game.model.state_hash() == before, "Opening changed health, timer or combat buffers")
		entry._process(float(MatchCeremony.script().beatSeconds[beat]) + 0.01)
	check(game.screen == "play" and entry.phase == "release" and game.model.frame() == 0, "Release call did not unlock frame zero")
	check(game.input_release_required and game.read_input(0) == 0, "Held intro button leaked into combat")
	check(game.play_root.mouse_behavior_recursive == Control.MOUSE_BEHAVIOR_INHERITED, "Match controls stayed disabled after entry")
	key(KEY_J, false)
	game._physics_process(1.0 / 60.0)
	check(game.model.frame() == 1 and game.model.state().players[0].move == -1, "Combat did not begin cleanly after release")
	entry._process(0.7)
	entry.set_process(true)
	# A held Select cannot skip the intro it just opened. A new press can.
	game.go_home()
	game.choose_activity("local")
	await game.wait_for_menu_motion()
	key(KEY_ENTER, true)
	game.confirm_selection()
	await wait_for_phase("intro")
	key(KEY_ENTER, true)
	check(entry.phase == "intro", "Held menu confirm skipped the character introduction")
	key(KEY_ENTER, false)
	key(KEY_ENTER, true)
	key(KEY_ENTER, false)
	check(entry.phase == "opening" and entry.beat == 0, "Fresh skip did not preserve the full opening sequence")
	key(KEY_ESCAPE, true)
	key(KEY_ESCAPE, false)
	await game.wait_for_menu_motion()
	check(game.screen == "fighters" and entry.phase == "hidden", "Cancel left an orphaned intro or failed to restore selection")
	game.confirm_selection()
	key(KEY_ESCAPE, true)
	key(KEY_ESCAPE, false)
	await tree.create_timer(0.7).timeout
	check(game.screen == "fighters" and game.model.frame() == 0, "Canceled loading later reopened combat")
	check(MatchCeremony.round_call(1) == "1st Scrum" and MatchCeremony.round_call(2) == "2nd Scrum" and MatchCeremony.round_call(3) == "Final Down", "Numbered calls do not match the chosen names")
	await verify_online_gates()
	game.characters = [0, 1]
	game.simple = [false, false]
	game.round_number = 1
	game.reset_round()
	game.go_home()
	await game.wait_for_menu_motion()
	game.motion.instant = true
	game.finish_menu_motion()
	await tree.process_frame
	print("Godot match entry: ", failures, " failures; real loading, two intros, four beats, skip/cancel, input isolation, peer readiness")
	return failures

func verify_online_gates() -> void:
	var host := NativePeer.new()
	var client := NativePeer.new()
	var host_model := CombatModel.new()
	var client_model := CombatModel.new()
	for peer in [host, client]:
		peer.manual_presentation = true
		tree.root.add_child(peer)
	var socket := PacketPeerUDP.new()
	check(socket.bind(0) == OK, "Could not reserve readiness-test port")
	var port := socket.get_local_port()
	socket.close()
	check(host.begin(host_model, true, "127.0.0.1", port, 0, false) == OK, "Readiness host failed")
	check(client.begin(client_model, false, "127.0.0.1", port, 4, true) == OK, "Readiness client failed")
	for _i in 300:
		if host.phase == "intro" and client.phase == "intro": break
		await tree.create_timer(0.01).timeout
	check(host.phase == "intro" and client.phase == "intro", "Handshake did not prepare both presentations")
	host.finish_intros()
	for _i in 5:
		host.tick(16)
		client.tick(64)
		await tree.create_timer(0.01).timeout
	check(host.session == null and client.session == null and host_model.frame() == 0 and client_model.frame() == 0, "Faster intro allowed early combat")
	client.finish_intros()
	for _i in 300:
		if host.phase == "countdown" and client.phase == "countdown": break
		await tree.create_timer(0.01).timeout
	check(host.phase == "countdown" and client.phase == "countdown", "Both-ready did not start the opening")
	host.finish_countdown()
	await tree.create_timer(0.05).timeout
	host.tick(16)
	client.tick(64)
	check(host.session == null and client.session == null and host_model.frame() == 0, "One countdown released the match before the other finished")
	client.finish_countdown()
	for _i in 300:
		if host.session != null and client.session != null: break
		await tree.create_timer(0.01).timeout
	check(host.phase == "live" and client.phase == "live" and host_model.state_hash() == client_model.state_hash(), "Release did not create matching frame-zero sessions")
	for _i in 8:
		host.tick(0)
		client.tick(0)
		await tree.create_timer(0.01).timeout
	check(host_model.frame() > 0 and host_model.state_hash() == client_model.state_hash(), "Readiness handshake broke subsequent combat parity")
	host.close()
	client.close()
	host.queue_free()
	client.queue_free()
