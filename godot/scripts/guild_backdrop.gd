extends Control

var palette := MenuPalette.new()
var motion := MenuMotion.new()
var fighters := [5, 4]
var dominant_player := 0
var online := false
var contest := 0.0:
	set(value):
		contest = value
		queue_redraw()
var surge := 0.0:
	set(value):
		surge = value
		queue_redraw()
var clash_tween: Tween
var page := "home"
var travel := Vector2.ZERO:
	set(value):
		travel = value
		queue_redraw()
var display_accent := FighterSelectPortrait.COLORS[5]:
	set(value):
		display_accent = value
		queue_redraw()
var clash_amount := 0.0:
	set(value):
		clash_amount = value
		queue_redraw()
var side_darkness := 0.0:
	set(value):
		side_darkness = value
		queue_redraw()
var scene_tween: Tween
var color_tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)
	palette.changed.connect(retint)
	display_accent = palette.accent

func retint() -> void:
	if color_tween: color_tween.kill()
	if motion.instant or motion.reduced:
		display_accent = palette.accent
		return
	color_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	color_tween.tween_property(self, "display_accent", palette.accent, motion.duration(0.30))

func set_page(value: String, fresh: bool = false) -> void:
	page = value
	if scene_tween: scene_tween.kill()
	if fresh or motion.instant or motion.reduced:
		clash_amount = 1.0 if page == "fighters" else 0.0
		side_darkness = 1.0 if page == "sides" else 0.0
		return
	scene_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	scene_tween.tween_property(self, "clash_amount", 1.0 if page == "fighters" else 0.0, motion.duration(0.38))
	scene_tween.tween_property(self, "side_darkness", 1.0 if page == "sides" else 0.0, motion.duration(0.38))

func set_matchup(chosen: Array, player: int, remote: bool) -> void:
	var changed: bool = fighters != chosen or dominant_player != player or online != remote
	fighters = chosen.duplicate()
	dominant_player = player
	online = remote
	if not changed: return
	if clash_tween: clash_tween.kill()
	var target := 0.065 if player == 0 else -0.065
	if motion.instant or motion.reduced or not is_visible_in_tree():
		contest = target
		surge = 0.0
		return
	surge = 1.0
	clash_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	clash_tween.tween_property(self, "contest", target, motion.duration(0.28))
	clash_tween.tween_property(self, "surge", 0.0, motion.duration(0.28))

func finish_motion() -> void:
	if scene_tween: scene_tween.kill()
	if color_tween: color_tween.kill()
	display_accent = palette.accent
	clash_amount = 1.0 if page == "fighters" else 0.0
	side_darkness = 1.0 if page == "sides" else 0.0
	if clash_tween: clash_tween.kill()
	contest = 0.065 if dominant_player == 0 else -0.065
	surge = 0.0

func is_animating() -> bool:
	return (clash_tween != null and clash_tween.is_running()) or (scene_tween != null and scene_tween.is_running()) or (color_tween != null and color_tween.is_running())

func clash_color(color: Color) -> Color:
	return Color(color, color.a * clash_amount)

