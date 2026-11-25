class_name PauseCommandButton
extends InkMenuButton

var subtitle := ""
var guild := Color.WHITE

func fit_caption() -> void:
	# The radial composition owns the strip's bounds, including long online labels.
	custom_minimum_size = Vector2.ZERO

func _draw() -> void:
	var focused := (has_focus() or is_hovered()) and not disabled
	var w := size.x
	var h := size.y
	var unit := h / 90.0
	var body := Rect2(5 * unit, 5 * unit, w - 10 * unit, h - 18 * unit)
	# Printed color overshoots the black plate, with an uneven cut at the tail.
	draw_colored_polygon(PackedVector2Array([Vector2(17, 21) * unit, Vector2(w - 2, 3 * unit), Vector2(w - 19 * unit, h - 4 * unit), Vector2(2 * unit, h), Vector2(19, 47) * unit]), guild)
	draw_colored_polygon(InkMenu.slash(body, 16 * unit), InkMenu.PAPER if focused else InkMenu.INK)
	var foreground := InkMenu.INK if focused else InkMenu.PAPER
	var radius := 17.0 * unit
	var badge := Vector2(30, 36) * unit
	draw_circle(badge, radius + 3 * unit, InkMenu.INK)
	draw_circle(badge, radius, guild if focused else InkMenu.INK)
	draw_arc(badge, radius, 0, TAU, 32, InkMenu.INK if focused else InkMenu.PAPER, 2 * unit, true)
	draw_string(GuildTheme.SEMIBOLD, badge + Vector2(-10, 6) * unit, serial, HORIZONTAL_ALIGNMENT_LEFT, -1, int(17 * unit), InkMenu.INK if focused else InkMenu.PAPER)
	InkMenu.word(self, text.to_upper(), Vector2(54, 43) * unit, int(43 * unit), foreground, -0.025, w - 76 * unit)
	draw_string(GuildTheme.SEMIBOLD, Vector2(55, 65) * unit, subtitle, HORIZONTAL_ALIGNMENT_LEFT, w - 74 * unit, int(16 * unit), foreground)
	if focused:
		draw_colored_polygon(PackedVector2Array([Vector2(2, 30) * unit, Vector2(15, 38) * unit, Vector2(1, 48) * unit]), guild)
