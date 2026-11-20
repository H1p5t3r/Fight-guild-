class_name NativePeer
extends Node

signal status_changed(message: String)
signal match_preparing
signal countdown_started
signal match_started
signal match_ended
var peer: ENetMultiplayerPeer
var model: CombatModel
var session: RollbackSession
var player := 0
var local_character := 0
var local_simple := false
var opponent := 0
var is_host := false
var active := false
var error := ""
var hashes := {}
var last_sent_hash := -1
var verified_through := -1
var waiting_ticks := 0
var elapsed_connection := 0.0
var received_count := 0
var received_window := 0.0
var hello_received := false
var manual_presentation := false
var phase := "idle"
var phase_elapsed := 0.0
var local_ready := false
var remote_ready := false
var generation := 1
var score := MatchScore.new()
var match_characters := [5, 4]
var match_simple := [false, false]
var remote_winner := -1
var result_probe := CombatModel.new()
const ROUND_MESSAGES := ["intro_ready", "countdown_ready", "countdown", "go", "intermission_ready", "next_round", "input", "hash"]

func begin(simulation: CombatModel, host: bool, address: String, port: int, character: int, simple: bool) -> Error:
	close()
	model = simulation
	is_host = host
	player = 0 if host else 1
	local_character = character
	local_simple = simple
	peer = ENetMultiplayerPeer.new()
	var result := peer.create_server(port, 1) if host else peer.create_client(address, port)
	if result != OK:
		peer = null
		return result
	active = true
	phase = "connecting"
	error = ""
	peer.transfer_mode = MultiplayerPeer.TRANSFER_MODE_RELIABLE
	peer.peer_connected.connect(_connected)
	peer.peer_disconnected.connect(func(_id: int): fail("Opponent disconnected. Host or join a new match."))
	status_changed.emit("Hosting on UDP %d · waiting for an opponent" % port if host else "Connecting to %s:%d" % [address, port])
	return OK

func close() -> void:
	if peer != null:
		peer.close()
	peer = null
	session = null
	active = false
	opponent = 0
	hashes.clear()
	last_sent_hash = -1
	verified_through = -1
	waiting_ticks = 0
	elapsed_connection = 0.0
	received_count = 0
	received_window = 0.0
	hello_received = false
	phase = "idle"
	phase_elapsed = 0.0
	local_ready = false
	remote_ready = false
	generation = 1
	score.reset()
	remote_winner = -1

func fail(message: String) -> void:
	error = message
	close()
	status_changed.emit(message)
	match_ended.emit()

func _connected(id: int) -> void:
	if opponent != 0:
		return
	opponent = id
	send({"type": "hello", "protocol": 4, "fingerprint": model.fingerprint(), "character": local_character, "simple": local_simple})

func send(message: Dictionary) -> void:
	if peer != null and opponent != 0:
		if message.get("type") in ROUND_MESSAGES: message["generation"] = generation
		peer.set_target_peer(opponent)
		peer.put_packet(JSON.stringify(message).to_utf8_buffer())

func _process(delta: float) -> void:
	if peer == null:
		return
	elapsed_connection += delta
	phase_elapsed += delta
	received_window += delta
	if received_window >= 1.0:
		received_window = 0
		received_count = 0
	peer.poll()
	if peer == null:
		return
	if not is_host and peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		fail("Connection failed or closed. Check the host address and UDP port.")
		return
	if phase == "connecting" and elapsed_connection > 30.0 and not is_host:
		fail("Connection timed out. Check the host address and UDP port.")
		return
	if phase in ["intro", "countdown", "intermission"] and phase_elapsed > 45.0:
		fail("Match preparation timed out. Host or join a new match.")
		return
	while peer != null and peer.get_available_packet_count() > 0:
		var sender := peer.get_packet_peer()
		var packet := peer.get_packet()
		received_count += 1
		if sender != opponent or packet.size() > 4096 or received_count > 300:
			fail("Invalid peer packet or message rate.")
			return
		var message: Variant = JSON.parse_string(packet.get_string_from_utf8())
		if not message is Dictionary:
			fail("Invalid peer message.")
			return
		handle_message(message)

