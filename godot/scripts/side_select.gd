class_name SideSelect
extends VBoxContainer

signal confirmed
var controls: FighterInputs
var motion := MenuMotion.new()
var active := false
var owners := {}
var lanes: Array[VBoxContainer] = []
var cards := {}
var continue_button: Button
var instruction: Label
var axis_latches := {}
var tweens: Array[Tween] = []

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 16)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 18)
	add_child(columns)
	for lane in [0, -1, 1]:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.size_flags_stretch_ratio = 1.0 if lane != -1 else 0.84
		var style := StyleBoxFlat.new()
		style.bg_color = Color("15252d") if lane != -1 else Color("10191f")
		style.border_color = accent(lane)
		style.set_border_width_all(1)
		style.border_width_top = 5 if lane != -1 else 1
		style.content_margin_left = 18
		style.content_margin_right = 18
		style.content_margin_top = 12
		style.content_margin_bottom = 12
		panel.add_theme_stylebox_override("panel", style)
		columns.add_child(panel)
		var body := VBoxContainer.new()
		body.add_theme_constant_override("separation", 6)
		panel.add_child(body)
		var title := text(body, "1P" if lane == 0 else "2P" if lane == 1 else "VS", 56, accent(lane))
		title.add_theme_font_override("font", GuildTheme.SEMIBOLD)
		text(body, "LEFT SIDE" if lane == 0 else "RIGHT SIDE" if lane == 1 else "UNASSIGNED", 18, GuildTheme.MUTED)
		body.add_child(HSeparator.new())
		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.follow_focus = true
		body.add_child(scroll)
		var list := VBoxContainer.new()
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_theme_constant_override("separation", 12)
		scroll.add_child(list)
		lanes.append(list)
	instruction = text(self, "Move your controller left or right to choose a side.", 19, GuildTheme.IVORY)
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	continue_button = Button.new()
	continue_button.text = "CHOOSE FIGHTERS  →"
	continue_button.custom_minimum_size.y = 52
	continue_button.add_theme_font_size_override("font_size", 24)
	GuildTheme.apply(continue_button, "essential")
	continue_button.pressed.connect(func(): if ready_to_continue(): confirmed.emit())
	add_child(continue_button)

static func accent(lane: int) -> Color:
	return GuildTheme.BRASS if lane == 0 else Color("66c5c3") if lane == 1 else GuildTheme.MUTED

