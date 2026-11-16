class_name CombatTypography
extends RefCounted

# Original treatment using the bundled, licensed font. No game UI textures are copied.
const FONT = preload("res://assets/fonts/DejaVuSansCondensed-BoldOblique.ttf")
const INK := Color("100d14")
const PAPER := Color("fff4da")
const COUNTER := Color("ffd04b")
const RED := Color("d84a38")

static func word(canvas: CanvasItem, value: String, center: Vector2, font_size: int, maximum_width: float,
		color: Color = PAPER, alpha: float = 1.0, angle: float = -0.035, depth: float = 5.0) -> void:
	var width := FONT.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var scale_x := minf(1.0, maximum_width / maxf(1.0, width))
	canvas.draw_set_transform(center, angle, Vector2(scale_x, 1.12))
	var point := Vector2(-width * 0.5, font_size * 0.33)
	canvas.draw_string_outline(FONT, point + Vector2(depth, depth), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 8, Color(RED, alpha * 0.85))
	canvas.draw_string_outline(FONT, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 7, Color(INK, alpha))
	canvas.draw_string(FONT, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(color, alpha))
	canvas.draw_set_transform(Vector2.ZERO)

static func rule(canvas: CanvasItem, center: Vector2, width: float, accent: Color, alpha: float) -> void:
	var y := center.y
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(center.x - width * 0.5, y), Vector2(center.x + width * 0.5, y - 7),
		Vector2(center.x + width * 0.5 - 18, y + 3), Vector2(center.x - width * 0.5 - 12, y + 9)]), Color(accent, alpha))