func handle_message(message: Dictionary) -> void:
	if message.get("type") in ROUND_MESSAGES:
		if not CombatModel.valid_integer(message.get("generation")):
			fail("Missing round generation.")
			return
		if int(message.generation) < generation: return # Delayed packets from the completed Scrum.
		if int(message.generation) != generation:
			fail("Round generation differs between peers.")
			return
	match message.get("type", ""):
		"hello":
			if hello_received or phase != "connecting" or message.get("protocol") != 4 or message.get("fingerprint") != model.fingerprint():
				fail("Build or move data differs. Import the same move set or restore defaults on both clients.")
				return
			if not CombatModel.valid_integer(message.get("character")) or int(message.character) not in range(CombatModel.CHARACTERS.size()) or not message.get("simple") is bool:
				fail("Invalid fighter selection.")
				return
			hello_received = true
			if is_host:
				var characters := [local_character, int(message.character)]
				var simplified := [local_simple, message.simple]
				send({"type": "start", "characters": characters, "simple": simplified})
				prepare_match(characters, simplified)
		"start":
			if is_host or not hello_received or phase != "connecting" or not message.get("characters") is Array or not message.get("simple") is Array:
				fail("Unexpected match-start message.")
				return
			var characters: Array = message.characters
			var simplified: Array = message.simple
			if characters.size() != 2 or simplified.size() != 2 or not CombatModel.valid_integer(characters[0]) or int(characters[0]) not in range(CombatModel.CHARACTERS.size()) or characters[1] != local_character or not simplified[0] is bool or not simplified[1] is bool or simplified[1] != local_simple:
				fail("Match selection does not match the handshake.")
				return
			prepare_match(characters, simplified)
		"intro_ready", "countdown_ready":
			var expected := "intro" if message.type == "intro_ready" else "countdown"
			if not is_host or phase != expected or remote_ready:
				fail("Unexpected preparation-ready message.")
				return
			remote_ready = true
			advance_preparation()
		"countdown":
			if is_host or phase != "intro" or not local_ready:
				fail("Unexpected countdown message.")
				return
			begin_countdown()
		"go":
			if is_host or phase != "countdown" or not local_ready:
				fail("Unexpected release message.")
				return
			start_match()
		"intermission_ready":
			if not is_host or phase not in ["live", "intermission"] or remote_ready or not CombatModel.valid_integer(message.get("winner")) or int(message.winner) not in [0, 1, 2]:
				fail("Unexpected intermission-ready message.")
				return
			remote_winner = int(message.winner)
			remote_ready = true
			advance_preparation()
		"next_round":
			var received_score: Variant = message.get("score")
			var score_matches: bool = received_score is Array and received_score.size() == 2 and CombatModel.valid_integer(received_score[0]) and CombatModel.valid_integer(received_score[1]) and int(received_score[0]) == score.wins[0] and int(received_score[1]) == score.wins[1]
			if is_host or phase != "intermission" or not local_ready or score.finished() or message.get("winner") != score.last_winner or not score_matches:
				fail("Next Scrum does not match the confirmed result.")
				return
			prepare_match(match_characters, match_simple, false)
		"input":
			if session == null or not CombatModel.valid_integer(message.get("frame")) or not CombatModel.valid_integer(message.get("input")):
				fail("Invalid input message.")
				return
			if not session.submit(1 - player, int(message.frame), int(message.input)):
				fail(session.error)
		"hash":
			if session == null or not CombatModel.valid_integer(message.get("frame")) or not (message.get("hash") is int or message.get("hash") is float):
				fail("Invalid state-check message.")
				return
			var frame := int(message.frame)
			var hash_value := int(message.hash)
			if frame < maxi(0, model.frame() - 240) or frame > model.frame() + 120 or hash_value < 0 or hash_value > 0xffffffff or message.hash != hash_value:
				fail("State-check message outside the allowed range.")
				return
			hashes[frame] = hash_value
		_:
			fail("Unknown peer message.")

func prepare_match(characters: Array, simple: Array, new_match: bool = true) -> void:
	if new_match:
		score.reset()
		generation = 1
	else: generation += 1
	match_characters = characters.duplicate()
	match_simple = simple.duplicate()
	session = null
	hashes.clear()
	last_sent_hash = -1
	verified_through = -1
	waiting_ticks = 0
	remote_winner = -1
	result_probe.load_data(model.data())
	model.reset(characters, simple)
	phase = "intro"
	phase_elapsed = 0.0
	local_ready = false
	remote_ready = false
	match_preparing.emit()
	# Headless transports may auto-ready; the game supplies its actual presentation gates.
	if not manual_presentation: finish_intros.call_deferred()

