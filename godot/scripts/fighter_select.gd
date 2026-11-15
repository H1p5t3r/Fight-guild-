class_name FighterSelect
extends VBoxContainer

signal confirmed

var motion := MenuMotion.new()
var chosen := [5, 4]
var active_player := 0
var online := false
var simple_checks: Array[CheckBox] = []
var slot_buttons: Array[Button] = []
var hero_panels: Array[VBoxContainer] = []
var portraits: Array[FighterSelectPortrait] = []
var tiles: Array[FighterRosterTile] = []
var start_button: Button
var context: Label
var instruction: Label
var roster_caption: Label
var selection_guard := false

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 8)
	var heading := HBoxContainer.new()
	add_child(heading)
	var title := label(heading, "PICK YOUR FIGHT.", 40, GuildTheme.IVORY)
	title.add_theme_font_override("font", GuildTheme.SEMIBOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	context = label(heading, "LOCAL VERSUS", 18, GuildTheme.BRASS)
	var matchup := HBoxContainer.new()
	matchup.add_theme_constant_override("separation", 24)
	matchup.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(matchup)
	var roster_column := VBoxContainer.new()
	roster_column.custom_minimum_size.x = 304
	roster_column.add_theme_constant_override("separation", 8)
	for p in 2:
		if p == 1: matchup.add_child(roster_column)
		var panel := VBoxContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_constant_override("separation", 8)
		matchup.add_child(panel)
		hero_panels.append(panel)
		var portrait := FighterSelectPortrait.new()
		portrait.player = p
		portrait.motion = motion
		panel.add_child(portrait)
		portraits.append(portrait)
		var simple := CheckBox.new()
		simple.text = "Simplified inputs"
		simple.custom_minimum_size.y = 38
		simple.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if p == 0 else Control.SIZE_SHRINK_END
		simple.tooltip_text = "Enable modifier + direction + button specials for this fighter. Motion inputs remain available."
		panel.add_child(simple)
		simple_checks.append(simple)
	spacer(roster_column)
	roster_caption = label(roster_column, "P1 / CHOOSE A FIGHTER", 17, GuildTheme.BRASS)
	roster_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var players := HBoxContainer.new()
	players.add_theme_constant_override("separation", 8)
	roster_column.add_child(players)
	for p in 2:
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(120, 38)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.pressed.connect(func(): set_active_player(p); focus_selection())
		players.add_child(slot)
		slot_buttons.append(slot)
	var roster := GridContainer.new()
	roster.columns = 2
	roster.add_theme_constant_override("h_separation", 8)
	roster.add_theme_constant_override("v_separation", 8)
	roster_column.add_child(roster)
	for index in CombatModel.CHARACTERS.size():
		var tile := FighterRosterTile.new()
		tile.character = index
		tile.motion = motion
		roster.add_child(tile)
		tiles.append(tile)
		tile.focus_entered.connect(func(): if not selection_guard: choose_fighter(active_player, index))
		tile.pressed.connect(func(): choose_fighter(active_player, index))
	spacer(roster_column)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 16)
	add_child(footer)
	instruction = label(footer, "", 17, GuildTheme.MUTED)
	instruction.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	start_button = Button.new()
	start_button.custom_minimum_size = Vector2(240, 42)
	GuildTheme.apply(start_button, "essential")
	start_button.pressed.connect(func(): confirmed.emit())
	footer.add_child(start_button)
	resized.connect(queue_redraw)
	configure("local", chosen, [false, false])

