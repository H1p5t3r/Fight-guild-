extends Control

const Arena = preload("res://scripts/arena.gd")
const SAVE_PATH := "user://moves.json"
const ACCENT := Color("f4b45e")
const MUTED := Color("a3adb4")
const KEY_MAPS := [{KEY_A:1, KEY_D:2, KEY_S:4, KEY_W:8, KEY_J:16, KEY_K:32, KEY_L:64, KEY_I:128, KEY_O:256, KEY_SPACE:512, KEY_SHIFT:1024}, {KEY_LEFT:1, KEY_RIGHT:2, KEY_DOWN:4, KEY_UP:8, KEY_KP_1:16, KEY_KP_2:32, KEY_KP_3:64, KEY_KP_5:128, KEY_KP_6:256, KEY_KP_0:512, KEY_KP_ADD:1024}]
var model := CombatModel.new()
var connection := NativePeer.new()
var characters := [0, 1]
var simple := [false, false]
var held := {}
var paused := false
var show_boxes := true
var history: Array[String] = []
var last_raw := 0
var arena: Control
var input_label: Label
var action_label: Label
var editor_status: Label
var net_status: Label
var trial_status: Label
var mode: OptionButton
var dummy: OptionButton
var edit_character: OptionButton
var edit_move: OptionButton
var fields := {}
var buffer_fields: Array[SpinBox] = []
var editor_title: Label
var routes: Label
var pause_button: Button
var locked_buttons: Array[Button] = []
var selection_dialog: ConfirmationDialog
var selection_characters: Array[OptionButton] = []
var selection_simple: Array[CheckBox] = []
var file_dialog: FileDialog
var importing := false
var address: LineEdit
var port: SpinBox
var leave_button: Button

func _ready() -> void:
	name = "FightGuild"
	build_theme()
	build_interface()
	add_child(connection)
	connection.status_changed.connect(func(message: String): net_status.text = message)
	connection.match_started.connect(func(): held.clear(); history.clear(); paused = false)
	connection.match_ended.connect(func(): lock_online(false); reset_round())
	if FileAccess.file_exists(SAVE_PATH) and not OS.get_cmdline_user_args().has("--test"):
		var error := model.load_file(SAVE_PATH)
		editor_status.text = "Loaded your saved move set." if error.is_empty() else error
	populate_editor()
	if not OS.get_cmdline_user_args().has("--test"):
		selection_dialog.popup_centered(Vector2i(660, 340))