func finish_intros() -> void:
	mark_ready("intro")

func finish_countdown() -> void:
	mark_ready("countdown")

func confirmed_winner() -> int:
	if session == null or model.state().winner < 0: return -1
	var confirmed := mini(session.confirmed[0], session.confirmed[1])
	if confirmed >= model.frame() - 1: return int(model.state().winner)
	if not session.records.has(confirmed + 1): return -1
	if not result_probe.core.restore(session.records[confirmed + 1].before): return -1
	return int(result_probe.state().winner)

func confirm_result() -> bool:
	if phase != "live": return false
	var winner := confirmed_winner()
	if winner < 0 or not score.record(winner): return false
	if remote_ready and (remote_winner != winner or score.finished()):
		fail("Peers disagreed on the completed Scrum.")
		return false
	phase = "result" if score.finished() else "intermission"
	phase_elapsed = 0.0
	local_ready = false
	if not manual_presentation and not score.finished(): finish_intermission.call_deferred()
	return true

func finish_intermission() -> void:
	if not active or phase != "intermission" or local_ready: return
	local_ready = true
	if is_host: advance_preparation()
	else: send({"type": "intermission_ready", "winner": score.last_winner})

func mark_ready(expected: String) -> void:
	if not active or phase != expected or local_ready: return
	local_ready = true
	if is_host: advance_preparation()
	else: send({"type": "intro_ready" if expected == "intro" else "countdown_ready"})

func advance_preparation() -> void:
	if not local_ready or not remote_ready: return
	if phase == "intro":
		send({"type": "countdown"})
		begin_countdown()
	elif phase == "countdown":
		send({"type": "go"})
		start_match()
	elif phase == "intermission":
		if score.finished() or remote_winner != score.last_winner:
			fail("Peers disagreed on the completed Scrum.")
			return
		send({"type": "next_round", "winner": score.last_winner, "score": score.wins})
		prepare_match(match_characters, match_simple, false)

func begin_countdown() -> void:
	phase = "countdown"
	phase_elapsed = 0.0
	local_ready = false
	remote_ready = false
	countdown_started.emit()
	if not manual_presentation: finish_countdown.call_deferred()

func start_match() -> void:
	local_ready = false
	remote_ready = false
	remote_winner = -1
	phase = "live"
	phase_elapsed = 0.0
	session = RollbackSession.new(model)
	for frame in 2:
		for p in 2:
			session.submit(p, frame, 0)
	match_started.emit()

func tick(input: int) -> bool:
	if session == null:
		return false
	var frame := model.frame() + 2
	if session.actual.get(frame, [-1, -1])[player] == -1:
		if not session.submit(player, frame, input):
			fail(session.error)
			return false
		send({"type": "input", "frame": frame, "input": input})
	var advanced := session.advance()
	waiting_ticks = 0 if advanced else waiting_ticks + 1
	if waiting_ticks > 600:
		fail("Peer stopped sending input. Start a new match.")
		return false
	var confirmed_frame := mini(mini(session.confirmed[0], session.confirmed[1]), model.frame() - 1)
	var checkpoint := int(floor(confirmed_frame / 60.0)) * 60
	if checkpoint >= 0 and checkpoint > last_sent_hash:
		var hash_value := session.confirmed_hash(checkpoint)
		if hash_value >= 0:
			send({"type": "hash", "frame": checkpoint, "hash": hash_value})
			last_sent_hash = checkpoint
	for frame_key in hashes.keys():
		var own := session.confirmed_hash(frame_key)
		if own >= 0:
			if own != hashes[frame_key]:
				fail("Desync at frame %d. Match stopped." % frame_key)
				return false
			verified_through = maxi(verified_through, frame_key)
			hashes.erase(frame_key)
	status_changed.emit("Player %d · %s · %d rollbacks / max %df · verified %df" % [player + 1, "connected" if advanced else "waiting", session.rollbacks, session.largest, verified_through])
	return advanced
