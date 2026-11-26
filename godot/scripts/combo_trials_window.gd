class_name ComboTrialsWindow
extends Window

signal finished
const Arena = preload("res://scripts/arena.gd")
const SAVE := "user://combo-trials.cfg"
var session := ComboTrialSession.new()
var controls: FighterInputs
var arena: Control
var highway: ComboTrialHighway
var combat_audio := CombatAudio.new()
var super_freeze := SuperFreeze.new()
var fighter_picker: OptionButton
var route_picker: OptionButton
var side_picker: OptionButton
var speed_picker: OptionButton
var watch_button: Button
var try_button: Button
var pause_button: Button
var title_label: Label
var hint_label: Label
var result_label: Label
var detail_label: Label
var route_row: HBoxContainer
var bindings_label: Label
var root_ui: Control
var route_ids: Array[int] = []
var step_labels: Array[Label] = []
var held := {}
var paused := false
var focused := true
var release_required := false
var accumulator := 0.0
var speed := 1.0
var input_raw := 0
var clear_saved := false
var progress := ConfigFile.new()
var error := ""
var reduced_motion := false
var pause_reason := ""
var initial_character := 5

func _ready() -> void:
	visible = false
	title = "Fight Guild · Combo Trials"
	borderless = true
	unresizable = true
	transient = true
	exclusive = true
	content_scale_size = Vector2i(1280, 720)
	content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	close_requested.connect(close)
	focus_exited.connect(func(): if visible: set_paused(true); focused = false; held.clear())
	focus_entered.connect(func(): focused = true; release_required = true)
	if controls != null: controls.controller_lost.connect(controller_lost)
	add_child(combat_audio)
	if not OS.get_cmdline_user_args().has("--test"): progress.load(SAVE)
	error = session.load_catalog()
	build_interface()
	if error.is_empty(): choose_fighter(initial_character)
	else:
		result_label.text = "TRIALS NEED AN UPDATE"
		detail_label.text = error
		watch_button.disabled = true
		try_button.disabled = true

func open() -> void:
	var bounds := get_parent().get_viewport().get_visible_rect()
	popup(Rect2i(Vector2i.ZERO, Vector2i(bounds.size)))
	try_button.grab_focus()
	refresh()

func close() -> void:
	combat_audio.silence()
	held.clear()
	hide()
	finished.emit()
	queue_free()

func controller_lost(player: int) -> void:
	if player == 0 and visible:
		set_paused(true)
		pause_reason = "Controller disconnected. Reconnect, then Resume."

func text(parent: Node, value: String, font_size: int, color: Color = InkMenu.PAPER) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func button(parent: Node, value: String, action: Callable) -> Button:
	var result := Button.new()
	result.text = value
	result.custom_minimum_size.y = 42
	result.pressed.connect(action)
	parent.add_child(result)
	return result

func picker(parent: Node, values: Array, width: float, name_text: String) -> OptionButton:
	var result := OptionButton.new()
	for value in values: result.add_item(str(value))
	result.custom_minimum_size = Vector2(width, 42)
	result.accessibility_name = name_text
	result.tooltip_text = name_text
	parent.add_child(result)
	return result