func box(color: Color, border: Color = Color("39444d")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func build_theme() -> void:
	theme = Theme.new()
	theme.default_font_size = 13
	theme.set_color("font_color", "Label", Color("f0ede5"))
	theme.set_stylebox("panel", "PanelContainer", box(Color("1b2329")))
	theme.set_stylebox("normal", "Button", box(Color("26323b")))
	theme.set_stylebox("hover", "Button", box(Color("3c4a54")))
	theme.set_stylebox("pressed", "Button", box(Color("63503a"), ACCENT))
	theme.set_stylebox("normal", "LineEdit", box(Color("111a21")))
	theme.set_constant("separation", "VBoxContainer", 10)
	theme.set_constant("separation", "HBoxContainer", 10)

func label(parent: Node, text: String, font_size: int = 13, color: Color = Color("f0ede5")) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	parent.add_child(node)
	return node

func button(parent: Node, text: String, action: Callable, lock_during_online: bool = false) -> Button:
	var node := Button.new()
	node.text = text
	node.pressed.connect(action)
	node.pressed.connect(release_focus_from_ui)
	parent.add_child(node)
	if lock_during_online:
		locked_buttons.append(node)
	return node

func option(parent: Node, caption: String, values: Array, selected: int = 0) -> OptionButton:
	var column := VBoxContainer.new()
	parent.add_child(column)
	if not caption.is_empty(): label(column, caption, 11, MUTED)
	var node := OptionButton.new()
	for value in values: node.add_item(str(value))
	node.selected = selected
	column.add_child(node)
	return node

func row(parent: Node) -> HBoxContainer:
	var node := HBoxContainer.new()
	parent.add_child(node)
	return node

func panel(parent: Node) -> VBoxContainer:
	var shell := PanelContainer.new()
	parent.add_child(shell)
	var column := VBoxContainer.new()
	shell.add_child(column)
	return column

func build_interface() -> void:
	var margins := MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]: margins.add_theme_constant_override("margin_" + edge, 24)
	add_child(margins)
	var root := VBoxContainer.new()
	margins.add_child(root)
	var header := row(root)
	var brand := label(header, "FG   FIGHT GUILD", 23, ACCENT)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label(header, "NATIVE COMBAT LAB / 002", 11, MUTED)
	button(header, "Fighter select", func(): selection_dialog.popup_centered(Vector2i(660,340)), true)
	button(header, "Controls", show_controls)
	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(content)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(left)
	label(left, "Find the fight.", 31)
	label(left, "Play a route. Tune a move. Run it back.", 13, MUTED)
	var toolbar := row(left)
	mode = option(toolbar, "", ["Training", "Local versus"])
	mode.item_selected.connect(func(_i: int): reset_round(); dummy.disabled = mode.selected == 1)
	dummy = option(toolbar, "", ["Stand", "Guard all", "Crouch guard", "Practice sequence"])
	button(toolbar, "Hitboxes", func(): show_boxes = not show_boxes)
	pause_button = button(toolbar, "Pause", func(): paused = not paused; pause_button.text = "Resume" if paused else "Pause", true)
	button(toolbar, "+1 frame", advance_one, true)
	button(toolbar, "Reset", reset_round, true)
	arena = Arena.new()
	left.add_child(arena)
	arena.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed: release_focus_from_ui())
	var inputs := row(left)
	input_label = label(inputs, "INPUT HISTORY   —", 12, ACCENT)
	input_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_label = label(inputs, "READY", 12, MUTED)
	label(left, "WASD move  ·  J / K / L / I / O attack  ·  Space dash  ·  Shift simple modifier", 12, MUTED)
	var lower := row(left)
	var network := panel(lower)
	network.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label(network, "Rollback workbench", 17)
	var test_row := row(network)
	button(test_row, "Run latency check", run_trial)
	trial_status = label(test_row, "6–9 frames of delay", 11, MUTED)
	var net_row := row(network)
	address = LineEdit.new()
	address.text = "127.0.0.1"
	address.placeholder_text = "Host IP"
	address.custom_minimum_size.x = 145
	net_row.add_child(address)
	port = SpinBox.new()
	port.min_value = 1024
	port.max_value = 65535
	port.value = 7000
	port.custom_minimum_size.x = 100
	net_row.add_child(port)
	button(net_row, "Host", func(): start_network(true), true)
	button(net_row, "Join", func(): start_network(false), true)
	leave_button = button(net_row, "Leave", func(): connection.close(); lock_online(false); reset_round(); net_status.text = "Offline · local play")
	leave_button.disabled = true
	net_status = label(network, "Offline · local play / direct UDP", 11, MUTED)
	net_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var route_panel := panel(lower)
	label(route_panel, "Unified gatlings", 17)
	label(route_panel, "P → P / K\nK → jump / command\nS → jump / Hs / command\nHs → command", 12, MUTED)
	label(route_panel, "All attacks → same-button command", 10, ACCENT)
	var editor_shell := PanelContainer.new()
	editor_shell.custom_minimum_size.x = 352
	content.add_child(editor_shell)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	editor_shell.add_child(scroll)
	var editor := VBoxContainer.new()
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(editor)
	label(editor, "MAKE IT YOURS", 10, MUTED)
	label(editor, "Move editor", 25)
	label(editor, "Apply a change, reset, and test it immediately.", 11, MUTED)
	var pickers := row(editor)
	edit_character = option(pickers, "Character", CombatModel.CHARACTERS)
	edit_move = option(pickers, "Move", CombatModel.MOVE_IDS)
	edit_character.item_selected.connect(func(_i: int): populate_editor())
	edit_move.item_selected.connect(func(_i: int): populate_editor())
	editor_title = label(editor, "5P / NORMAL", 22, ACCENT)
	label(editor, "FRAME DATA", 11, MUTED)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	editor.add_child(grid)
	for spec in [["startup","Startup",1,120,1],["active","Active",1,120,1],["recovery","Recovery",0,180,1],["damage","Damage",0,1000,1],["hitstun","Hitstun",0,180,1],["blockstun","Blockstun",0,180,1],["hitstop","Hitstop",0,30,1],["pushback","Push (px)",0,200,100],["advance","Advance (px)",-100,100,100],["reach","Reach (px)",1,500,100],["bottom","Bottom (px)",-500,500,100],["height","Height (px)",1,500,100]]:
		add_field(grid, spec)
	label(editor, "CANCEL BEHAVIOR", 11, MUTED)
	var checks := GridContainer.new()
	checks.columns = 2
	editor.add_child(checks)
	for pair in [["specialCancel","Special cancel"],["jumpCancel","Jump cancel"],["whiffCancel","Whiff cancel"],["selfCancel","Allow self route"]]:
		var check := CheckBox.new()
		check.text = pair[1]
		check.add_theme_font_size_override("font_size", 11)
		checks.add_child(check)
		fields[pair[0]] = {"control": check, "scale": 1}
	routes = label(editor, "", 11, MUTED)
	routes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var advanced := VBoxContainer.new()
	editor.add_child(advanced)
	advanced.visible = false
	button(editor, "Input & advanced rules ▾", func(): advanced.visible = not advanced.visible)
	var advanced_grid := GridContainer.new()
	advanced_grid.columns = 2
	advanced.add_child(advanced_grid)
	for spec in [["button","Button (0–4)",0,4,1],["category","Kind (0–3)",0,3,1],["direction","Direction (1–9)",1,9,1],["motion","Motion (0/214/236/623)",0,623,1],["air","Air (0/1)",0,1,1],["hitLevel","Guard level (0–2)",0,2,1],["simpleDirection","Simple direction",0,9,1],["simpleButton","Simple button",0,4,1],["normalRoutes","Normal mask",-1,31,1],["commandRoutes","Command mask",-1,31,1]]:
		add_field(advanced_grid, spec)
	var note := label(advanced, "Kind: 0 normal, 1 command, 2 special, 3 Drive. Button: P=0 K=1 S=2 Hs=3 D=4. Masks: −1 unified; P=1 K=2 S=4 Hs=8 D=16.", 10, MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button(editor, "Apply & reset", apply_move, true)
	var saves := row(editor)
	button(saves, "Save locally", func(): var error := model.save_file(SAVE_PATH); editor_status.text = "Saved to " + SAVE_PATH if error.is_empty() else error)
	button(saves, "Export", func(): show_file(false))
	button(saves, "Import", func(): show_file(true), true)
	button(editor, "Restore default move set", func(): model.restore_defaults(); populate_editor(); reset_round(); editor_status.text = "Defaults restored. Save locally to keep them.", true)
	editor_status = label(editor, "Provisional tuning · changes stay local", 11, ACCENT)
	editor_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label(editor, "INPUT BUFFER", 11, MUTED)
	var buffer_grid := GridContainer.new()
	buffer_grid.columns = 3
	editor.add_child(buffer_grid)
	for i in 3:
		var column := VBoxContainer.new()
		buffer_grid.add_child(column)
		label(column, ["Buttons", "Motion", "Step gap"][i], 11, MUTED)
		var spin := SpinBox.new()
		spin.min_value = [1,3,1][i]
		spin.max_value = [12,30,12][i]
		column.add_child(spin)
		buffer_fields.append(spin)
	button(editor, "Apply buffer & reset", apply_buffer, true)
	label(editor, "Strive parity is still to be measured.", 10, MUTED)
	label(root, "FIGHT GUILD / GODOT 4.6  ·  Native C++ simulation  ·  60 fixed ticks per second", 11, MUTED)
	build_dialogs()

func add_field(parent: Node, spec: Array) -> void:
	var column := VBoxContainer.new()
	parent.add_child(column)
	label(column, spec[1], 10, MUTED)
	var spin := SpinBox.new()
	spin.min_value = spec[2]
	spin.max_value = spec[3]
	spin.step = 0.01 if spec[4] == 100 else 1.0
	spin.custom_minimum_size.x = 92
	column.add_child(spin)
	fields[spec[0]] = {"control": spin, "scale": spec[4]}

func build_dialogs() -> void:
	selection_dialog = ConfirmationDialog.new()
	selection_dialog.title = "Choose your fighters"
	selection_dialog.ok_button_text = "Enter training floor"
	add_child(selection_dialog)
	var columns := HBoxContainer.new()
	columns.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	selection_dialog.add_child(columns)
	for p in 2:
		var column := VBoxContainer.new()
		column.custom_minimum_size.x = 300
		columns.add_child(column)
		label(column, "PLAYER " + str(p + 1), 16, ACCENT)
		selection_characters.append(option(column, "Fighter", CombatModel.CHARACTERS, p))
		var check := CheckBox.new()
		check.text = "Enable simplified inputs"
		column.add_child(check)
		selection_simple.append(check)
		label(column, "Motions remain available.\nModifier + → P / ↓ S / ↑ Hs\nNo damage penalty in this prototype.", 12, MUTED)
	selection_dialog.confirmed.connect(func():
		for p in 2:
			characters[p] = selection_characters[p].selected
			simple[p] = selection_simple[p].button_pressed
		reset_round())
	file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.json ; Fight Guild move data"])
	file_dialog.size = Vector2i(800, 560)
	add_child(file_dialog)
	file_dialog.file_selected.connect(func(path: String):
		var error := model.load_file(path) if importing else model.save_file(path)
		editor_status.text = error if not error.is_empty() else "Move set imported." if importing else "Move set exported."
		if importing and error.is_empty(): populate_editor(); reset_round())

func show_controls() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Know your buttons"
	dialog.dialog_text = "Player 1: WASD move; J K L I O = P K S Hs D\nSpace dash; Shift simple modifier\n\nPlayer 2: arrows move; numpad 1 2 3 5 6 attacks\nNumpad 0 dash; numpad + modifier\n\nGamepad: bottom / left / top / right / RB = P K S Hs D\nD-pad or left stick moves; LB dash; LT modifier\n\nHold away to block. 6 + button: command normal.\nSpecials: 236P, 236S, 623Hs; directions follow facing.\nClick the arena after editing to return to gameplay.\nOnline: each client uses Player 1 controls."
	add_child(dialog)
	dialog.popup_centered(Vector2i(580, 420))
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)

