extends AcceptDialog

var controls: FighterInputs
var accent := Color("d67570")
var tabs: Array[Button] = []
var bindings: VBoxContainer
var headings := ["Player 1", "Player 2", "Guide"]
var selected := 0
var listening := ""
var listening_action := -1
var testing := false
var status_label: Label
var live_label: Label
var test_button: Button
var reset_button: Button
var binding_buttons := {}

func _ready() -> void:
	title = "Fight Guild · Controls"
	theme = InkMenu.theme(accent)
	ok_button_text = "Close"
	dialog_close_on_escape = false
	get_ok_button().hide()
	var layout := VBoxContainer.new()
	add_child(layout)
	var heading := label(layout, "MAKE IT YOURS", 30, InkMenu.PAPER)
	heading.add_theme_font_override("font", InkMenu.FONT)
	label(layout, "Controls save on this computer. Esc / Start always opens the match menu.", 18, InkMenu.MUTED)
	var navigation := HBoxContainer.new()
	layout.add_child(navigation)
	var group := ButtonGroup.new()
	for i in headings.size():
		var tab := Button.new()
		tab.text = headings[i]
		tab.theme_type_variation = "SettingsTab"
		tab.toggle_mode = true
		tab.button_group = group
		tab.custom_minimum_size.y = 40
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.pressed.connect(func(): show_bindings(i))
		navigation.add_child(tab)
		tabs.append(tab)
	var scroll := ScrollContainer.new()
	scroll.name = "ControlsBody"
	scroll.custom_minimum_size = Vector2(760, 310)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	layout.add_child(scroll)
	bindings = VBoxContainer.new()
	bindings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bindings.add_theme_constant_override("separation", 10)
	scroll.add_child(bindings)
	status_label = label(layout, "", 17, accent)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Give the wrapping label a width before popup minimum-size measurement.
	# A zero-width first layout can otherwise grow AcceptDialog past the screen.
	status_label.custom_minimum_size = Vector2(760, 44)
	status_label.size.x = 760
	var footer := HBoxContainer.new()
	layout.add_child(footer)
	reset_button = make_button(footer, "Reset this player", func():
		controls.reset_player(selected)
		show_bindings(selected)
		status_label.text = "Defaults restored. Keys used by the other player stay unbound." if controls.status.is_empty() else controls.status)
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(space)
	var close := make_button(footer, "Close", func(): confirmed.emit())
	close.name = "CloseAction"
	controls.devices_changed.connect(func():
		if selected < 2 and listening.is_empty() and not testing: show_bindings(selected))
	show_bindings(0)
	visibility_changed.connect(func(): if visible: tabs[0].grab_focus.call_deferred())

