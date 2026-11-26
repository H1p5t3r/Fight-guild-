class_name GameMenus
extends Control

signal action_requested(action: String)

const DISPLAY_FONT = CombatTypography.FONT
const GOLD := InkMenu.PAPER
const MUTED := InkMenu.MUTED
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
var sides: SideSelect
var address: LineEdit
var port: SpinBox
var status: Label
var online_fighter: Label
var pause_note: Label
var pause_commands: PauseCommands
var result_title: Label
var result_note: Label
var palette := MenuPalette.new()
var backdrop: Control
# A single camera travels between fixed menu locations. The shared ink backdrop
# follows at a slower depth; pages no longer disappear behind screen-covering wipes.
const LOCATIONS := {"home": Vector2(0, 0), "matches": Vector2(1, 0), "sides": Vector2(2, 0), "fighters": Vector2(2, 1), "online": Vector2(3, 1), "pause": Vector2(0, 1), "results": Vector2(1, 1)}
var camera := Vector2.ZERO:
	set(value):
		camera = value
		position_pages()
		if is_instance_valid(backdrop): backdrop.travel = value
var camera_tween: Tween
var page_extent := Vector2(1280, 720)
var pause_mix := 0.0:
	set(value):
		pause_mix = value
		if is_instance_valid(backdrop): backdrop.modulate.a = 1.0 - value
var home_poster: MenuFighterPoster
var versus_poster: MenuFighterPoster
var pause_character := 5
var pause_opponent := 4
var result_poster: MenuFighterPoster
var online_poster: MenuFighterPoster
var featured_caption: Label
var featured := 5

