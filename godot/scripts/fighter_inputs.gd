class_name FighterInputs
extends Node

# Physical controls end here. Only the resulting 12-bit sample enters the
# deterministic combat buffer, recordings and rollback transport.
signal changed
signal devices_changed
signal controller_lost(player: int)

const PATH := "user://controls.json"
const ACTIONS := ["Left", "Right", "Down / crouch", "Up / jump", "P", "K", "S", "Hs", "D", "Run / dash", "", "Faultless Defense"]
const KEYS := [[KEY_A, KEY_D, KEY_S, KEY_W, KEY_J, KEY_K, KEY_L, KEY_I, KEY_O, KEY_SPACE, -1, KEY_Q], [KEY_LEFT, KEY_RIGHT, KEY_DOWN, KEY_UP, KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_5, KEY_KP_6, KEY_KP_0, -1, KEY_KP_ENTER]]
const PAD := [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_UP, JOY_BUTTON_A, JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_B, JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_LEFT_SHOULDER, -1, 101]
const PAD_NAMES := ["A / Cross", "B / Circle", "X / Square", "Y / Triangle", "Back / Select", "Guide", "Start / Options", "Left stick click", "Right stick click", "LB / L1", "RB / R1", "D-pad up", "D-pad down", "D-pad left", "D-pad right", "Misc", "Paddle 1", "Paddle 2", "Paddle 3", "Paddle 4", "Touchpad"]

var profiles: Array = [defaults(0), defaults(1)]
var assigned := [-1, -1]
var devices: Array = []
var reservations := ["", ""]
var gates := [{}, {}]
var persistence := true
var status := ""

static func defaults(player: int) -> Dictionary:
	return {"keys": KEYS[player].duplicate(), "pad": PAD.duplicate(), "keyboard": true, "device": "auto", "deadzone": 0.35, "trigger": 0.5, "stick_mode": 0}

func _ready() -> void:
	persistence = not OS.get_cmdline_user_args().has("--test")
	if persistence: load_preferences()
	Input.joy_connection_changed.connect(on_connection)
	refresh_devices()

static func device_key(device: Dictionary) -> String:
	return str(device.guid) + "|" + str(device.name)

static func connected_devices() -> Array:
	var result := []
	for id in Input.get_connected_joypads():
		result.append({"id": id, "name": Input.get_joy_name(id), "guid": Input.get_joy_guid(id)})
	return result

func on_connection(_id: int, _connected: bool) -> void:
	refresh_devices()

func refresh_devices(available: Variant = null) -> void:
	var lost := []
	var used := []
	if available == null: available = connected_devices()
	devices = available.duplicate(true)
	# Retain live assignments; removing P1 must never move P2 into P1's slot.
	for p in 2:
		var found := false
		for device in devices:
			if device.id == assigned[p]: found = true
		if assigned[p] >= 0 and not found:
			assigned[p] = -1
			gates[p].clear()
			lost.append(p)
		if assigned[p] >= 0: used.append(assigned[p])
	# Reclaim known devices before giving a new device an unused automatic slot.
	for pass_index in 2:
		for p in 2:
			if assigned[p] >= 0 or profiles[p].device == "none": continue
			var wanted: String = reservations[p] if profiles[p].device == "auto" else profiles[p].device
			if (pass_index == 0) != (not wanted.is_empty()): continue
			for device in devices:
				if device.id in used or (not wanted.is_empty() and device_key(device) != wanted): continue
				assigned[p] = int(device.id)
				reservations[p] = device_key(device)
				used.append(device.id)
				gates[p].clear()
				break
	for p in lost: controller_lost.emit(p)
	devices_changed.emit()

func assign_device(player: int, id: int) -> void:
	# -2 is automatic, -1 explicitly disables the controller for this player.
	assigned[player] = -1
	reservations[player] = ""
	profiles[player].device = "auto" if id == -2 else "none"
	for device in devices:
		if device.id != id: continue
		profiles[player].device = device_key(device)
		assigned[player] = id
		reservations[player] = device_key(device)
		if assigned[1-player] == id:
			assigned[1-player] = -1
			reservations[1-player] = ""
			profiles[1-player].device = "none"
	gates = [{}, {}]
	refresh_devices(devices)
	commit()

