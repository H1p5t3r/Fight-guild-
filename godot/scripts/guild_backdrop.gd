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
var page := "home":
	set(value):
		page = value
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)
	palette.changed.connect(queue_redraw)

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
	if clash_tween: clash_tween.kill()
	contest = 0.065 if dominant_player == 0 else -0.065
	surge = 0.0

func is_animating() -> bool:
	return clash_tween != null and clash_tween.is_running()

func draw_clash(w: float, h: float) -> void:
	var left: Color = FighterSelectPortrait.COLORS[fighters[0]]
	var right: Color = FighterSelectPortrait.COLORS[fighters[1]] if not online else InkMenu.INK
	if fighters[0] == fighters[1] and not online: right = right.darkened(0.38)
	# Guilds flood the whole screen, then tear into one another across an irregular seam.
	# There are no portrait-card bounds: silhouettes and color cuts share the same field.
	draw_rect(Rect2(Vector2.ZERO, size), right)
	var boundary := (0.5 + contest) * w
	var edge := PackedVector2Array([Vector2(boundary + 165, -10), Vector2(boundary + 90, h * 0.20), Vector2(boundary + 145, h * 0.24), Vector2(boundary - 10, h * 0.47), Vector2(boundary + 55, h * 0.50), Vector2(boundary - 125, h * 0.78), Vector2(boundary - 80, h * 0.82), Vector2(boundary - 170, h + 10)])
	var field := PackedVector2Array([Vector2(-10, -10)])
	field.append_array(edge)
	field.append(Vector2(-10, h + 10))
	draw_colored_polygon(field, left)
	draw_polyline(edge, InkMenu.INK, 22, true)
	var reach := surge * 130.0
	# Blades of color cross the join; the focused side surges further without moving controls.
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.25, h * 0.59), Vector2(boundary + 180 + (reach if dominant_player == 0 else 0.0), h * 0.31), Vector2(boundary + 30, h * 0.49), Vector2(w * 0.30, h * 0.66)]), left)
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.88, h * 0.32), Vector2(boundary - 175 - (reach if dominant_player == 1 else 0.0), h * 0.63), Vector2(boundary - 10, h * 0.58), Vector2(w * 0.85, h * 0.41)]), right)
	draw_colored_polygon(PackedVector2Array([Vector2(0, h * 0.71), Vector2(w * 0.44, h * 0.56), Vector2(w * 0.27, h * 0.71), Vector2(w * 0.45, h * 0.68), Vector2(w * 0.34, h), Vector2(0, h)]), InkMenu.INK)
	draw_colored_polygon(PackedVector2Array([Vector2(w, h * 0.60), Vector2(w * 0.63, h * 0.72), Vector2(w * 0.79, h * 0.71), Vector2(w * 0.54, h), Vector2(w, h)]), InkMenu.INK)
	for side in 2:
		for row in 12:
			for column in 15:
				var x := column * 17 + row * 8.0
				draw_circle(Vector2(x if side == 0 else w - x, h * 0.19 + row * 17), 2.0, Color(InkMenu.INK, 0.27))
	# Paper tears separate competing ink regions without enclosing either fighter.
	draw_colored_polygon(PackedVector2Array([Vector2(boundary + 167, 0), Vector2(boundary + 179, 0), Vector2(boundary + 60, h * 0.3)]), InkMenu.PAPER)
	draw_colored_polygon(PackedVector2Array([Vector2(boundary - 182, h), Vector2(boundary - 163, h), Vector2(boundary - 25, h * 0.68)]), InkMenu.PAPER)

func _draw() -> void:
	var w := size.x
	var h := size.y
	if page == "fighters":
		draw_clash(w, h)
		draw_rect(Rect2(0, h - 64, w, 64), InkMenu.INK)
		return
	draw_rect(Rect2(Vector2.ZERO, size), palette.accent)
	# Screen-print fields, not gradients. Negative space stays clear behind the controls.
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w * 0.49, 0), Vector2(w * 0.31, h * 0.68), Vector2(w * 0.38, h), Vector2(0, h)]), InkMenu.INK)
	if page in ["sides", "fighters"]:
		draw_colored_polygon(PackedVector2Array([Vector2(0, h * 0.17), Vector2(w, h * 0.11), Vector2(w, h * 0.88), Vector2(0, h * 0.94)]), palette.accent.darkened(0.83))
	for row in range(0, 32):
		for column in range(0, 26):
			var point := Vector2(w * 0.66 + column * 18 + (row % 2) * 9, row * 18)
			if point.x < w and point.y < h * 0.76: draw_circle(point, 2.0, Color(0.035, 0.035, 0.047, 0.30))
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.75, 0), Vector2(w * 0.8, 0), Vector2(w * 0.51, h * 0.77)]), InkMenu.PAPER)
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.82, 0), Vector2(w * 0.85, 0), Vector2(w * 0.57, h * 0.77)]), InkMenu.INK)
	# Bottom cuts recall the broken, angular health rails in combat.
	draw_colored_polygon(PackedVector2Array([Vector2(0, h - 66), Vector2(w * 0.38, h - 50), Vector2(w, h - 76), Vector2(w, h), Vector2(0, h)]), InkMenu.INK)
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.86, h - 78), Vector2(w, h - 94), Vector2(w, h - 82), Vector2(w * 0.75, h - 54)]), InkMenu.PAPER)
