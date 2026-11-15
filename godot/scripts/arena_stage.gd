class_name ArenaStage
extends RefCounted

static func draw(canvas: Control, debug_grid: bool, stage: int = 0) -> void:
	var w := canvas.size.x
	var h := canvas.size.y
	var floor_y := h - 76.0
	canvas.draw_rect(Rect2(Vector2.ZERO, canvas.size), Color("0b1821"))
	# A graphic sports-ground study: stands, guild pennants and chalked field planes.
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(0, 120), Vector2(w * 0.36, 156), Vector2(w * 0.43, floor_y), Vector2(0, floor_y)]), Color("102630"))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(w * 0.64, 156), Vector2(w, 120), Vector2(w, floor_y), Vector2(w * 0.57, floor_y)]), Color("17282c"))
	for p in 2:
		var x := w * (0.16 if p == 0 else 0.84)
		var color: Color = FightHud.PLAYER_COLORS[p]
		var banner := PackedVector2Array([Vector2(x - 32, 146), Vector2(x + 32, 146), Vector2(x + 32, h * 0.50), Vector2(x, h * 0.50 - 23), Vector2(x - 32, h * 0.50)])
		canvas.draw_colored_polygon(banner, Color(color, 0.08))
		canvas.draw_line(Vector2(x, 162), Vector2(x, h * 0.44), Color(color, 0.15), 2)
	var stand_y := maxf(170.0, h * 0.48)
	for row in 3:
		var y := stand_y + row * 19
		canvas.draw_rect(Rect2(0, y, w, 13), Color("14252c"))
		for seat in range(0, int(w), 35):
			var x := float(seat + (row % 2) * 13)
			canvas.draw_circle(Vector2(x, y + 1), 3.5, Color("20353c"))
			canvas.draw_line(Vector2(x - 4, y + 11), Vector2(x + 4, y + 11), Color("20353c"), 7)
	canvas.draw_rect(Rect2(0, stand_y + 64, w, maxf(floor_y - stand_y - 64, 0)), Color("14292e"))
	canvas.draw_line(Vector2(0, stand_y + 63), Vector2(w, stand_y + 63), Color("40504b"), 3)
	for side in [-1, 1]:
		canvas.draw_line(Vector2(w * 0.5 + side * 36, stand_y + 64), Vector2(w * 0.5 + side * w * 0.44, floor_y), Color("243d3d"), 2, true)
	canvas.draw_line(Vector2(0, floor_y - 26), Vector2(w, floor_y - 26), Color("294342"), 2)
	canvas.draw_line(Vector2(0, floor_y), Vector2(w, floor_y), Color("788e81"), 2)
	FightHud.centered(canvas, "FIGHT GUILD", Vector2(w * 0.5, stand_y - 16), 46, Color("21363c"))
	canvas.draw_rect(Rect2(0, floor_y + 1, w, h - floor_y), Color("0a161e"))
	var zone_colors := [Color("5e9fa3"), Color("c7956c"), Color("97ad84")]
	var zone: Color = zone_colors[stage % zone_colors.size()]
	canvas.draw_rect(Rect2(0, 145, w, floor_y - 145), Color(zone, 0.025 if stage == 0 else 0.09))
	FightHud.centered(canvas, ["CENTRE GROUND", "GUILD TERRACE", "THE NORTH END"][stage % 3], Vector2(w * 0.5, stand_y + 55), 13, Color(zone, 0.65))
	if debug_grid:
		for x in range(0, int(w), 70): canvas.draw_line(Vector2(x, 140), Vector2(x, floor_y), Color(0.25, 0.38, 0.43, 0.25))
		for y in range(160, int(floor_y), 50): canvas.draw_line(Vector2(0, y), Vector2(w, y), Color(0.25, 0.38, 0.43, 0.25))