func label(parent: Node, value: String, font_size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = value
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	parent.add_child(result)
	return result

func spacer(parent: Node) -> void:
	var space := Control.new()
	space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(space)

func configure(activity: String, characters: Array, simple: Array) -> void:
	online = activity == "online"
	var practice := activity in ["training", "development"]
	context.text = {"local":"LOCAL VERSUS", "online":"ONLINE VERSUS", "training":"TRAINING", "development":"DEVELOPMENT / COMBAT LAB"}[activity]
	hero_panels[1].visible = not online
	slot_buttons[1].visible = not online
	for p in 2:
		portraits[p].role.text = "LOCAL PLAYER / 01" if online else "TRAINING DUMMY / 02" if practice and p == 1 else "PLAYER %02d" % (p + 1)
		slot_buttons[p].text = "P2 / DUMMY" if practice and p == 1 else "PLAYER " + str(p + 1)
		simple_checks[p].set_pressed_no_signal(simple[p])
		choose_fighter(p, characters[p])
	set_active_player(0)
	start_button.text = {"local":"LET'S FIGHT  →", "online":"CONTINUE  →", "training":"START TRAINING  →", "development":"OPEN COMBAT LAB  →"}[activity]

func choose_fighter(player: int, index: int) -> void:
	chosen[player] = clampi(index, 0, CombatModel.CHARACTERS.size() - 1)
	portraits[player].present(chosen[player])
	refresh_roster()
	queue_redraw()

func set_active_player(player: int) -> void:
	active_player = 0 if online else player
	for p in 2:
		GuildTheme.apply(slot_buttons[p], "primary" if p == active_player else "secondary")
		portraits[p].editing = p == active_player
		portraits[p].queue_redraw()
	roster_caption.text = "P%d / CHOOSE A FIGHTER" % (active_player + 1)
	roster_caption.add_theme_color_override("font_color", FighterSelectPortrait.PLAYER_COLORS[active_player])
	instruction.text = "Choose P1 or P2 above the roster. Motions are always available." if not online else "Your opponent chooses their fighter on their own computer."
	refresh_roster()

func refresh_roster() -> void:
	for index in tiles.size():
		var tile := tiles[index]
		tile.markers = [chosen[0] == index, not online and chosen[1] == index]
		tile.selecting = chosen[active_player] == index
		tile.player = active_player
		tile.queue_redraw()
		var neighbour := index + 1 if index % 2 == 0 else index - 1
		tile.focus_neighbor_left = tile.get_path_to(tiles[neighbour])
		tile.focus_neighbor_right = tile.get_path_to(tiles[neighbour])
		tile.focus_neighbor_top = tile.get_path_to(tiles[index - 2] if index >= 2 else slot_buttons[active_player])
		if start_button != null:
			tile.focus_neighbor_bottom = tile.get_path_to(tiles[index + 2] if index < 4 else start_button)
	if start_button == null: return
	for p in 2:
		slot_buttons[p].focus_neighbor_bottom = slot_buttons[p].get_path_to(tiles[chosen[active_player]])
		simple_checks[p].focus_neighbor_bottom = simple_checks[p].get_path_to(start_button)
	start_button.focus_neighbor_top = start_button.get_path_to(tiles[chosen[active_player]])

func focus_selection() -> void:
	selection_guard = true
	tiles[chosen[active_player]].grab_focus()
	selection_guard = false

func is_animating() -> bool:
	return portraits[0].is_animating() or portraits[1].is_animating()

func finish_motion() -> void:
	for portrait in portraits: portrait.finish_motion()

func _draw() -> void:
	if portraits.is_empty(): return
	var w := size.x
	var h := size.y
	var left: Color = FighterSelectPortrait.COLORS[chosen[0]]
	var right: Color = FighterSelectPortrait.COLORS[chosen[1]]
	# A shared stage, with each guild's color spilling behind its fighter.
	draw_colored_polygon(PackedVector2Array([Vector2(0, 70), Vector2(w * 0.39, 48), Vector2(w * 0.27, h - 56), Vector2(0, h - 72)]), Color(left, 0.10))
	if not online:
		draw_colored_polygon(PackedVector2Array([Vector2(w * 0.64, 48), Vector2(w, 70), Vector2(w, h - 72), Vector2(w * 0.74, h - 56)]), Color(right, 0.10))
	for i in 7:
		var y := h - 126.0 + i * 5.0
		draw_line(Vector2(0, y), Vector2(w * 0.28, y - 12), Color(left, 0.14), 1)
		if not online: draw_line(Vector2(w * 0.73, y - 12), Vector2(w, y), Color(right, 0.14), 1)
