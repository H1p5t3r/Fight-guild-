extends SceneTree

var failures := 0
var checks := 0
const PAD_A := {"id": 3, "name": "Test pad A", "guid": "fixture-a"}
const PAD_B := {"id": 7, "name": "Test pad B", "guid": "fixture-b"}

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr(message)

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var controls := FighterInputs.new()
	controls.persistence = false
	for player in 2:
		for action in 12:
			var code: int = controls.profiles[player].keys[action]
			check(controls.translate(player, {code: true}, {}, {}) == 1 << action, "Default keyboard action lost")
			check(controls.translate(1-player, {code: true}, {}, {}) == 0, "Keyboard leaked to other player")
			controls.gates = [{}, {}]
			code = controls.profiles[player].pad[action]
			var buttons := {code: true} if code < 100 else {}
			var axes := {JOY_AXIS_TRIGGER_LEFT if code == 100 else JOY_AXIS_TRIGGER_RIGHT: 1.0} if code >= 100 else {}
			check(controls.translate(player, {}, buttons, axes) == 1 << action, "Default pad action lost")
	controls.gates = [{}, {}]
	for pair in [[0.34, 0], [0.36, 2], [0.30, 2], [0.27, 0], [-0.36, 1], [-0.27, 0]]:
		check(controls.translate(0, {}, {}, {JOY_AXIS_LEFT_X: pair[0]}) == pair[1], "Stick threshold/release chattered")
	for pair in [[0.49, 0], [0.51, 2048], [0.45, 2048], [0.39, 0]]:
		check(controls.translate(0, {}, {}, {JOY_AXIS_TRIGGER_RIGHT: pair[0]}) == pair[1], "Trigger threshold/release chattered")
	check(controls.translate(0, {}, {JOY_BUTTON_DPAD_LEFT: true}, {JOY_AXIS_LEFT_X: 1.0}) == 1, "Stick drift overrode digital direction")
	check(controls.translate(0, {KEY_A: true, KEY_D: true, KEY_W: true, KEY_S: true}, {}, {}) == 0, "SOCD did not neutralize both pairs")
	check(controls.translate(0, {KEY_A: true, KEY_D: true}, {}, {}, false) != 0, "Held-input guard lost opposed held directions")
	controls.set_option(0, "stick_mode", 1)
	check(controls.translate(0, {}, {}, {JOY_AXIS_LEFT_X: 1.0}) == 0, "D-pad-only mode accepted the stick")
	controls.set_option(0, "stick_mode", 2)
	check(controls.translate(0, {}, {JOY_BUTTON_DPAD_LEFT: true}, {JOY_AXIS_LEFT_X: 1.0}) == 2, "Stick-only mode accepted D-pad")
	controls.reset_player(0)
	check(controls.bind(0, "keys", 4, KEY_F).is_empty(), "Keyboard remap rejected")
	check(controls.translate(0, {KEY_F: true}, {}, {}) == 16 and controls.translate(0, {KEY_J: true}, {}, {}) == 0, "Old/new keyboard mapping wrong")
	check(controls.bind(0, "keys", 5, KEY_F).is_empty() and controls.profiles[0].keys[4] == KEY_K, "Duplicate keyboard binding failed to swap")
	check(not controls.bind(0, "keys", 4, KEY_KP_1).is_empty(), "Cross-player keyboard collision accepted")
	check(not controls.bind(0, "keys", 4, KEY_ESCAPE).is_empty(), "Escape was remapped")
	check(not controls.bind(0, "pad", 4, JOY_BUTTON_START).is_empty(), "Start was remapped")
	check(controls.bind(0, "pad", 4, 100).is_empty() and controls.profiles[0].pad[10] == JOY_BUTTON_A, "Trigger/button swap failed")
	check(controls.bind(0, "keys", 4, -1).is_empty(), "Unbind rejected")
	controls.set_option(0, "keyboard", false)
	check(controls.translate(0, {KEY_F: true}, {}, {}) == 0, "Disabled keyboard still controls player")
	controls.refresh_devices([PAD_A, PAD_B])
	check(controls.assigned == [3, 7], "Automatic initial controller assignment failed")
	controls.refresh_devices([PAD_B])
	check(controls.assigned == [-1, 7], "Disconnect transferred P2 to P1")
	var replug := PAD_A.duplicate(); replug.id = 11
	controls.refresh_devices([PAD_B, replug])
	check(controls.assigned == [11, 7], "Controller did not reclaim its player after an ID change")
	controls.assign_device(0, 7)
	check(controls.assigned == [7, -1] and controls.profiles[1].device == "none", "Explicit pad assignment duplicated a controller")
	var path := "user://test-input-controls.json"
	check(controls.save_preferences(path).is_empty(), "Controls save failed")
	var loaded := FighterInputs.new()
	loaded.persistence = false
	loaded.load_preferences(path)
	check(loaded.profiles == controls.profiles, "Controls did not survive save/load")
	loaded.refresh_devices([PAD_B, replug])
	check(loaded.assigned == [7, -1], "Saved explicit controller selection was ignored")
	var saved: Array = loaded.profiles.duplicate(true)
	for invalid in [null, {}, {"version": 2, "players": saved}, {"version": 1, "players": []}]:
		var file := FileAccess.open(path, FileAccess.WRITE); file.store_string(JSON.stringify(invalid)); file.close()
		loaded.load_preferences(path)
		check(loaded.profiles == saved and not loaded.status.is_empty(), "Bad preferences partially replaced live controls")
	for field in ["deadzone", "trigger", "stick_mode", "keys", "pad", "device", "keyboard"]:
		var broken := saved.duplicate(true)
		broken[0][field] = null
		check(not FighterInputs.valid_profiles(broken), "Invalid profile field accepted: " + field)
	DirAccess.remove_absolute(path)
	controls.reset_player(0); controls.reset_player(1)
	verify_native_inputs(controls)
	controls.free(); loaded.free()
	print("Native input controls: %d failures; %d checks; remapping, devices, deadzones, persistence, motions and buffering" % [failures, checks])
	quit(1 if failures else 0)