func text(parent: Node, value: String, font_size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = value
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(result)
	return result

func configure(service: FighterInputs) -> void:
	controls = service
	owners.clear()
	axis_latches.clear()
	for p in 2: owners["key%d" % p] = p if controls.profiles[p].keyboard else -1
	for device in controls.devices:
		owners["pad%d" % device.id] = controls.assigned.find(int(device.id))
	if not controls.devices_changed.is_connected(refresh_devices): controls.devices_changed.connect(refresh_devices)
	render()

func refresh_devices() -> void:
	if not active: return
	var present := ["key0", "key1"]
	for device in controls.devices:
		var source := "pad%d" % device.id
		present.append(source)
		if not owners.has(source): owners[source] = -1
	for source in owners.keys():
		if source not in present: owners.erase(source)
	render()

func ready_to_continue() -> bool:
	return 0 in owners.values() and 1 in owners.values()

func source_name(source: String) -> String:
	if source.begins_with("key"):
		var p := int(source.substr(3))
		return "KEYBOARD %d\n%s  /  %s" % [p + 1, FighterInputs.binding_name("keys", int(controls.profiles[p].keys[0])), FighterInputs.binding_name("keys", int(controls.profiles[p].keys[1]))]
	var id := int(source.substr(3))
	for device in controls.devices:
		if device.id == id: return "CONTROLLER %d\n%s" % [id + 1, device.name]
	return "Disconnected"

func move_source(source: String, destination: int) -> void:
	if not owners.has(source) or destination not in [-1, 0, 1]: return
	var previous := int(owners[source])
	if previous == destination: return
	# A side has at most one keyboard layout and one controller.
	if destination >= 0:
		for other in owners:
			if other != source and owners[other] == destination and other.left(3) == source.left(3): owners[other] = -1
	owners[source] = destination
	render()
	if cards.has(source):
		var card: Control = cards[source]
		if not motion.instant:
			card.modulate.a = 0.35
			var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(card, "modulate:a", 1.0, motion.duration(0.16))
			tweens.append(tween)

func nudge(source: String, direction: int) -> void:
	if not owners.has(source): return
	var positions := [0, -1, 1]
	var index := positions.find(int(owners[source]))
	move_source(source, positions[clampi(index + direction, 0, 2)])

func render() -> void:
	for tween in tweens: if tween.is_running(): tween.kill()
	tweens.clear()
	cards.clear()
	for lane in lanes:
		for child in lane.get_children():
			lane.remove_child(child)
			child.queue_free()
	for source in owners:
		var owner := int(owners[source])
		var lane: VBoxContainer = lanes[[0, -1, 1].find(owner)]
		var panel := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color("21323b")
		style.border_color = Color(accent(owner), 0.65)
		style.set_border_width_all(1)
		style.set_content_margin_all(6)
		panel.add_theme_stylebox_override("panel", style)
		lane.add_child(panel)
		cards[source] = panel
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 4)
		panel.add_child(content)
		var name_label := text(content, source_name(source), 17, GuildTheme.IVORY)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var buttons := HBoxContainer.new()
		content.add_child(buttons)
		for destination in [0, -1, 1]:
			var button := Button.new()
			button.text = "1P" if destination == 0 else "—" if destination == -1 else "2P"
			button.custom_minimum_size.y = 36
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.disabled = destination == owner
			button.accessibility_name = source_name(source).replace("\n", " ") + (" unassign" if destination < 0 else " to Player %d" % (destination + 1))
			GuildTheme.apply(button, "secondary")
			buttons.add_child(button)
			button.pressed.connect(func():
				move_source(source, destination)
				continue_button.grab_focus.call_deferred())
	for i in 3:
		if lanes[i].get_child_count() == 0:
			text(lanes[i], "MOVE HERE TO JOIN" if i != 1 else "Connect a controller\nor move a device here.", 18, GuildTheme.MUTED)
	continue_button.disabled = not ready_to_continue()
	instruction.text = "Choose a side with left / right. Enter or Start continues. Cards also work with the mouse." if ready_to_continue() else "Assign an input to each side to continue. Left / right moves your own device."

func apply() -> bool:
	if not ready_to_continue(): return false
	var keyboards := [-1, -1]
	var pads := [-1, -1]
	for source in owners:
		var player := int(owners[source])
		if player < 0: continue
		if source.begins_with("key"): keyboards[player] = int(source.substr(3))
		else: pads[player] = int(source.substr(3))
	controls.assign_sides(keyboards, pads)
	configure(controls)
	return true

func handle_input(event: InputEvent) -> bool:
	if not active: return false
	if event is InputEventKey and event.pressed and not event.echo:
		var code: int = event.physical_keycode if event.physical_keycode else event.keycode
		if code == KEY_ENTER:
			if ready_to_continue(): confirmed.emit()
			return true
		for p in 2:
			if code == controls.profiles[p].keys[0]: nudge("key%d" % p, -1); return true
			if code == controls.profiles[p].keys[1]: nudge("key%d" % p, 1); return true
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_START:
			if ready_to_continue(): confirmed.emit()
			return true
		if event.button_index in [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]:
			nudge("pad%d" % event.device, -1 if event.button_index == JOY_BUTTON_DPAD_LEFT else 1)
			return true
	elif event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_X:
		var side := int(signf(event.axis_value)) if absf(event.axis_value) > 0.6 else 0
		if absf(event.axis_value) < 0.3: axis_latches[event.device] = 0
		if side != 0 and int(axis_latches.get(event.device, 0)) != side:
			axis_latches[event.device] = side
			nudge("pad%d" % event.device, side)
		return true
	return false