func label(parent: Node, value: String, font_size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = value
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	parent.add_child(result)
	return result

func make_button(parent: Node, value: String, callback: Callable) -> Button:
	var result := Button.new()
	result.text = value
	result.custom_minimum_size.y = 40
	result.pressed.connect(callback)
	parent.add_child(result)
	return result

func set_status() -> void:
	status_label.text = controls.status if not controls.status.is_empty() else "Select a binding to change it. Esc cancels; Backspace clears. Duplicate bindings swap within a player."

func show_bindings(scheme: int) -> void:
	selected = scheme
	listening = ""
	testing = false
	binding_buttons.clear()
	live_label = null
	tabs[scheme].set_pressed_no_signal(true)
	reset_button.visible = scheme < 2
	for child in bindings.get_children():
		bindings.remove_child(child)
		child.queue_free()
	label(bindings, headings[scheme].to_upper() + " / " + ("BINDINGS" if scheme < 2 else "MOTIONS & DEFENSE"), 18, accent)
	set_status()
	if scheme == 2:
		var note := label(bindings, "Numpad notation faces right: 5 neutral, 2 down, 4 back, 6 forward; mirror left/right when facing left. j. means airborne.\n\nTraditional motions work in both control modes. Enable simple controls at fighter select, then hold Simple plus the move's direction and button. Development shows each move's current mapping.\n\n66 or Dash begins forward movement. Hold forward or Dash to run; 4 + Dash goes backward. Air dashes depend on the character.\n\n2S is a hard-knockdown sweep. 4P+K / 6P+K throws; + means simultaneous. Hold away to block; hold down-away against lows.\n\nAway + Faultless Defense spends Momentum to prevent chip and add pushback. Away + two of P/K/S/Hs also works, except grounded 4P+K (back throw). Guard break removes backdash and blockstun grab protection.\n\nCombined controller mode prioritizes digital directions over the left stick. Opposite directions neutralize. Stick and trigger values must cross their threshold to activate, then fall below 80% of it to release.\n\nA disconnected controller never transfers the other player's controls. Reconnect it, or assign a replacement here. Identical controllers can require manual assignment after restarting.\n\nOnline uses Player 1 controls on each computer. Menus keep their own arrows / D-pad, Enter / A, Esc / B navigation. Test inputs captures these buttons until Esc / Start. Release controls after closing settings before returning to combat.", 19, InkMenu.MUTED)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		return
	var profile: Dictionary = controls.profiles[scheme]
	var sources := HBoxContainer.new()
	bindings.add_child(sources)
	var keyboard := CheckBox.new()
	keyboard.text = "Keyboard enabled"
	keyboard.button_pressed = profile.keyboard
	keyboard.custom_minimum_size.y = 40
	sources.add_child(keyboard)
	keyboard.toggled.connect(func(value: bool): controls.set_option(selected, "keyboard", value); set_status())
	var device := OptionButton.new()
	device.name = "ControllerAssignment"
	device.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	device.custom_minimum_size.y = 40
	device.add_item("Automatic controller")
	device.set_item_metadata(0, -2)
	device.add_item("No controller")
	device.set_item_metadata(1, -1)
	device.select(0 if profile.device == "auto" else 1)
	for item in controls.devices:
		device.add_item("%s · #%d%s" % [item.name, int(item.id) + 1, " (other player)" if controls.assigned[1-selected] == item.id else ""])
		device.set_item_metadata(device.item_count - 1, int(item.id))
		if controls.assigned[selected] == item.id and profile.device != "auto": device.select(device.item_count - 1)
	if controls.assigned[selected] < 0 and profile.device not in ["auto", "none"]:
		device.add_item("Disconnected · reconnect saved controller")
		device.set_item_metadata(device.item_count - 1, -3)
		device.set_item_disabled(device.item_count - 1, true)
		device.select(device.item_count - 1)
	sources.add_child(device)
	device.item_selected.connect(func(index: int): controls.assign_device(selected, int(device.get_item_metadata(index))); set_status())
	var tuning := HBoxContainer.new()
	bindings.add_child(tuning)
	for field in ["deadzone", "trigger"]:
		var column := VBoxContainer.new()
		tuning.add_child(column)
		label(column, "Stick deadzone" if field == "deadzone" else "Trigger threshold", 17, InkMenu.MUTED)
		var spinner := SpinBox.new()
		spinner.name = "StickDeadzone" if field == "deadzone" else "TriggerThreshold"
		spinner.min_value = 10
		spinner.max_value = 90
		spinner.step = 1
		spinner.suffix = "%"
		spinner.value = profile[field] * 100
		spinner.custom_minimum_size = Vector2(160, 40)
		column.add_child(spinner)
		spinner.value_changed.connect(func(value: float): controls.set_option(selected, field, value / 100.0); set_status())
	var input_mode := VBoxContainer.new()
	tuning.add_child(input_mode)
	input_mode.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label(input_mode, "Controller directions", 17, InkMenu.MUTED)
	var direction := OptionButton.new()
	for item in ["D-pad + stick", "D-pad only", "Stick only"]: direction.add_item(item)
	direction.select(int(profile.stick_mode))
	direction.custom_minimum_size.y = 40
	input_mode.add_child(direction)
	direction.item_selected.connect(func(index: int): controls.set_option(selected, "stick_mode", index); set_status())
	var live := HBoxContainer.new()
	bindings.add_child(live)
	live_label = label(live, "5", 19, InkMenu.PAPER)
	live_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	live_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	test_button = make_button(live, "Test inputs", func():
		testing = not testing
		test_button.text = "Stop testing" if testing else "Test inputs"
		status_label.text = "Press your controls. Esc / Start ends the test; no combat runs here." if testing else "Test ended."
		if testing: get_viewport().gui_release_focus())
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 6)
	bindings.add_child(grid)
	for title_text in ["ACTION", "KEYBOARD", "CONTROLLER"]: label(grid, title_text, 17, accent)
	for action in [4, 5, 6, 7, 8, 9, 10, 11, 0, 1, 2, 3]:
		var caption := label(grid, FighterInputs.ACTIONS[action], 20, InkMenu.PAPER)
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for kind in ["keys", "pad"]:
			var binding := make_button(grid, FighterInputs.binding_name(kind, int(profile[kind][action])), func(): begin_binding(kind, action))
			binding.custom_minimum_size.x = 240
			binding.accessibility_name = "%s %s binding" % [FighterInputs.ACTIONS[action], "keyboard" if kind == "keys" else "controller"]
			binding_buttons["%s%d" % [kind, action]] = binding