func sample_bits(controls: FighterInputs, player: int, bits: int, gamepad: bool) -> int:
	var keys := {}
	var buttons := {}
	var axes := {}
	for i in 12:
		if bits & (1 << i) == 0: continue
		if not gamepad: keys[int(controls.profiles[player].keys[i])] = true
		else:
			var code := int(controls.profiles[player].pad[i])
			if code < 100: buttons[code] = true
			else: axes[JOY_AXIS_TRIGGER_LEFT if code == 100 else JOY_AXIS_TRIGGER_RIGHT] = 1.0
	return controls.translate(player, keys, buttons, axes)

func verify_native_inputs(controls: FighterInputs) -> void:
	# Exercise a remapped physical scheme through the actual native command parser.
	controls.bind(0, "keys", 4, KEY_F)
	controls.bind(1, "keys", 4, KEY_G)
	for player in 2:
		for gamepad in [false, true]:
			var forward := 2 if player == 0 else 1
			var model := LegacyFixture.create()
			model.reset([0, 0])
			for bits in [4, 4 | forward, forward | 16]:
				var raw := sample_bits(controls, player, bits, gamepad)
				model.step(raw if player == 0 else 0, raw if player == 1 else 0)
			check(model.state().players[player].move == 14, "236P motion failed in a facing/device")
			var snapshot := model.core.snapshot()
			for tick in 30: model.step(0, 0)
			var hash_value := model.state_hash()
			check(model.core.restore(snapshot), "Input history snapshot rejected")
			for tick in 30: model.step(0, 0)
			check(model.state_hash() == hash_value, "Buffered input replay diverged")
			model.reset([0, 0])
			for bits in [forward, 4, 4 | forward | 128]:
				var raw := sample_bits(controls, player, bits, gamepad)
				model.step(raw if player == 0 else 0, raw if player == 1 else 0)
			check(model.state().players[player].move == 16, "623Hs failed in a facing/device")
			for simple in [false, true]:
				model.reset([0, 0], [simple, simple])
				var raw := sample_bits(controls, player, 1024 | forward | 16, gamepad)
				model.step(raw if player == 0 else 0, raw if player == 1 else 0)
				check(model.state().players[player].move == (14 if simple else 8), "Simple toggle changed motion acceptance")
			# A whiffed normal cannot gatling; a late K buffers through recovery.
			for early in [false, true]:
				model.reset([0, 0])
				var p := sample_bits(controls, player, 16, gamepad)
				model.step(p if player == 0 else 0, p if player == 1 else 0)
				var normal: Dictionary = model.move(0, 0)
				var late := int(normal.startup + normal.active + normal.recovery - 5)
				for tick in (2 if early else late): model.step(0, 0)
				var k := sample_bits(controls, player, 32, gamepad)
				model.step(k if player == 0 else 0, k if player == 1 else 0)
				for tick in (20 if early else 3): model.step(0, 0)
				check(model.state().players[player].move == (-1 if early else 1), "Early/late buffered action boundary changed")
			model.reset([0, 0])
			var jump: int = controls.translate(player, {int(controls.profiles[player].keys[2]): true, int(controls.profiles[player].keys[3]): true}, {}, {})
			for tick in 10: model.step(jump if player == 0 else 0, jump if player == 1 else 0)
			check(model.state().players[player].y == 0, "Opposite vertical keys caused a jump")