func assign_sides(keyboards: Array, pads: Array) -> void:
	# The side selector can exchange the two keyboard layouts without changing
	# their physical bindings. Only one keyboard layout and one pad per side.
	var previous := profiles.duplicate(true)
	var swap: bool = keyboards[0] == 1 or keyboards[1] == 0
	for p in 2:
		profiles[p].keys = previous[1-p if swap else p].keys.duplicate()
		profiles[p].keyboard = keyboards[p] >= 0
		profiles[p].device = "none"
		assigned[p] = -1
		reservations[p] = ""
		for device in devices:
			if device.id == pads[p]:
				profiles[p].device = device_key(device)
				assigned[p] = int(device.id)
				reservations[p] = device_key(device)
	gates = [{}, {}]
	commit()
	devices_changed.emit()

func set_option(player: int, field: String, value: Variant) -> void:
	if field not in ["keyboard", "deadzone", "trigger", "stick_mode"]: return
	var candidate := profiles.duplicate(true)
	candidate[player][field] = value
	if not valid_profiles(candidate): return
	profiles = candidate
	gates[player].clear()
	commit()

static func valid_binding(kind: String, code: Variant) -> bool:
	if not (code is int or code is float) or not is_finite(float(code)) or code != int(code): return false
	code = int(code)
	if code == -1: return true
	if kind == "pad": return code in [100, 101] or (code >= 0 and code < PAD_NAMES.size() and code not in [JOY_BUTTON_START, JOY_BUTTON_GUIDE])
	return code > 0 and code <= KEY_UNKNOWN and code not in [KEY_ESCAPE, KEY_BACKSPACE, KEY_UNKNOWN] and not OS.get_keycode_string(int(code)).is_empty()

static func valid_profiles(value: Variant) -> bool:
	if not value is Array or value.size() != 2: return false
	var keys := []
	for profile in value:
		if not profile is Dictionary: return false
		for field in defaults(0):
			if not profile.has(field): return false
		if not profile.keyboard is bool or not profile.device is String or profile.device.length() > 512: return false
		for field in ["deadzone", "trigger"]:
			if not (profile[field] is float or profile[field] is int) or not is_finite(float(profile[field])) or profile[field] < 0.1 or profile[field] > 0.9: return false
		if not (profile.stick_mode is int or profile.stick_mode is float) or profile.stick_mode != int(profile.stick_mode) or int(profile.stick_mode) not in [0, 1, 2]: return false
		for kind in ["keys", "pad"]:
			if not profile[kind] is Array or profile[kind].size() != 12: return false
			var seen := []
			for raw_code in profile[kind]:
				if not valid_binding(kind, raw_code): return false
				var code := int(raw_code)
				if code == -1: continue
				if code in seen or (kind == "keys" and code in keys): return false
				seen.append(code)
				if kind == "keys": keys.append(code)
	return true

func bind(player: int, kind: String, action: int, code: int) -> String:
	if player not in [0, 1] or kind not in ["keys", "pad"] or action < 0 or action >= 12 or action == 10 or not valid_binding(kind, code):
		return "That control is reserved or unsupported. Esc and Start always open the menu."
	if kind == "keys" and code >= 0 and code in profiles[1-player].keys:
		return "%s is already assigned to Player %d. Clear that binding first." % [binding_name(kind, code), 2-player]
	var mapping: Array = profiles[player][kind]
	var previous: int = mapping[action]
	var conflict := mapping.find(code) if code >= 0 else -1
	if conflict >= 0: mapping[conflict] = previous
	mapping[action] = code
	gates[player].clear()
	commit()
	return ""

func reset_player(player: int) -> void:
	# Do not silently overwrite another player's chosen keyboard bindings.
	var fresh := defaults(player)
	for i in 12:
		if fresh.keys[i] in profiles[1-player].keys: fresh.keys[i] = -1
	profiles[player] = fresh
	assigned[player] = -1
	reservations[player] = ""
	gates[player].clear()
	refresh_devices(devices)
	commit()

func commit() -> void:
	status = save_preferences() if persistence else ""
	changed.emit()

func save_preferences(path: String = PATH) -> String:
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return "Controls work for this session, but could not be saved."
	file.store_string(JSON.stringify({"version": 1, "players": profiles}, "\t"))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK: return "Controls work for this session, but could not be saved."
	if DirAccess.rename_absolute(path + ".tmp", path) != OK: return "Controls work for this session, but could not be saved."
	return ""

