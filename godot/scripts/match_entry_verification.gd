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
	verify_local_match()
	await verify_online_gates()
	game.characters = [0, 1]
	game.simple = [false, false]
	game.round_number = 1
	game.match_score.reset()
	game.reset_round()
	game.go_home()
	await game.wait_for_menu_motion()
	game.motion.instant = true
	game.finish_menu_motion()
	await tree.process_frame
	print("Godot match entry: ", failures, " failures; real loading, two intros, four beats, skip/cancel, input isolation, first-to-two, draw replay, Final Down, peer readiness/generations")
	return failures

func knockout_data(model: CombatModel, fighters: Array) -> Dictionary:
	var data: Dictionary = model.data().duplicate(true)
	for fighter in fighters:
		var move: Dictionary = data.characters[fighter].moves[0]
		move.damage = 1000
		move.startup = 1
		move.reach = 50000
		move.hitstop = 0
	return data

func verify_local_match() -> void:
	game.motion.instant = true
	var original: Dictionary = game.model.data()
	game.model.load_data(knockout_data(game.model, [0, 1]))
	game.go_home()
	game.choose_activity("local")
	for p in 2: game.menus.selection.choose_fighter(p, p)
	game.confirm_selection()
	game.model.step(16, 0)
	game._process(0.0)
	check(game.match_score.wins == [1, 0] and game.round_number == 2 and game.model.frame() == 0, "First win did not reset fighters for 2nd Scrum")
	game.model.step(0, 16)
	game._process(0.0)
	check(game.match_score.wins == [1, 1] and game.round_number == 3 and game.screen == "play", "1–1 did not advance to Final Down")
	game.model.step(16, 16)
	check(game.model.state().winner == 2, "Draw fixture did not trade")
	game._process(0.0)
	check(game.match_score.wins == [1, 1] and game.round_number == 3 and game.model.frame() == 0, "Draw did not replay Final Down without awarding a win")
	game.model.step(16, 0)
	game._process(0.0)
	check(game.screen == "results" and game.match_score.wins == [2, 1], "Deciding Scrum did not end the match")
	game.menu_action("rematch")
	check(game.round_number == 1 and game.match_score.wins == [0, 0] and game.screen == "play", "Rematch retained the previous match score")
	game.model.load_data(original)
	game.go_home()
	game.motion.instant = false

func verify_online_gates() -> void:
	var host := NativePeer.new()
	var client := NativePeer.new()
	var host_model := CombatModel.new()
	var client_model := CombatModel.new()
	var fixture := knockout_data(host_model, [0, 4])
	host_model.load_data(fixture)
	client_model.load_data(fixture)
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
	await network_scrum(host, client, 0)
	check(host.score.wins == [1, 0] and client.score.wins == [1, 0], "Online first win did not agree")
	await next_network_scrum(host, client)
	await network_scrum(host, client, 1)
	check(host.score.wins == [1, 1] and client.score.next_number() == 3, "Online 1–1 did not produce Final Down")
	await next_network_scrum(host, client)
	await network_scrum(host, client, 0)
	check(host.phase == "result" and client.phase == "result" and host.score.wins == [2, 1] and client.score.wins == [2, 1], "Online deciding win did not finish both matches")
	check(not host.confirm_result() and host.score.wins == [2, 1], "Confirmed result was counted twice")
	host.close()
	client.close()
	host.queue_free()
	client.queue_free()

func network_scrum(host: NativePeer, client: NativePeer, winner: int) -> void:
	for _i in 300:
		if host.phase in ["intermission", "result"] and client.phase in ["intermission", "result"]: return
		host.tick(16 if winner == 0 else 0)
		client.tick(16 if winner == 1 else 0)
		if host.confirmed_winner() >= 0: host.confirm_result()
		if client.confirmed_winner() >= 0: client.confirm_result()
		await tree.create_timer(0.01).timeout
	check(false, "Online Scrum failed to confirm: " + host.error + " / " + client.error)

func next_network_scrum(host: NativePeer, client: NativePeer) -> void:
	var previous := host.generation
	host.finish_intermission()
	await tree.create_timer(0.03).timeout
	check(host.generation == previous and client.generation == previous, "A single intermission completion reset the round early")
	client.finish_intermission()
	for _i in 300:
		if host.phase == "intro" and client.phase == "intro": break
		await tree.create_timer(0.01).timeout
	check(host.generation == previous + 1 and client.generation == host.generation and host.model.frame() == 0 and client.model.frame() == 0, "Next Scrum did not prepare a shared fresh generation")
	var before := host.model.state_hash()
	host.handle_message({"type":"input", "generation":previous, "frame":0, "input":16})
	check(host.active and host.error.is_empty() and host.model.state_hash() == before, "Delayed old-round input contaminated the new Scrum")
	host.finish_intros()
	client.finish_intros()
	for _i in 300:
		if host.phase == "countdown" and client.phase == "countdown": break
		await tree.create_timer(0.01).timeout
	host.finish_countdown()
	client.finish_countdown()
	for _i in 300:
		if host.phase == "live" and client.phase == "live": return
		await tree.create_timer(0.01).timeout
	check(false, "Next Scrum did not release")