func show_file(load_mode: bool) -> void:
	if load_mode and connection.active: return
	importing = load_mode
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE if importing else FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.current_file = "fight-guild-moves.json"
	file_dialog.popup_centered()

func populate_editor() -> void:
	var definition := model.move(edit_character.selected, edit_move.selected)
	editor_title.text = CombatModel.MOVE_IDS[edit_move.selected] + " / " + ["NORMAL", "COMMAND", "SPECIAL", "DRIVE"][definition.category]
	for key in fields:
		var control: Control = fields[key].control
		if control is CheckBox: control.button_pressed = bool(definition[key])
		else: control.value = float(definition[key]) / fields[key].scale
	var destinations: Array[String] = []
	for to in CombatModel.MOVE_IDS.size():
		if model.core.can_cancel(edit_character.selected, edit_move.selected, to, true): destinations.append(CombatModel.MOVE_IDS[to])
	routes.text = "On contact → " + ", ".join(destinations) + (" / jump" if definition.jumpCancel else "")
	var data := model.data()
	for i in 3: buffer_fields[i].value = data.inputRules[CombatModel.RULES[i]]

func apply_move() -> void:
	if connection.active: return
	var data := model.data()
	var definition: Dictionary = data.characters[edit_character.selected].moves[edit_move.selected]
	for key in fields:
		var control: Control = fields[key].control
		definition[key] = int(control.button_pressed) if control is CheckBox else roundi(control.value * fields[key].scale)
	var error := model.load_data(data)
	if not error.is_empty(): editor_status.text = error; return
	populate_editor()
	reset_round()
	editor_status.text = "Applied. Save locally or export to keep this set."