func load_preferences(path: String = PATH) -> void:
	if not FileAccess.file_exists(path): return
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not value is Dictionary or value.get("version") != 1 or not valid_profiles(value.get("players")):
		status = "Saved controls could not be read. Using defaults; your file has been preserved."
		return
	profiles = value.players
	# JSON numbers are floats in Godot; membership/duplicate checks use integers.
	for profile in profiles:
		profile.stick_mode = int(profile.stick_mode)
		for kind in ["keys", "pad"]:
			for i in 12: profile[kind][i] = int(profile[kind][i])
			# Free the old modifier's key/trigger for ordinary remapping.
			profile[kind][10] = -1
	assigned = [-1, -1]
	reservations = ["", ""]
	gates = [{}, {}]
	status = ""

static func binding_name(kind: String, code: int) -> String:
	if code < 0: return "Unbound"
	if kind == "keys": return OS.get_keycode_string(code)
	if code == 100: return "LT / L2"
	if code == 101: return "RT / R2"
	return PAD_NAMES[code] if code < PAD_NAMES.size() else "Button %d" % code

func device_name(player: int) -> String:
	for device in devices:
		if device.id == assigned[player]: return "%s · #%d" % [device.name, device.id + 1]
	return "No controller" if profiles[player].device == "none" else "Waiting for controller"

func gate(player: int, key: String, value: float, threshold: float) -> bool:
	# A small release margin avoids chatter near the activation threshold.
	var edge := threshold * 0.8 if gates[player].get(key, false) else threshold
	var active := value > edge
	gates[player][key] = active
	return active

static func clean_directions(raw: int) -> int:
	if raw & 3 == 3: raw &= ~3
	if raw & 12 == 12: raw &= ~12
	return raw

func translate(player: int, keys: Dictionary, buttons: Dictionary, axes: Dictionary, clean: bool = true) -> int:
	var profile: Dictionary = profiles[player]
	var raw := 0
	var pad := 0
	if profile.keyboard:
		for i in 12:
			if keys.get(int(profile.keys[i]), false): raw |= 1 << i
	for i in 12:
		var code := int(profile.pad[i])
		var active: bool = buttons.get(code, false) if code < 100 else gate(player, "trigger%d" % code, float(axes.get(JOY_AXIS_TRIGGER_LEFT if code == 100 else JOY_AXIS_TRIGGER_RIGHT, 0.0)), profile.trigger)
		if active: pad |= 1 << i
	var stick := 0
	for i in 4:
		var amount := float(axes.get(JOY_AXIS_LEFT_X if i < 2 else JOY_AXIS_LEFT_Y, 0.0)) * (-1 if i in [0, 3] else 1)
		if gate(player, "stick%d" % i, amount, profile.deadzone): stick |= 1 << i
	# Digital directions take precedence over stick drift in combined mode.
	if profile.stick_mode == 2: pad = (pad & ~15) | stick
	elif profile.stick_mode == 0 and pad & 15 == 0: pad |= stick
	raw = (raw | pad) & ~1024
	return clean_directions(raw) if clean else raw

func sample(player: int, keys: Dictionary, clean: bool = true) -> int:
	var buttons := {}
	var axes := {}
	if assigned[player] >= 0:
		for code in range(PAD_NAMES.size()): buttons[code] = Input.is_joy_button_pressed(assigned[player], code)
		for axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]: axes[axis] = Input.get_joy_axis(assigned[player], axis)
	return translate(player, keys, buttons, axes, clean)

func physical_keys() -> Dictionary:
	var result := {}
	for profile in profiles:
		for code in profile.keys:
			if code >= 0 and (Input.is_physical_key_pressed(int(code)) or Input.is_key_pressed(int(code))): result[int(code)] = true
	return result

func any_held() -> bool:
	var keys := physical_keys()
	return sample(0, keys, false) != 0 or sample(1, keys, false) != 0

static func notation(raw: int) -> String:
	var x := int(bool(raw & 2)) - int(bool(raw & 1))
	var y := int(bool(raw & 8)) - int(bool(raw & 4))
	var result := str(5 + x + y * 3)
	for i in range(4, 12):
		if i != 10 and raw & (1 << i): result += " + " + ACTIONS[i]
	return result

func keyboard_hint(player: int) -> String:
	if not profiles[player].keyboard: return "Keyboard off · " + device_name(player) + " · Controls to change bindings"
	var values := []
	for index in profiles[player].keys.size():
		if index != 10: values.append(binding_name("keys", int(profiles[player].keys[index])))
	return "%s / %s / %s / %s move · %s / %s / %s / %s / %s attack · %s dash · Back + %s FD" % values