func begin_binding(kind: String, action: int) -> void:
	testing = false
	if kind == "pad" and controls.assigned[selected] < 0:
		status_label.text = "Assign a connected controller above first."
		return
	listening = kind
	listening_action = action
	status_label.text = "Press %s for %s. Esc cancels; Backspace clears." % ["a physical key" if kind == "keys" else "a button or trigger on the assigned controller", FighterInputs.ACTIONS[action]]

func capture(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var code: int = event.physical_keycode if event.physical_keycode else event.keycode
		if code == KEY_ESCAPE:
			listening = ""
			set_status()
			return
		if code == KEY_BACKSPACE: finish_binding(-1)
		elif listening == "keys": finish_binding(code)
	elif listening == "pad" and event.device == controls.assigned[selected]:
		if event is InputEventJoypadButton and event.pressed: finish_binding(event.button_index)
		elif event is InputEventJoypadMotion and event.axis in [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT] and event.axis_value > maxf(0.65, controls.profiles[selected].trigger):
			finish_binding(100 if event.axis == JOY_AXIS_TRIGGER_LEFT else 101)

func finish_binding(code: int) -> void:
	var error := controls.bind(selected, listening, listening_action, code)
	if not error.is_empty():
		status_label.text = error
		return
	var focus_key := "%s%d" % [listening, listening_action]
	show_bindings(selected)
	focus_binding.call_deferred(focus_key)

func focus_binding(key_name: String) -> void:
	if visible and binding_buttons.has(key_name) and binding_buttons[key_name].is_inside_tree(): binding_buttons[key_name].grab_focus()

func _input(event: InputEvent) -> void:
	if not visible: return
	if not listening.is_empty():
		capture(event)
		get_viewport().set_input_as_handled()
	elif testing:
		if (event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE)) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START):
			testing = false
			test_button.text = "Test inputs"
			test_button.grab_focus()
			set_status()
		if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion: get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		canceled.emit()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not visible or not is_instance_valid(live_label): return
	var raw := controls.sample(selected, controls.physical_keys())
	var id: int = controls.assigned[selected]
	var axis := Vector2(Input.get_joy_axis(id, JOY_AXIS_LEFT_X), Input.get_joy_axis(id, JOY_AXIS_LEFT_Y)) if id >= 0 else Vector2.ZERO
	live_label.text = "%s\n%s · stick %.2f, %.2f" % [FighterInputs.notation(raw), controls.device_name(selected), axis.x, axis.y]