func apply_buffer() -> void:
	if connection.active: return
	var data := model.data()
	for i in 3: data.inputRules[CombatModel.RULES[i]] = int(buffer_fields[i].value)
	var error := model.load_data(data)
	if error.is_empty(): reset_round()
	editor_status.text = "Input settings applied." if error.is_empty() else error

func release_focus_from_ui() -> void:
	var focus := get_viewport().gui_get_focus_owner()
	if focus != null: focus.release_focus()

func is_editing() -> bool:
	return get_viewport().gui_get_focus_owner() != null or has_open_dialog()

func has_open_dialog() -> bool:
	for child in get_children():
		if child is Window and child.visible: return true
	return false

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var code: int = event.physical_keycode if event.physical_keycode else event.keycode
		if not event.pressed: held.erase(code)
		elif not is_editing() and not event.echo: held[code] = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: held.clear()

func read_input(player: int) -> int:
	if is_editing(): return 0
	var raw := 0
	for key in held: raw |= KEY_MAPS[player].get(key, 0)
	var pads := Input.get_connected_joypads()
	if player >= pads.size(): return raw
	var pad := pads[player]
	if Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_LEFT) or Input.get_joy_axis(pad, JOY_AXIS_LEFT_X) < -0.35: raw |= 1
	if Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_RIGHT) or Input.get_joy_axis(pad, JOY_AXIS_LEFT_X) > 0.35: raw |= 2
	if Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_DOWN) or Input.get_joy_axis(pad, JOY_AXIS_LEFT_Y) > 0.35: raw |= 4
	if Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_UP) or Input.get_joy_axis(pad, JOY_AXIS_LEFT_Y) < -0.35: raw |= 8
	var buttons := [JOY_BUTTON_A, JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_B, JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_LEFT_SHOULDER]
	for b in buttons.size():
		if Input.is_joy_button_pressed(pad, buttons[b]): raw |= 16 << b
	if Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_LEFT) > 0.5: raw |= 1024
	return raw

