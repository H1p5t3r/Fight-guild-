class_name PauseCommands
extends Control

signal action_requested(action: String)

var motion := MenuMotion.new()
var buttons := {}
var note: Label
var characters := [5, 4]
var anchor_ratio := Vector2(0.5, 0.60)
var reframe_pending := false
# One focal point for the entire frozen pair, in viewport-normalized coordinates.
var focal_point := Vector2(0.5, 0.57):
	set(value):
		focal_point = value
		reframe_pending = true
		layout_commands()
var arrival := 1.0:
	set(value):
		arrival = value
		layout_commands()
var tween: Tween
const ORDER := ["restart", "change_fighters", "pause_home", "pause_controls", "pause_sound", "resume"]
const ANGLES := [0.23, -0.12, -0.22, -0.23, 0.10, 0.22]
const DIRECTIONS := [Vector2(-0.55, -1), Vector2(-1, 0), Vector2(-0.6, 1), Vector2(0.55, -1), Vector2(1, 0), Vector2(0.6, 1)]
var focus_local := Vector2.ZERO
var centers: Array[Vector2] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size.y = 350
	for spec in [["restart", "RESTART", "Reset this Scrum", "02"], ["change_fighters", "FIGHTERS", "Change the matchup", "03"], ["pause_home", "MAIN MENU", "Leave the arena", "04"], ["pause_controls", "CONTROLS", "Buttons & devices", "05"], ["pause_sound", "SOUND", "Mix & volume", "06"], ["resume", "BACK IN", "Resume the fight", "01"]]:
		var button := PauseCommandButton.new()
		button.text = spec[1]
		button.subtitle = spec[2]
		button.serial = spec[3]
		button.motion = motion
		button.accessibility_name = spec[1] + ". " + spec[2]
		button.pressed.connect(func(): action_requested.emit(spec[0]))
		buttons[spec[0]] = button
		add_child(button)
	note = Label.new()
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_override("font", GuildTheme.SEMIBOLD)
	note.add_theme_font_size_override("font_size", 17)
	note.add_theme_color_override("font_color", InkMenu.PAPER)
	note.add_theme_color_override("font_outline_color", InkMenu.INK)
	note.add_theme_constant_override("outline_size", 8)
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(note)
	resized.connect(layout_commands)
	configure([5, 4])

func configure(pair: Array) -> void:
	characters = pair.duplicate()
	if buttons.is_empty(): return
	for i in ORDER.size():
		var button: PauseCommandButton = buttons[ORDER[i]]
		button.guild = FighterSelectPortrait.COLORS[characters[0 if i < 3 else 1]]
		button.queue_redraw()
	# Directions follow the visible columns. Hidden online-only omissions are
	# skipped, while Tab retains a complete sequential path through every action.
	for i in ORDER.size():
		var button: Button = buttons[ORDER[i]]
		if not button.visible: continue
		var column: Array = ORDER.slice(0, 3) if i < 3 else ORDER.slice(3, 6)
		column = column.filter(func(id): return buttons[id].visible)
		var row := column.find(ORDER[i])
		button.focus_neighbor_top = button.get_path_to(buttons[column[(row + column.size() - 1) % column.size()]])
		button.focus_neighbor_bottom = button.get_path_to(buttons[column[(row + 1) % column.size()]])
		var other: Button = buttons[ORDER[(i + 3) % 6]]
		if not other.visible: other = buttons.pause_home
		button.focus_neighbor_left = button.get_path_to(other)
		button.focus_neighbor_right = button.get_path_to(other)
	layout_commands()

func enter() -> void:
	if tween: tween.kill()
	arrival = 0.0
	if motion.instant:
		arrival = 1.0
		return
	tween = create_tween()
	tween.tween_property(self, "arrival", 1.0, motion.duration(0.38))

func depart() -> void:
	if tween: tween.kill()
	if motion.instant:
		arrival = 0.0
		return
	tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "arrival", 0.0, motion.duration(0.28))

func finish() -> void:
	if tween: tween.kill()
	arrival = 1.0

