class_name GameMenus
extends Control

signal action_requested(action: String)

const DISPLAY_FONT = preload("res://assets/fonts/DejaVuSansCondensed-BoldOblique.ttf")
const GOLD := Color("f4b45e")
const MUTED := Color("a3adb4")
var pages := {}
var buttons := {}
var current_page := "home"
var breadcrumb: Label
var back_button: Button
var selection_title: Label
var selection_note: Label
var selection_cards: Array[Control] = []
var selection_roles: Array[Label] = []
var fighters: Array[OptionButton] = []
var simplified: Array[CheckBox] = []
var portraits: Array[FighterPreview] = []
var address: LineEdit
var port: SpinBox
var status: Label
var online_fighter: Label
var pause_note: Label
var result_title: Label
var result_note: Label

func _ready() -> void:
	# Godot's built-in UI actions only supply keyboard events in this project.
	# Use all devices so either player's controller can navigate the front end.
	for binding in [["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B], ["ui_up", JOY_BUTTON_DPAD_UP], ["ui_down", JOY_BUTTON_DPAD_DOWN], ["ui_left", JOY_BUTTON_DPAD_LEFT], ["ui_right", JOY_BUTTON_DPAD_RIGHT]]:
		var event := InputEventJoypadButton.new()
		event.device = -1
		event.button_index = binding[1]
		if not InputMap.action_has_event(binding[0], event): InputMap.action_add_event(binding[0], event)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right"]: margin.add_theme_constant_override("margin_" + edge, 56)
	for edge in ["top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 26)
	add_child(margin)
	var root := column(margin)
	var header := line(root)
	var brand := text(header, "FG   FIGHT GUILD", 23, GOLD)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	breadcrumb = text(header, "MAIN MENU", 12, MUTED)
	back_button = action(header, "back", "← Back", 44)
	var body := Control.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	for id in ["home", "matches", "fighters", "online", "pause", "results"]:
		var scroll := ScrollContainer.new()
		scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		body.add_child(scroll)
		var page := column(scroll)
		page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page.size_flags_vertical = Control.SIZE_EXPAND_FILL
		pages[id] = scroll
		match id:
			"home": build_home(page)
			"matches": build_matches(page)
			"fighters": build_fighters(page)
			"online": build_online(page)
			"pause": build_pause(page)
			"results": build_results(page)
	var footer := line(root)
	var hint := text(footer, "↑ ↓ / D-pad  Navigate     Enter / A  Select     Esc / B  Back", 12, MUTED)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text(footer, "PLAYABLE PROTOTYPE  /  004", 11, GOLD)
	show_page("home")

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("10191f"))
	draw_colored_polygon(PackedVector2Array([Vector2(size.x * 0.60, 0), Vector2(size.x, 0), size, Vector2(size.x * 0.36, size.y)]), Color("19272e"))
	draw_line(Vector2(size.x * 0.60, 0), Vector2(size.x * 0.36, size.y), Color("33444a"), 2)
	draw_line(Vector2(56, 90), Vector2(size.x - 56, 90), Color("39444d"))

func column(parent: Node) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override("separation", 16)
	parent.add_child(node)
	return node

func line(parent: Node) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation", 24)
	parent.add_child(node)
	return node

func text(parent: Node, value: String, font_size: int = 16, color: Color = Color("f0ede5")) -> Label:
	var node := Label.new()
	node.text = value
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	parent.add_child(node)
	return node

func heading(parent: Node, value: String, subtitle: String) -> Label:
	var title := text(parent, value, 44)
	title.add_theme_font_override("font", DISPLAY_FONT)
	var note := text(parent, subtitle, 16, MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return title

func action(parent: Node, id: String, value: String, height: int = 70) -> Button:
	var node := Button.new()
	node.text = value
	node.alignment = HORIZONTAL_ALIGNMENT_LEFT
	node.custom_minimum_size.y = height
	node.add_theme_font_size_override("font_size", 20 if height > 44 else 14)
	node.pressed.connect(func(): action_requested.emit(id))
	parent.add_child(node)
	buttons[id] = node
	return node

func spacer(parent: Node) -> void:
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	space.custom_minimum_size.y = 16
	parent.add_child(space)

func build_home(page: VBoxContainer) -> void:
	spacer(page)
	var split := line(page)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var choices := column(split)
	choices.custom_minimum_size.x = 520
	text(choices, "STEP INTO THE GUILD", 13, GOLD)
	heading(choices, "Find the fight.", "Six fighters. Five buttons. Your next route starts here.")
	action(choices, "matches", "01   Matches\n        Local versus or online", 96)
	action(choices, "training", "02   Training\n        Practice routes, defense and timing", 96)
	action(choices, "development", "03   Development\n        Edit moves and explore the combat lab", 96)
	var utilities := line(choices)
	action(utilities, "controls", "Controls", 44)
	action(utilities, "quit", "Quit game", 44)
	var art := column(split)
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pair := line(art)
	pair.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for p in 2:
		var preview := FighterPreview.new()
		preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		preview.custom_minimum_size = Vector2(180, 330)
		pair.add_child(preview)
		preview.present(p, "active", 0, 1 if p == 0 else -1)
	var caption := text(art, "ANVIL  /  HAMMER", 14, GOLD)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text(art, "A roster in the making. A fight you can shape.", 14, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spacer(page)

func build_matches(page: VBoxContainer) -> void:
	spacer(page)
	heading(page, "Pick your match.", "Choose how to play, then choose your fighter.")
	action(page, "local", "Local versus\nTwo players on this computer", 100)
	action(page, "online", "Online versus\nHost or join a direct connection", 100)
	text(page, "Online currently uses a host address and UDP port. Matchmaking is planned.", 14, MUTED)
	spacer(page)

func build_fighters(page: VBoxContainer) -> void:
	selection_title = heading(page, "Choose your fighters.", "Motions are always available. Simplified inputs are optional for each fighter.")
	var pair := line(page)
	pair.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for p in 2:
		var shell := PanelContainer.new()
		shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pair.add_child(shell)
		selection_cards.append(shell)
		var card := column(shell)
		selection_roles.append(text(card, "PLAYER " + str(p + 1), 14, GOLD))
		var picker := OptionButton.new()
		picker.custom_minimum_size.y = 46
		picker.add_theme_font_size_override("font_size", 22)
		for fighter in CombatModel.CHARACTERS: picker.add_item(fighter)
		card.add_child(picker)
		fighters.append(picker)
		var portrait := FighterPreview.new()
		portrait.custom_minimum_size = Vector2(280, 260)
		portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.add_child(portrait)
		portraits.append(portrait)
		picker.item_selected.connect(func(index: int): portrait.present(index, "active", 0, 1 if p == 0 else -1))
		var check := CheckBox.new()
		check.text = "Enable simplified inputs"
		card.add_child(check)
		simplified.append(check)
		text(card, "Modifier + → P / ↓ S / ↑ Hs\nDirections follow your fighter's facing.", 13, MUTED)
	selection_note = text(page, "", 14, MUTED)
	action(page, "confirm_fighters", "Start match")

func build_online(page: VBoxContainer) -> void:
	spacer(page)
	heading(page, "Connect to a rival.", "Both players need the same build and move data. Each uses Player 1 controls locally.")
	online_fighter = text(page, "", 24, GOLD)
	var form := line(page)
	var host_column := column(form)
	host_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text(host_column, "HOST ADDRESS  ·  needed when joining", 12, MUTED)
	address = LineEdit.new()
	address.text = "127.0.0.1"
	address.placeholder_text = "Host IP or hostname"
	address.custom_minimum_size.y = 46
	host_column.add_child(address)
	var port_column := column(form)
	text(port_column, "UDP PORT", 12, MUTED)
	port = SpinBox.new()
	port.min_value = 1024
	port.max_value = 65535
	port.value = 7000
	port.custom_minimum_size = Vector2(160, 46)
	port_column.add_child(port)
	var actions := line(page)
	for id in ["host", "join", "cancel_connection"]:
		action(actions, id, {"host":"Host match", "join":"Join match", "cancel_connection":"Cancel connection"}[id])
	status = text(page, "Choose Host or Join to begin.", 18, GOLD)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text(page, "127.0.0.1 connects two instances on this computer.\nFor another computer, use the host's address and allow the chosen UDP port.", 14, MUTED)
	spacer(page)

func build_pause(page: VBoxContainer) -> void:
	spacer(page)
	heading(page, "Take a breath.", "Return to the fight when you're ready.")
	pause_note = text(page, "", 16, GOLD)
	action(page, "resume", "Resume")
	action(page, "restart", "Restart round")
	action(page, "change_fighters", "Change fighters")
	action(page, "pause_home", "Main menu")
	spacer(page)

func build_results(page: VBoxContainer) -> void:
	spacer(page)
	result_title = heading(page, "Round complete.", "Run it back, try another fighter, or return to the main menu.")
	result_note = text(page, "", 20, GOLD)
	action(page, "rematch", "Rematch")
	action(page, "results_fighters", "Change fighters")
	action(page, "return_lobby", "Return to online lobby")
	action(page, "results_home", "Main menu")
	spacer(page)

func configure_selection(activity: String, chosen: Array, simple: Array) -> void:
	var online := activity == "online"
	var practice := activity in ["training", "development"]
	selection_title.text = {"local":"Local versus", "online":"Choose your fighter.", "training":"Set up your practice.", "development":"Enter the combat lab."}[activity]
	selection_cards[1].visible = not online
	for p in 2:
		selection_roles[p].text = "LOCAL PLAYER" if online else "TRAINING DUMMY" if practice and p == 1 else "PLAYER " + str(p + 1)
		fighters[p].select(chosen[p])
		simplified[p].button_pressed = simple[p]
		portraits[p].present(chosen[p], "active", 0, 1 if p == 0 else -1)
	selection_note.text = "Your opponent chooses their fighter on their own computer." if online else "Dummy behavior and starting Momentum can be changed during practice." if practice else "Share a keyboard or connect two controllers. Open Controls for the full layout."
	buttons.confirm_fighters.text = {"local":"Start match", "online":"Continue to connection", "training":"Start training", "development":"Open combat lab"}[activity]

func configure_pause(online: bool) -> void:
	pause_note.text = "Online match continues while this menu is open." if online else "The round is paused."
	buttons.restart.visible = not online
	buttons.change_fighters.visible = not online
	buttons.pause_home.text = "Leave match & main menu" if online else "Main menu"

func configure_results(state: Dictionary, online: bool) -> void:
	result_title.text = "Draw." if state.winner == 2 else CombatModel.CHARACTERS[state.players[state.winner].character] + " wins."
	result_note.text = "Return to the lobby to host or join another match." if online else "Choose your next round."
	buttons.rematch.visible = not online
	buttons.results_fighters.visible = not online
	buttons.return_lobby.visible = online

func set_connecting(connecting: bool) -> void:
	buttons.host.disabled = connecting
	buttons.join.disabled = connecting
	buttons.cancel_connection.disabled = not connecting
	address.editable = not connecting
	port.editable = not connecting

func show_page(page: String) -> void:
	current_page = page
	for id in pages: pages[id].visible = id == page
	back_button.visible = page not in ["home", "results"]
	breadcrumb.text = {"home":"MAIN MENU", "matches":"MATCHES", "fighters":"FIGHTER SELECT", "online":"ONLINE / CONNECTION", "pause":"MATCH MENU", "results":"RESULT"}[page]
	call_deferred("focus_page", page)

func focus_page(page: String) -> void:
	if not is_visible_in_tree() or current_page != page: return
	match page:
		"home": buttons.matches.grab_focus()
		"matches": buttons.local.grab_focus()
		"fighters": fighters[0].grab_focus()
		"online": (buttons.cancel_connection if buttons.host.disabled else buttons.host).grab_focus()
		"pause": buttons.resume.grab_focus()
		"results": (buttons.rematch if buttons.rematch.visible else buttons.return_lobby).grab_focus()