func build_interface() -> void:
	root_ui = Control.new()
	root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.theme = InkMenu.theme(Color("bd2443"))
	add_child(root_ui)
	root_ui.draw.connect(draw_background)
	var top := HBoxContainer.new()
	top.position = Vector2(20, 15)
	top.size = Vector2(1240, 46)
	top.add_theme_constant_override("separation", 8)
	root_ui.add_child(top)
	fighter_picker = picker(top, CombatModel.CHARACTERS, 144, "Trial fighter")
	fighter_picker.item_selected.connect(choose_fighter)
	route_picker = picker(top, [], 330, "Combo route")
	route_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	route_picker.item_selected.connect(func(_index): choose_route())
	side_picker = picker(top, ["Face right →", "← Face left"], 160, "Practice side")
	side_picker.item_selected.connect(func(_index): choose_route())
	speed_picker = picker(top, ["100% speed", "75% speed", "50% speed"], 150, "Practice speed")
	speed_picker.item_selected.connect(func(index): speed = [1.0, 0.75, 0.5][index]; choose_route())
	button(top, "BACK · Esc", close)
	title_label = text(root_ui, "FIND YOUR RHYTHM", 36)
	title_label.position = Vector2(26, 77)
	title_label.add_theme_font_override("font", CombatTypography.FONT)
	title_label.rotation = -0.025
	hint_label = text(root_ui, "", 15, InkMenu.MUTED)
	hint_label.position = Vector2(26, 122)
	hint_label.size = Vector2(838, 42)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	arena = Arena.new()
	root_ui.add_child(arena)
	arena.position = Vector2(20, 155)
	arena.custom_minimum_size = Vector2(0, 0)
	arena.size = Vector2(852, 350)
	arena.diagnostics = false
	arena.feedback.reduced_motion = reduced_motion
	arena.round_label = "COMBO TRIAL"
	arena.add_child(super_freeze)
	highway = ComboTrialHighway.new()
	highway.position = Vector2(894, 80)
	highway.size = Vector2(366, 620)
	highway.session = session
	root_ui.add_child(highway)
	result_label = text(root_ui, "", 27)
	result_label.position = Vector2(28, 550)
	result_label.add_theme_font_override("font", CombatTypography.FONT)
	detail_label = text(root_ui, "", 14, InkMenu.MUTED)
	detail_label.position = Vector2(28, 582)
	detail_label.size = Vector2(838, 36)
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	route_row = HBoxContainer.new()
	route_row.position = Vector2(26, 510)
	route_row.size = Vector2(838, 30)
	route_row.add_theme_constant_override("separation", 7)
	root_ui.add_child(route_row)
	var commands := HBoxContainer.new()
	commands.position = Vector2(20, 621)
	commands.size = Vector2(852, 42)
	commands.add_theme_constant_override("separation", 12)
	root_ui.add_child(commands)
	watch_button = button(commands, "WATCH · F2", func(): begin(true))
	try_button = button(commands, "TRY / RETRY · F3", func(): begin(false))
	pause_button = button(commands, "PAUSE · F4", toggle_pause)
	bindings_label = text(root_ui, "", 14, InkMenu.MUTED)
	bindings_label.position = Vector2(26, 674)
	bindings_label.size = Vector2(846, 35)
	bindings_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func draw_background() -> void:
	var accent: Color = FighterSelectPortrait.COLORS[fighter_picker.selected]
	root_ui.draw_rect(Rect2(0, 0, 1280, 720), InkMenu.INK)
	root_ui.draw_colored_polygon(PackedVector2Array([Vector2(0, 66), Vector2(879, 66), Vector2(859, 116), Vector2(0, 150)]), accent.darkened(0.35))
	root_ui.draw_colored_polygon(PackedVector2Array([Vector2(877, 0), Vector2(890, 0), Vector2(875, 720), Vector2(862, 720)]), accent)
	root_ui.draw_rect(Rect2(20, 510, 852, 32), Color(InkMenu.INK, 0.92))

func choose_fighter(index: int) -> void:
	if not error.is_empty(): return
	fighter_picker.select(index)
	route_picker.clear()
	route_ids.clear()
	for i in session.catalog.trials.size():
		var item: Dictionary = session.catalog.trials[i]
		if int(item.character) != index: continue
		route_ids.append(i)
		route_picker.add_item(str(item.title).capitalize())
	route_picker.select(0)
	choose_route()

func choose_route() -> void:
	if route_ids.is_empty(): return
	session.select(session.catalog.trials[route_ids[route_picker.selected]], side_picker.selected == 1)
	set_paused(false)
	accumulator = 0
	held.clear()
	input_raw = 0
	release_required = true
	combat_audio.silence()
	title_label.text = CombatModel.CHARACTERS[int(session.trial.character)].to_upper() + " / COMBO TRIALS"
	hint_label.text = str(session.trial.hint)
	for child in route_row.get_children(): route_row.remove_child(child); child.queue_free()
	step_labels.clear()
	for i in session.trial.steps.size():
		if i > 0: text(route_row, "›", 20, InkMenu.MUTED)
		step_labels.append(text(route_row, str(session.trial.steps[i].notation), 21))
	highway.accent = FighterSelectPortrait.COLORS[int(session.trial.character)]
	root_ui.theme = InkMenu.theme(highway.accent)
	root_ui.queue_redraw()
	refresh()

func begin(demo: bool) -> void:
	if not error.is_empty(): return
	set_paused(false)
	session.begin(demo)
	accumulator = 0
	clear_saved = false
	release_required = true
	input_raw = 0
	var owner := gui_get_focus_owner()
	if owner: owner.release_focus()
	refresh()

func set_paused(value: bool) -> void:
	paused = value
	pause_reason = ""
	release_required = true
	accumulator = 0
	if is_instance_valid(pause_button): pause_button.text = "RESUME · F4" if paused else "PAUSE · F4"
	if paused: combat_audio.silence()