func is_animating() -> bool:
	return tween != null and tween.is_running()

func progress(index: int) -> float:
	if motion.reduced: return arrival
	var delay := [0.04, 0.10, 0.16, 0.0, 0.08, 0.13][index] as float
	var t := clampf((arrival - delay) / (1.0 - delay), 0.0, 1.0)
	return 1.0 - pow(1.0 - t, 3.0)

func layout_commands() -> void:
	if buttons.is_empty() or size.x < 1.0: return
	if reframe_pending and size.y > 0.0 and is_visible_in_tree():
		anchor_ratio = (focal_point * get_viewport_rect().size - get_global_position()) / size
		reframe_pending = false
	# Keep the pair's composition attached to this menu location during camera
	# travel; recomputing from global position would drag the spokes across it.
	focus_local = anchor_ratio * size
	var unit := minf(size.x / 1200.0, size.y / 558.0)
	var center := focus_local.clamp(Vector2(size.x * 0.40, size.y * 0.46), Vector2(size.x * 0.60, size.y * 0.58))
	centers.clear()
	for i in ORDER.size():
		var button: PauseCommandButton = buttons[ORDER[i]]
		button.size = Vector2(310, 90) * unit
		button.pivot_offset = button.size * 0.5
		button.rotation = ANGLES[i]
		var row: int = i % 3
		var sign_x := -1.0 if i < 3 else 1.0
		var target := center + Vector2(sign_x * (405.0 + (22.0 if row == 1 else 0.0)), (row - 1) * 163.0) * unit
		var angle: float = absf(ANGLES[i])
		var half := Vector2(cos(angle) * button.size.x + sin(angle) * button.size.y, sin(angle) * button.size.x + cos(angle) * button.size.y) * 0.5
		target = target.clamp(half + Vector2(14, 16), size - half - Vector2(14, 28))
		var t := progress(i)
		var start: Vector2 = target + DIRECTIONS[i] * (size + button.size)
		var current := target if motion.reduced else start.lerp(target, t)
		button.position = current - button.size * 0.5
		button.modulate.a = minf(1.0, t * 2.5)
		centers.append(current)
	if is_instance_valid(note):
		note.position = Vector2(size.x * 0.15, size.y - 28 + (0.0 if motion.reduced else (1.0 - arrival) * 130.0))
		note.size = Vector2(size.x * 0.70, 28)
		note.modulate.a = arrival
	queue_redraw()

func _draw() -> void:
	if centers.size() != 6: return
	var unit := minf(size.x / 1200.0, size.y / 558.0)
	# Irregular color rays share the pair's real focal point, rather than placing
	# one radial menu on each fighter. Clamped strips keep corner pauses readable.
	for i in ORDER.size():
		if not buttons[ORDER[i]].visible: continue
		var t := progress(i)
		if t <= 0.001: continue
		var end := centers[i]
		var direction := (end - focus_local).normalized()
		var side := direction.orthogonal()
		var start := focus_local + direction * 95.0 * unit
		var color: Color = FighterSelectPortrait.COLORS[characters[0 if i < 3 else 1]]
		draw_colored_polygon(PackedVector2Array([start, end + side * 34 * unit, end - side * 47 * unit, start - side * 7 * unit]), Color(InkMenu.INK, t))
		draw_colored_polygon(PackedVector2Array([start + direction * 28 * unit, end + side * 20 * unit, end - side * 27 * unit, start - side * 3 * unit]), Color(color, t))
	var title_origin := Vector2(size.x * 0.5 - 125 * unit, 38 * unit - (0.0 if motion.reduced else (1.0 - arrival) * 180.0))
	var plate := Rect2(title_origin + Vector2(-25, -48) * unit, Vector2(300, 62) * unit)
	draw_colored_polygon(InkMenu.slash(plate, 26 * unit), Color(InkMenu.INK, arrival))
	InkMenu.word(self, "TIME OUT", title_origin, int(55 * unit), Color(InkMenu.PAPER, arrival), -0.065, 270 * unit)