func reset_round() -> void:
	if connection.active: return
	model.reset(characters, simple)
	held.clear()
	history.clear()
	last_raw = 0
	paused = false
	pause_button.text = "Pause"
	release_focus_from_ui()

func advance_one() -> void:
	if connection.active: return
	release_focus_from_ui()
	paused = true
	pause_button.text = "Resume"
	simulate_local()

func simulate_local() -> void:
	var a := read_input(0)
	var b := read_input(1)
	if mode.selected == 0:
		var state := model.state()
		var away := 2 if state.players[1].x > state.players[0].x else 1
		b = [0, away, away | 4, RollbackSession.scripted_input(model.frame(), 1)][dummy.selected]
	model.step(a, b)
	record_input(a)

func record_input(raw: int) -> void:
	if raw != 0 and raw != last_raw:
		var facing := model.core.read_value(connection.player if connection.active else 0, 2)
		var x := (int(bool(raw & 2)) - int(bool(raw & 1))) * facing
		var y := int(bool(raw & 8)) - int(bool(raw & 4))
		var notation: String = ["", "↙", "↓", "↘", "←", "·", "→", "↖", "↑", "↗"][5 + x + y * 3]
		for b in 5:
			if raw & (16 << b): notation += CombatModel.BUTTONS[b]
		if raw & 512: notation += " Dash"
		if raw & 1024: notation += " *"
		history.append(notation)
		if history.size() > 8: history.pop_front()
	last_raw = raw

func _physics_process(_delta: float) -> void:
	if connection.active:
		var raw := read_input(0)
		connection.tick(raw)
		record_input(raw)
	elif not paused and not has_open_dialog():
		simulate_local()

func _process(_delta: float) -> void:
	var state := model.state()
	arena.refresh(model, state, show_boxes, paused)
	input_label.text = "INPUT HISTORY   " + ("   ".join(history) if not history.is_empty() else "—")
	var fighter: Dictionary = state.players[connection.player if connection.active else 0]
	action_label.text = "READY" if fighter.lastMove < 0 else CombatModel.MOVE_IDS[fighter.lastMove] + (" / CONTACT" if fighter.contact else "")

func run_trial() -> void:
	var result := RollbackSession.trial(model.data())
	trial_status.text = "PASS · %d corrections · %08x" % [result.rollbacks, result.hash] if result.get("pass", false) else "FAIL: " + str(result)

func start_network(host: bool) -> void:
	if connection.active: return
	var result := connection.begin(model, host, address.text.strip_edges(), int(port.value), characters[0], simple[0])
	if result != OK: net_status.text = "Could not open connection: " + error_string(result); return
	lock_online(true)
	paused = false
	held.clear()

func lock_online(locked: bool) -> void:
	for control in locked_buttons: control.disabled = locked
	for field in fields.values():
		if field.control is SpinBox: field.control.editable = not locked
		else: field.control.disabled = locked
	for spin in buffer_fields: spin.editable = not locked
	mode.disabled = locked
	dummy.disabled = locked or mode.selected == 1
	leave_button.disabled = not locked
	address.editable = not locked
	port.editable = not locked
