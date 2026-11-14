class_name NativePeer
extends Node

signal status_changed(message: String)
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

func fail(message: String) -> void:
	error = message
	close()
	status_changed.emit(message)
	match_ended.emit()

func _connected(id: int) -> void:
	if opponent != 0:
		return
	opponent = id
	send({"type": "hello", "protocol": 1, "fingerprint": model.fingerprint(), "character": local_character, "simple": local_simple})

func send(message: Dictionary) -> void:
	if peer != null and opponent != 0:
		peer.set_target_peer(opponent)
		peer.put_packet(JSON.stringify(message).to_utf8_buffer())

func _process(delta: float) -> void:
	if peer == null:
		return
	elapsed_connection += delta
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
	if session == null and elapsed_connection > 30.0 and not is_host:
		fail("Connection timed out. Check the host address and UDP port.")
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
	match message.get("type", ""):
		"hello":
			if session != null or message.get("protocol") != 1 or message.get("fingerprint") != model.fingerprint():
				fail("Build or move data differs. Import the same move set or restore defaults on both clients.")
				return
			if not CombatModel.valid_integer(message.get("character")) or int(message.character) not in [0, 1] or not message.get("simple") is bool:
				fail("Invalid fighter selection.")
				return
			hello_received = true
			if is_host:
				var characters := [local_character, int(message.character)]
				var simplified := [local_simple, message.simple]
				send({"type": "start", "characters": characters, "simple": simplified})
				start_match(characters, simplified)
		"start":
			if is_host or not hello_received or session != null or not message.get("characters") is Array or not message.get("simple") is Array:
				fail("Unexpected match-start message.")
				return
			var characters: Array = message.characters
			var simplified: Array = message.simple
			if characters.size() != 2 or simplified.size() != 2 or not CombatModel.valid_integer(characters[0]) or int(characters[0]) not in [0, 1] or characters[1] != local_character or not simplified[0] is bool or not simplified[1] is bool or simplified[1] != local_simple:
				fail("Match selection does not match the handshake.")
				return
			start_match(characters, simplified)
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

func start_match(characters: Array, simple: Array) -> void:
	model.reset(characters, simple)
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
