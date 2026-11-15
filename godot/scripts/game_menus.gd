class_name GameMenus
extends Control

signal action_requested(action: String)

const DISPLAY_FONT = GuildTheme.SEMIBOLD
const GOLD := GuildTheme.BRASS
const MUTED := GuildTheme.MUTED
var pages := {}
var buttons := {}
var current_page := "home"
var motion := MenuMotion.new()
var page_tweens := {}
var chrome_tween: Tween
var active := true
var header: HBoxContainer
var breadcrumb: Label
var back_button: Button
var home_utilities: HBoxContainer
var selection: FighterSelect
var simplified: Array[CheckBox] = []
var address: LineEdit
var port: SpinBox
var status: Label
var online_fighter: Label
var pause_note: Label
var result_title: Label
var result_note: Label

func _ready() -> void:
	for binding in [["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B], ["ui_up", JOY_BUTTON_DPAD_UP], ["ui_down", JOY_BUTTON_DPAD_DOWN], ["ui_left", JOY_BUTTON_DPAD_LEFT], ["ui_right", JOY_BUTTON_DPAD_RIGHT]]:
		var event := InputEventJoypadButton.new()
		event.device = -1
		event.button_index = binding[1]
		if not InputMap.action_has_event(binding[0], event): InputMap.action_add_event(binding[0], event)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(preload("res://scripts/guild_backdrop.gd").new())
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right"]: margin.add_theme_constant_override("margin_" + edge, 36)
	for edge in ["top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 24)
	add_child(margin)
	var root := Control.new()
	margin.add_child(root)
	header = line(root)
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_bottom = 40
	var brand := text(header, "FIGHT GUILD", 28, GOLD)
	brand.add_theme_font_override("font", DISPLAY_FONT)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	breadcrumb = text(header, "MAIN MENU", 17, MUTED)
	back_button = action(header, "back", "Back", 38, "secondary")
	var body := Control.new()
	root.add_child(body)
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_bottom = -60
	body.resized.connect(layout_pages)
	for id in ["home", "matches", "fighters", "online", "pause", "results"]:
		var page := column(body)
		page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		page.offset_top = 0 if id == "home" else 64
		page.visible = false
		pages[id] = page
		page.minimum_size_changed.connect(func(): layout_pages.call_deferred())
		match id:
			"home": build_home(page)
			"matches": build_matches(page)
			"fighters": build_fighters(page)
			"online": build_online(page)
			"pause": build_pause(page)
			"results": build_results(page)
	var footer := line(root)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -40
	home_utilities = line(footer)
	action(home_utilities, "controls", "Controls", 40, "secondary")
	var hint := text(footer, "Arrows / D-pad: navigate   ·   Enter / A: select   ·   Esc / B: back", 17, MUTED)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action(home_utilities, "quit", "Quit", 40, "secondary")
	var motion_button := action(home_utilities, "motion", "", 40, "secondary")
	motion_button.tooltip_text = "Reduce menu motion: short fades, no sliding portraits or pages."
	update_motion_label()
	text(footer, "EARLY BUILD", 16, GOLD)
	show_page("home", true)
	layout_pages.call_deferred()

func column(parent: Node) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override("separation", 12)
	parent.add_child(node)
	return node

func line(parent: Node) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation", 8)
	parent.add_child(node)
	return node

func text(parent: Node, value: String, font_size: int = 20, color: Color = GuildTheme.IVORY) -> Label:
	var node := Label.new()
	node.text = value
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	parent.add_child(node)
	return node

func heading(parent: Node, value: String, subtitle: String) -> Label:
	var title := text(parent, value, 30, GOLD)
	title.add_theme_font_override("font", DISPLAY_FONT)
	var note := text(parent, subtitle, 18, MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return title

func scroll_body(page: Node) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = "BodyScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	page.add_child(scroll)
	var content := column(scroll)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return content

func section(parent: Node, title: String = "") -> VBoxContainer:
	var shell := PanelContainer.new()
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(shell)
	var content := column(shell)
	content.add_theme_constant_override("separation", 8)
	if not title.is_empty(): text(content, title, 18, GOLD)
	return content

func action(parent: Node, id: String, value: String, height: int = 38, family: String = "primary") -> Button:
	var node := Button.new()
	node.text = value
	node.custom_minimum_size.y = height
	GuildTheme.apply(node, family)
	node.pressed.connect(func(): action_requested.emit(id))
	parent.add_child(node)
	buttons[id] = node
	return node

func spacer(parent: Node) -> void:
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(space)

func build_home(page: VBoxContainer) -> void:
	var body := scroll_body(page)
	var split := line(body)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 24)
	var choices := column(split)
	choices.custom_minimum_size.x = 320
	spacer(choices)
	text(choices, "MAIN MENU", 18, GOLD)
	var title := text(choices, "FIGHT\nGUILD", 88)
	title.add_theme_font_override("font", DISPLAY_FONT)
	title.add_theme_constant_override("line_spacing", -22)
	text(choices, "Choose your fighter.", 20, MUTED)
	var versus := action(choices, "matches", "VERSUS", 64, "essential")
	versus.add_theme_font_size_override("font_size", 32)
	var training := action(choices, "training", "TRAINING", 52)
	training.add_theme_font_size_override("font_size", 26)
	action(choices, "development", "DEVELOPMENT", 42, "secondary")
	var description := text(choices, "Local and online matches.", 18, MUTED)
	description.custom_minimum_size.y = 44
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for id in ["matches", "training", "development"]:
		var explain := func(): description.text = {"matches":"Local and online matches.", "training":"Practice combos, defense and timing.", "development":"Edit moves and test the combat lab."}[id]
		buttons[id].focus_entered.connect(explain)
		buttons[id].mouse_entered.connect(explain)
	spacer(choices)
	var artwork := column(split)
	artwork.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var faceoff := preload("res://scripts/home_faceoff.gd").new()
	artwork.add_child(faceoff)
	var roster := text(artwork, "ANVIL   /   HAMMER   /   SMOKE   /   TAPPER   /   SHARK   /   FILLET", 17, MUTED)
	roster.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func build_matches(page: VBoxContainer) -> void:
	heading(page, "VERSUS", "Play together on one computer or connect to a rival.")
	var body := scroll_body(page)
	var groups := line(body)
	groups.add_theme_constant_override("separation", 12)
	var local := section(groups, "PLAY TOGETHER")
	text(local, "Two players. One computer.\nShare a keyboard or connect controllers.", 20, MUTED)
	action(local, "local", "Local versus")
	var online := section(groups, "PLAY ONLINE")
	text(online, "Choose your fighter, then host or join.\nUse a host address and UDP port.", 20, MUTED)
	action(online, "online", "Online versus")
	text(body, "Both players need the same build and move data for online play.", 18, MUTED)

func build_fighters(page: VBoxContainer) -> void:
	selection = FighterSelect.new()
	selection.motion = motion
	page.add_child(selection)
	selection.confirmed.connect(func(): action_requested.emit("confirm_fighters"))
	simplified = selection.simple_checks
	buttons.confirm_fighters = selection.start_button

func build_online(page: VBoxContainer) -> void:
	heading(page, "ONLINE / CONNECTION", "Both players choose a fighter locally and use Player 1 controls on their own computer.")
	var body := scroll_body(page)
	var form := section(body, "YOUR MATCH")
	online_fighter = text(form, "", 26, GOLD)
	var fields := line(form)
	var host_column := column(fields)
	host_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text(host_column, "HOST ADDRESS · needed when joining", 18, MUTED)
	address = LineEdit.new()
	address.text = "127.0.0.1"
	address.placeholder_text = "Host IP or hostname"
	address.custom_minimum_size.y = 40
	host_column.add_child(address)
	var port_column := column(fields)
	text(port_column, "UDP PORT", 18, MUTED)
	port = SpinBox.new()
	port.min_value = 1024
	port.max_value = 65535
	port.value = 7000
	port.custom_minimum_size = Vector2(160, 40)
	port_column.add_child(port)
	text(form, "127.0.0.1 connects two instances on this computer. For another computer, enter its host address.", 18, MUTED).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var actions := line(form)
	for id in ["host", "join", "cancel_connection"]:
		action(actions, id, {"host":"Host match", "join":"Join match", "cancel_connection":"Cancel connection"}[id], 40, "secondary" if id == "cancel_connection" else "primary")
	status = text(page, "Choose Host or Join to begin.", 20, GOLD)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func build_pause(page: VBoxContainer) -> void:
	heading(page, "MATCH MENU", "Return to the fight when you're ready.")
	pause_note = text(page, "", 20, GOLD)
	var body := scroll_body(page)
	var actions := section(body, "YOUR NEXT MOVE")
	actions.get_parent().size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	actions.custom_minimum_size.x = 420
	action(actions, "resume", "Resume", 40, "essential")
	action(actions, "restart", "Restart " + str(MatchCeremony.script().roundName).to_lower())
	action(actions, "change_fighters", "Change fighters")
	action(actions, "pause_home", "Main menu", 38, "secondary")

func build_results(page: VBoxContainer) -> void:
	result_title = heading(page, "ROUND COMPLETE", "Run it back, try another fighter, or return to the main menu.")
	result_note = text(page, "", 20, GOLD)
	var body := scroll_body(page)
	var actions := section(body, "NEXT ROUND")
	actions.get_parent().size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	actions.custom_minimum_size.x = 420
	action(actions, "rematch", "Rematch", 40, "essential")
	action(actions, "results_fighters", "Change fighters")
	action(actions, "return_lobby", "Return to online lobby")
	action(actions, "results_home", "Main menu", 38, "secondary")

func configure_selection(activity: String, chosen: Array, simple: Array) -> void:
	selection.configure(activity, chosen, simple)

func configure_pause(online: bool) -> void:
	pause_note.text = "Online match continues while this menu is open." if online else "The round is paused."
	buttons.restart.visible = not online
	buttons.change_fighters.visible = not online
	buttons.pause_home.text = "Leave match & main menu" if online else "Main menu"

func configure_results(state: Dictionary, online: bool, round_label: String = "") -> void:
	result_title.text = "Draw." if state.winner == 2 else CombatModel.CHARACTERS[state.players[state.winner].character] + " wins."
	result_note.text = (round_label + " COMPLETE · " if not round_label.is_empty() else "") + ("Return to the lobby to host or join another match." if online else "Run it back or choose new fighters.")
	buttons.rematch.visible = not online
	buttons.results_fighters.visible = not online
	buttons.return_lobby.visible = online

func set_connecting(connecting: bool) -> void:
	buttons.host.disabled = connecting
	buttons.join.disabled = connecting
	buttons.cancel_connection.disabled = not connecting
	address.editable = not connecting
	port.editable = not connecting

func layout_pages() -> void:
	for id in pages:
		var node: Control = pages[id]
		var slide := node.position.x
		node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		node.offset_top = 0 if id == "home" else 64
		node.position.x = slide

func update_motion_label() -> void:
	buttons.motion.text = "Motion: Reduced" if motion.reduced else "Motion: Full"

func set_active(enabled: bool) -> void:
	active = enabled
	MenuMotion.interactive(self, enabled)
	for id in pages: MenuMotion.interactive(pages[id], enabled and id == current_page)
	MenuMotion.interactive(header, enabled and current_page != "home")
	MenuMotion.interactive(home_utilities, enabled and current_page == "home")

func show_page(page: String, fresh: bool = false) -> void:
	var depth := {"home":0, "matches":1, "fighters":2, "online":3, "pause":1, "results":1}
	var direction := -1.0 if depth[page] < depth[current_page] else 1.0
	current_page = page
	back_button.visible = page not in ["home", "results"]
	breadcrumb.text = {"home":"MAIN MENU", "matches":"VERSUS", "fighters":"FIGHTER SELECT", "online":"ONLINE / CONNECTION", "pause":"MATCH MENU", "results":"RESULT"}[page]
	for id in pages:
		var node: Control = pages[id]
		if page_tweens.has(id): page_tweens[id].kill()
		var incoming: bool = id == page
		MenuMotion.interactive(node, active and incoming)
		if fresh or motion.instant:
			settle_page(id)
			continue
		if not node.visible and not incoming: continue
		if not node.visible:
			node.modulate.a = 0.0
			node.position.x = motion.distance(32.0 * direction)
		node.visible = true
		var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		page_tweens[id] = tween
		var duration := motion.duration(0.28 if incoming else 0.18)
		tween.tween_property(node, "modulate:a", 1.0 if incoming else 0.0, duration)
		tween.tween_property(node, "position:x", 0.0 if incoming else motion.distance(-24.0 * direction), duration)
		tween.chain().tween_callback(settle_page.bind(id))
	if chrome_tween: chrome_tween.kill()
	if fresh or motion.instant:
		header.modulate.a = 0.0 if page == "home" else 1.0
		home_utilities.modulate.a = 1.0 if page == "home" else 0.0
	else:
		chrome_tween = create_tween().set_parallel(true)
		chrome_tween.tween_property(header, "modulate:a", 0.0 if page == "home" else 1.0, motion.duration(0.18))
		chrome_tween.tween_property(home_utilities, "modulate:a", 1.0 if page == "home" else 0.0, motion.duration(0.18))
	set_active(active)
	call_deferred("focus_page", page)

func settle_page(id: String) -> void:
	pages[id].visible = id == current_page
	pages[id].modulate.a = 1.0
	pages[id].position.x = 0.0

func is_animating() -> bool:
	for tween in page_tweens.values():
		if tween.is_running(): return true
	return (chrome_tween != null and chrome_tween.is_running()) or selection.is_animating()

func finish_motion() -> void:
	selection.finish_motion()
	for id in pages:
		if page_tweens.has(id): page_tweens[id].kill()
		settle_page(id)
	if chrome_tween: chrome_tween.kill()
	header.modulate.a = 0.0 if current_page == "home" else 1.0
	home_utilities.modulate.a = 1.0 if current_page == "home" else 0.0

func focus_page(page: String) -> void:
	if not active or not is_visible_in_tree() or current_page != page: return
	match page:
		"home": buttons.matches.grab_focus()
		"matches": buttons.local.grab_focus()
		"fighters": selection.focus_selection()
		"online": (buttons.cancel_connection if buttons.host.disabled else buttons.host).grab_focus()
		"pause": buttons.resume.grab_focus()
		"results": (buttons.rematch if buttons.rematch.visible else buttons.return_lobby).grab_focus()