func toggle_pause() -> void:
	set_paused(not paused)
	var owner := gui_get_focus_owner()
	if owner: owner.release_focus()
	if paused: pause_button.grab_focus()
	refresh()

func _input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventKey:
		var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if not event.pressed: held.erase(code)
		elif not event.echo:
			if code == KEY_ESCAPE: set_input_as_handled(); close(); return
			if code == KEY_F2: set_input_as_handled(); begin(true); return
			if code == KEY_F3: set_input_as_handled(); begin(false); return
			if code == KEY_F4: set_input_as_handled(); toggle_pause(); return
			held[code] = true
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
		if controls != null and event.device == controls.assigned[0]:
			set_input_as_handled()
			if session.running(): toggle_pause()
			else: begin(false)
	if session.running() and not paused:
		# Gameplay buttons and directions must not navigate focused menu controls.
		if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion: set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and visible:
		focused = false
		held.clear()
		set_paused(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		focused = true
		release_required = true

func _physics_process(_delta: float) -> void:
	if not visible or not error.is_empty(): return
	input_raw = controls.sample(0, held) if controls != null and focused else 0
	if release_required:
		if input_raw == 0: release_required = false
		else: refresh(); return
	if paused or not focused: refresh(); return
	accumulator += speed
	if accumulator >= 1:
		accumulator -= 1
		tick(input_raw)
	refresh()

func tick(raw: int) -> void:
	var was_running := session.running()
	session.advance(raw)
	if was_running and not session.running(): try_button.grab_focus()
	combat_audio.consume(session.model, session.model.frame() - 1, not paused and focused)
	if session.state == "success" and not session.demonstration and not clear_saved:
		clear_saved = true
		if speed == 1.0 and not OS.get_cmdline_user_args().has("--test"):
			progress.set_value(str(session.catalog.fingerprint), progress_key(), true)
			progress.save(SAVE)

func progress_key() -> String:
	return str(session.trial.id) + ("-left" if session.mirrored else "-right")

func refresh() -> void:
	if session.trial.is_empty(): return
	var live := session.model.state()
	arena.refresh(session.model, live, false, paused)
	if int(live.superFreezeTime) > 0:
		var actor: Dictionary = live.players[int(live.superFreezeActor)]
		super_freeze.present(int(actor.character), int(actor.facing), int(live.superFreezeDuration) - int(live.superFreezeTime), int(live.superFreezeDuration))
	else: super_freeze.clear()
	highway.raw = session.inputs[session.clock - 1] if session.demonstration and session.clock > 0 and session.clock <= session.inputs.size() else input_raw
	highway.queue_redraw()
	for i in step_labels.size():
		step_labels[i].modulate = highway.accent.lightened(0.35) if i == session.completed_step else InkMenu.PAPER if i < session.completed_step else Color("8e8594")
	result_label.text = session.feedback
	if session.state == "countdown":
		result_label.text = ("WATCH" if session.demonstration else "READY") + "   /   " + str(maxi(1, ceili(float(-session.clock) / 30.0)))
	elif session.state == "play" and session.clock > session.feedback_until:
		result_label.text = "WATCH THE TIMING" if session.demonstration else "KEEP IT GOING"
	var status := "%d / %d HITS  ·  %d DAMAGE  ·  %d%% SPEED" % [session.hits, int(session.trial.hits), session.damage, roundi(speed * 100)]
	if session.state == "ready":
		status = "%d hits / %d damage · %s · Default fighter kits" % [int(session.trial.hits), int(session.trial.damage), "Corner" if session.trial.corner else "Midscreen"]
		if progress.get_value(str(session.catalog.fingerprint), progress_key(), false): status += " · CLEARED"
	elif session.state == "failed": status = session.failure
	elif session.state == "success":
		status += " · " + ("Your turn: F3 / Start" if session.demonstration else "Practice clear" if speed < 1.0 else "Full-speed clear")
	if paused:
		result_label.text = "PAUSED"
		status = pause_reason if not pause_reason.is_empty() else "F4 / Start to resume. Release held inputs first."
	detail_label.text = status
	result_label.modulate = Color("ffb0b4") if session.state == "failed" else InkMenu.PAPER
	bindings_label.text = (controls.keyboard_hint(0) if controls != null else "") + "\nStart: pause / retry · Move labels are facing-relative. DIR shows screen directions."
	for picker_control in [fighter_picker, route_picker, side_picker, speed_picker]:
		picker_control.disabled = session.running() and not paused