func draw_clash(w: float, h: float) -> void:
	var left: Color = clash_color(FighterSelectPortrait.COLORS[fighters[0]])
	var right: Color = FighterSelectPortrait.COLORS[fighters[1]] if not online else InkMenu.INK
	if fighters[0] == fighters[1] and not online: right = right.darkened(0.38)
	right = clash_color(right)
	# Guilds flood the whole screen, then tear into one another across an irregular seam.
	# There are no portrait-card bounds: silhouettes and color cuts share the same field.
	draw_rect(Rect2(Vector2.ZERO, size), right)
	var boundary := (0.5 + contest) * w
	var edge := PackedVector2Array([Vector2(boundary + 165, -10), Vector2(boundary + 90, h * 0.20), Vector2(boundary + 145, h * 0.24), Vector2(boundary - 10, h * 0.47), Vector2(boundary + 55, h * 0.50), Vector2(boundary - 125, h * 0.78), Vector2(boundary - 80, h * 0.82), Vector2(boundary - 170, h + 10)])
	var field := PackedVector2Array([Vector2(-10, -10)])
	field.append_array(edge)
	field.append(Vector2(-10, h + 10))
	draw_colored_polygon(field, left)
	draw_polyline(edge, clash_color(InkMenu.INK), 22, true)
	var reach := surge * 130.0
	# Blades of color cross the join; the focused side surges further without moving controls.
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.25, h * 0.59), Vector2(boundary + 180 + (reach if dominant_player == 0 else 0.0), h * 0.31), Vector2(boundary + 30, h * 0.49), Vector2(w * 0.30, h * 0.66)]), left)
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.88, h * 0.32), Vector2(boundary - 175 - (reach if dominant_player == 1 else 0.0), h * 0.63), Vector2(boundary - 10, h * 0.58), Vector2(w * 0.85, h * 0.41)]), right)
	draw_colored_polygon(PackedVector2Array([Vector2(0, h * 0.71), Vector2(w * 0.44, h * 0.56), Vector2(w * 0.27, h * 0.71), Vector2(w * 0.45, h * 0.68), Vector2(w * 0.34, h), Vector2(0, h)]), clash_color(InkMenu.INK))
	draw_colored_polygon(PackedVector2Array([Vector2(w, h * 0.60), Vector2(w * 0.63, h * 0.72), Vector2(w * 0.79, h * 0.71), Vector2(w * 0.54, h), Vector2(w, h)]), clash_color(InkMenu.INK))
	for side in 2:
		for row in 12:
			for column in 15:
				var x := column * 17 + row * 8.0
				draw_circle(Vector2(x if side == 0 else w - x, h * 0.19 + row * 17), 2.0, Color(InkMenu.INK, 0.27 * clash_amount))
	# Paper tears separate competing ink regions without enclosing either fighter.
	draw_colored_polygon(PackedVector2Array([Vector2(boundary + 167, 0), Vector2(boundary + 179, 0), Vector2(boundary + 60, h * 0.3)]), clash_color(InkMenu.PAPER))
	draw_colored_polygon(PackedVector2Array([Vector2(boundary - 182, h), Vector2(boundary - 163, h), Vector2(boundary - 25, h * 0.68)]), clash_color(InkMenu.PAPER))

func _draw() -> void:
	var w := size.x
	var h := size.y
	var pan := travel * Vector2(w * 0.13, h * 0.10)
	draw_rect(Rect2(Vector2.ZERO, size), display_accent)
	# The same pitch-long ink planes remain in view as the menu camera travels.
	# Their slower parallax, shared dot field and white rail expose the route between pages.
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w * 0.49 - pan.x * 0.20, 0), Vector2(w * 0.31 - pan.x * 0.20, h * 0.68), Vector2(w * 0.38 - pan.x * 0.20, h), Vector2(0, h)]), InkMenu.INK)
	if side_darkness > 0.0:
		draw_colored_polygon(PackedVector2Array([Vector2(0, h * 0.17), Vector2(w, h * 0.11), Vector2(w, h * 0.88), Vector2(0, h * 0.94)]), Color(display_accent.darkened(0.83), side_darkness))
	for row in range(-4, 38):
		for column in range(0, 66):
			var point := Vector2(w * 0.66 + column * 18 + (row % 2) * 9, row * 18) - pan
			if point.x >= 0 and point.x < w and point.y >= 0 and point.y < h * 0.76: draw_circle(point, 2.0, Color(0.035, 0.035, 0.047, 0.30))
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.75 - pan.x, 0), Vector2(w * 0.8 - pan.x, 0), Vector2(w * 0.51 - pan.x, h * 0.77)]), InkMenu.PAPER)
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.82 - pan.x, 0), Vector2(w * 0.85 - pan.x, 0), Vector2(w * 0.57 - pan.x, h * 0.77)]), InkMenu.INK)
	if clash_amount > 0.0: draw_clash(w, h)
	draw_colored_polygon(PackedVector2Array([Vector2(0, h - 66), Vector2(w * 0.38, h - 50), Vector2(w, h - 76), Vector2(w, h), Vector2(0, h)]), InkMenu.INK)
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.86, h - 78), Vector2(w, h - 94), Vector2(w, h - 82), Vector2(w * 0.75, h - 54)]), InkMenu.PAPER)