func _ready() -> void:
	for binding in [["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B], ["ui_up", JOY_BUTTON_DPAD_UP], ["ui_down", JOY_BUTTON_DPAD_DOWN], ["ui_left", JOY_BUTTON_DPAD_LEFT], ["ui_right", JOY_BUTTON_DPAD_RIGHT]]:
		var event := InputEventJoypadButton.new()
		event.device = -1
		event.button_index = binding[1]
		if not InputMap.action_has_event(binding[0], event): InputMap.action_add_event(binding[0], event)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = InkMenu.theme(palette.accent)
	palette.changed.connect(func(): theme = InkMenu.theme(palette.accent))
	backdrop = preload("res://scripts/guild_backdrop.gd").new()
	backdrop.palette = palette
	backdrop.motion = motion
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right"]: margin.add_theme_constant_override("margin_" + edge, 40)
	for edge in ["top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 24)
	add_child(margin)
	var root := Control.new()
	margin.add_child(root)
	header = line(root)
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_bottom = 40
	var brand := text(header, "FIGHT GUILD", 28, GOLD)
	brand.add_theme_font_override("font", DISPLAY_FONT)
	brand.add_theme_color_override("font_outline_color", InkMenu.INK)
	brand.add_theme_constant_override("outline_size", 4)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	breadcrumb = text(header, "MAIN MENU", 17, MUTED)
	breadcrumb.add_theme_color_override("font_outline_color", InkMenu.INK)
	breadcrumb.add_theme_constant_override("outline_size", 5)
	back_button = action(header, "back", "Back", 38, "secondary")
	var body := Control.new()
	root.add_child(body)
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_bottom = -50
	# The viewport is the boundary: entering strips can cross the page margins.
	body.clip_contents = false
	body.resized.connect(layout_pages)
	for id in ["home", "matches", "sides", "fighters", "online", "pause", "results"]:
		var page := column(body)
		page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		page.offset_top = 0 if id == "home" else 64
		page.visible = false
		pages[id] = page
		page.minimum_size_changed.connect(func(): layout_pages.call_deferred())
		match id:
			"home": build_home(page)
			"matches": build_matches(page)
			"sides":
				heading(page, "TAKE YOUR SIDE.", "LOCAL VERSUS  /  Move your device left or right, then choose your fighter.")
				sides = SideSelect.new()
				sides.motion = motion
				sides.palette = palette
				page.add_child(sides)
				sides.confirmed.connect(func(): action_requested.emit("confirm_sides"))
				buttons.confirm_sides = sides.continue_button
			"fighters": build_fighters(page)
			"online": build_online(page)
			"pause": build_pause(page)
			"results": build_results(page)
	var footer := line(root)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -40
	home_utilities = line(footer)
	action(home_utilities, "controls", "Controls", 40, "secondary")
	action(home_utilities, "sound", "Sound", 40, "secondary")
	var hint := text(footer, "D-pad / Arrows  MOVE     A / Enter  SELECT     B / Esc  BACK", 16, MUTED)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action(home_utilities, "quit", "Quit", 40, "secondary")
	var motion_button := action(home_utilities, "motion", "", 40, "secondary")
	motion_button.tooltip_text = "Reduce motion: short fades; no camera travel, sliding portraits or animated idles."
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
	var title := text(parent, value, 46, GOLD)
	title.add_theme_font_override("font", DISPLAY_FONT)
	title.add_theme_color_override("font_outline_color", InkMenu.INK)
	title.add_theme_constant_override("outline_size", 8)
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
	var node := InkMenuButton.new()
	node.motion = motion
	node.palette = palette
	node.compact = height < 48
	node.add_theme_font_size_override("font_size", 18 if node.compact else 32)
	node.text = value
	node.custom_minimum_size.y = height
	node.set_meta("family", family)
	node.pressed.connect(func(): action_requested.emit(id))
	parent.add_child(node)
	buttons[id] = node
	return node

func spacer(parent: Node) -> void:
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(space)

func poster(parent: Node) -> MenuFighterPoster:
	var art := MenuFighterPoster.new()
	art.palette = palette
	art.motion = motion
	parent.add_child(art)
	return art

func set_featured(index: int) -> void:
	featured = index
	palette.set_fighter(index)
	home_poster.present(index)
	versus_poster.present(index)
	featured_caption.text = FighterSelectPortrait.GUILDS[index] + "  /  " + FighterSelectPortrait.LINES[index]

func build_home(page: VBoxContainer) -> void:
	var body := scroll_body(page)
	var split := line(body)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 24)
	var choices := column(split)
	choices.custom_minimum_size.x = 430
	choices.add_theme_constant_override("separation", 4)
	spacer(choices)
	text(choices, "THE GUILDS ARE CALLING.", 18, MUTED)
	var title := text(choices, "FIGHT\nGUILD", 96)
	title.add_theme_font_override("font", DISPLAY_FONT)
	title.add_theme_constant_override("line_spacing", -28)
	title.rotation = -0.045
	for entry in [["matches", "VERSUS", 66], ["combo_trials", "COMBO TRIALS", 58], ["training", "TRAINING", 58], ["development", "COMBAT LAB", 54]]:
		var button := action(choices, entry[0], entry[1], entry[2]) as InkMenuButton
		button.serial = "0" + str(["matches", "combo_trials", "training", "development"].find(entry[0]) + 1)
		button.add_theme_font_size_override("font_size", 42 if entry[0] == "matches" else 34)
	var description := text(choices, "Local and online matches.", 19, MUTED)
	description.custom_minimum_size.y = 40
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for id in ["matches", "combo_trials", "training", "development"]:
		var explain := func(): description.text = {"matches":"Local and online matches.", "combo_trials":"Follow the rhythm. Land the whole combo.", "training":"Find the route. Practice combos and defense.", "development":"Tune moves, hitboxes and combat rules."}[id]
		buttons[id].focus_entered.connect(explain)
		buttons[id].mouse_entered.connect(explain)
	spacer(choices)
	var artwork := column(split)
	artwork.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	artwork.add_theme_constant_override("separation", 2)
	home_poster = poster(artwork)
	featured_caption = text(artwork, "BUTCHERS  /  CUT DEEP.", 20, InkMenu.INK)
	featured_caption.add_theme_font_override("font", GuildTheme.SEMIBOLD)
	var guilds := line(artwork)
	for index in CombatModel.CHARACTERS.size():
		var choose := InkMenuButton.new()
		choose.motion = motion
		choose.palette = palette
		choose.compact = true
		choose.text = CombatModel.CHARACTERS[index]
		choose.tooltip_text = "Feature " + FighterSelectPortrait.GUILDS[index].capitalize()
		choose.accessibility_name = choose.tooltip_text
		choose.custom_minimum_size.y = 36
		choose.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choose.add_theme_font_size_override("font_size", 15)
		choose.pressed.connect(func(): set_featured(index))
		guilds.add_child(choose)

func build_matches(page: VBoxContainer) -> void:
	heading(page, "PICK A FIGHT.", "VERSUS  /  One room or one connection away.")
	var body := scroll_body(page)
	var split := line(body)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var choices := column(split)
	choices.custom_minimum_size.x = 440
	spacer(choices)
	action(choices, "local", "LOCAL VERSUS", 76).add_theme_font_size_override("font_size", 38)
	text(choices, "Two players. One screen.\nShare a keyboard or bring your controllers.", 22, MUTED)
	var gap := Control.new()
	gap.custom_minimum_size.y = 20
	choices.add_child(gap)
	action(choices, "online", "ONLINE VERSUS", 76).add_theme_font_size_override("font_size", 36)
	text(choices, "Choose your fighter. Host or join a match.", 22, MUTED)
	text(choices, "Both players need the same build and move data.", 18, MUTED)
	spacer(choices)
	versus_poster = poster(split)
	# Both axes work, preserving pad habits from the previous horizontal menu.
	buttons.local.focus_neighbor_right = buttons.local.get_path_to(buttons.online)
	buttons.online.focus_neighbor_left = buttons.online.get_path_to(buttons.local)

func build_fighters(page: VBoxContainer) -> void:
	selection = FighterSelect.new()
	selection.motion = motion
	selection.palette = palette
	selection.matchup_changed.connect(Callable(backdrop, "set_matchup"))
	page.add_child(selection)
	selection.confirmed.connect(func(): action_requested.emit("confirm_fighters"))
	buttons.confirm_fighters = selection.start_button

func build_online(page: VBoxContainer) -> void:
	heading(page, "ONLINE / CONNECTION", "Both players choose a fighter locally and use Player 1 controls on their own computer.")
	var body := scroll_body(page)
	var split := line(body)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var form := section(split, "YOUR MATCH")
	form.custom_minimum_size.x = 620
	form.get_parent().size_flags_vertical = Control.SIZE_SHRINK_BEGIN
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
	online_poster = poster(split)
	status = text(page, "Choose Host or Join to begin.", 20, GOLD)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func build_pause(page: VBoxContainer) -> void:
	pause_commands = PauseCommands.new()
	pause_commands.motion = motion
	page.add_child(pause_commands)
	pause_commands.action_requested.connect(func(action_id: String): action_requested.emit(action_id))
	for id in pause_commands.buttons: buttons[id] = pause_commands.buttons[id]
	pause_note = pause_commands.note

func build_results(page: VBoxContainer) -> void:
	result_title = heading(page, "MATCH COMPLETE", "THE FINAL WHISTLE  /  First to two Scrums.")
	var body := scroll_body(page)
	var split := line(body)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var actions := column(split)
	actions.custom_minimum_size.x = 460
	result_note = text(actions, "", 22, GOLD)
	result_note.custom_minimum_size.x = 460
	result_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	spacer(actions)
	action(actions, "rematch", "RUN IT BACK", 72).add_theme_font_size_override("font_size", 38)
	action(actions, "results_fighters", "Change fighters", 60)
	action(actions, "return_lobby", "Return to online lobby", 60)
	action(actions, "results_home", "Main menu", 54, "secondary")
	spacer(actions)
	result_poster = poster(split)

func configure_selection(activity: String, chosen: Array) -> void:
	selection.configure(activity, chosen)

func configure_pause(online: bool, state: Dictionary = {}) -> void:
	if not state.is_empty():
		var fighter: int = state.players[0].character
		palette.set_fighter(fighter)
		pause_character = fighter
		pause_opponent = int(state.players[1].character)
	pause_note.text = "Online match continues while this menu is open." if online else "The round is paused."
	buttons.restart.visible = not online
	buttons.change_fighters.visible = not online
	buttons.pause_home.text = "MAIN MENU"
	buttons.pause_home.subtitle = "Leave the online match" if online else "Leave the arena"
	buttons.pause_home.accessibility_name = "Main menu. " + buttons.pause_home.subtitle
	pause_commands.configure([pause_character, pause_opponent])

func configure_results(state: Dictionary, online: bool, round_label: String = "", score: Array = [0, 0]) -> void:
	var winner: int = int(state.winner) if state.winner in [0, 1] else 0
	var fighter: int = state.players[winner].character
	palette.set_fighter(fighter)
	result_poster.present(fighter)

	result_title.text = "Draw." if state.winner == 2 else CombatModel.CHARACTERS[state.players[state.winner].character] + " wins."
	result_note.text = "%d–%d · %s · MATCH COMPLETE · " % [score[0], score[1], round_label] + ("Return to the lobby to host or join another match." if online else "Run it back or choose new fighters.")
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
	page_extent = size
	for id in pages:
		var node: Control = pages[id]
		node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		node.offset_top = 0 if id == "home" else 64
	position_pages()

func position_pages() -> void:
	for id in pages:
		var displacement: Vector2 = (LOCATIONS[id] - camera) * page_extent
		pages[id].position = Vector2(0, 0 if id == "home" else 64) + (Vector2.ZERO if motion.reduced else displacement)

func update_motion_label() -> void:
	buttons.motion.text = "Motion: Reduced" if motion.reduced else "Motion: Full"

func set_active(enabled: bool) -> void:
	active = enabled
	sides.active = enabled and current_page == "sides"
	MenuMotion.interactive(self, enabled)
	for id in pages: MenuMotion.interactive(pages[id], enabled and id == current_page)
	MenuMotion.interactive(header, enabled and current_page != "home")
	MenuMotion.interactive(home_utilities, enabled and current_page == "home")

func show_page(page: String, fresh: bool = false) -> void:
	current_page = page
	backdrop.set_page(page, fresh)
	if page in ["home", "matches"]: palette.set_fighter(featured)
	if page == "pause":
		palette.set_fighter(pause_character)
		pause_commands.enter()
	if page == "results": palette.set_fighter(result_poster.character)
	if page == "fighters": palette.set_fighter(selection.chosen[selection.active_player])
	if page == "online":
		palette.set_fighter(selection.chosen[0])
		online_poster.present(selection.chosen[0])
	back_button.visible = page not in ["home", "results"]
	breadcrumb.text = {"home":"MAIN MENU", "matches":"VERSUS", "sides":"SIDE SELECT", "fighters":"FIGHTER SELECT", "online":"ONLINE / CONNECTION", "pause":"MATCH MENU", "results":"RESULT"}[page]
	if camera_tween: camera_tween.kill()
	for tween in page_tweens.values(): tween.kill()
	page_tweens.clear()
	for id in pages:
		MenuMotion.interactive(pages[id], active and id == page)
		if id == page: pages[id].visible = true
	if fresh or motion.instant:
		camera = LOCATIONS[page]
		for id in pages: settle_page(id)
	elif motion.reduced:
		camera = LOCATIONS[page]
		for id in pages:
			var node: Control = pages[id]
			if not node.visible: continue
			if id == page: node.modulate.a = 0.0
			var tween := create_tween()
			page_tweens[id] = tween
			tween.tween_property(node, "modulate:a", 1.0 if id == page else 0.0, motion.duration(0.28))
			tween.tween_callback(settle_page.bind(id))
	else:
		# Pages share one translation. Reversing midway starts at the current camera,
		# so the same panels and landmarks retrace their path without snapping/fading.
		for id in pages: pages[id].modulate.a = 1.0
		position_pages()
		camera_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		page_tweens.camera = camera_tween
		var distance := camera.distance_to(LOCATIONS[page])
		camera_tween.tween_property(self, "camera", LOCATIONS[page], motion.duration(clampf(0.34 + distance * 0.035, 0.34, 0.44)))
		camera_tween.tween_callback(func():
			for id in pages: settle_page(id))
	if chrome_tween: chrome_tween.kill()
	if fresh or motion.instant:
		header.modulate.a = 0.0 if page == "home" else 1.0
		home_utilities.modulate.a = 1.0 if page == "home" else 0.0
		pause_mix = 1.0 if page == "pause" else 0.0
	else:
		chrome_tween = create_tween().set_parallel(true)
		chrome_tween.tween_property(header, "modulate:a", 0.0 if page == "home" else 1.0, motion.duration(0.18))
		chrome_tween.tween_property(home_utilities, "modulate:a", 1.0 if page == "home" else 0.0, motion.duration(0.18))
		chrome_tween.tween_property(self, "pause_mix", 1.0 if page == "pause" else 0.0, motion.duration(0.30))
	set_active(active)
	call_deferred("focus_page", page)

func settle_page(id: String) -> void:
	pages[id].visible = id == current_page
	pages[id].modulate.a = 1.0
	position_pages()

func is_animating() -> bool:
	for tween in page_tweens.values():
		if tween.is_running(): return true
	return (chrome_tween != null and chrome_tween.is_running()) or selection.is_animating() or backdrop.is_animating() or pause_commands.is_animating()

func finish_motion() -> void:
	pause_commands.finish()
	backdrop.finish_motion()
	selection.finish_motion()
	for tween in page_tweens.values(): tween.kill()
	if camera_tween: camera_tween.kill()
	camera = LOCATIONS[current_page]
	for id in pages: settle_page(id)
	if chrome_tween: chrome_tween.kill()
	pause_mix = 1.0 if current_page == "pause" else 0.0
	header.modulate.a = 0.0 if current_page == "home" else 1.0
	home_utilities.modulate.a = 1.0 if current_page == "home" else 0.0

func focus_page(page: String) -> void:
	if not active or not is_visible_in_tree() or current_page != page: return
	match page:
		"home": buttons.matches.grab_focus()
		"matches": buttons.local.grab_focus()
		"sides": sides.continue_button.grab_focus()
		"fighters": selection.focus_selection()
		"online": (buttons.cancel_connection if buttons.host.disabled else buttons.host).grab_focus()
		"pause": buttons.resume.grab_focus()
		"results": (buttons.rematch if buttons.rematch.visible else buttons.return_lobby).grab_focus()
