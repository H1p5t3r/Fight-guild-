class_name ComboTrialHighway
extends Control

var session: ComboTrialSession
var accent := Color("bf2446")
var raw := 0
const PAPER := InkMenu.PAPER
const MUTED := Color("8c8799")
const LANE_COLORS := [Color("8de4ed"), Color("a9e8a3"), Color("ffe490"), Color("ffb383"), Color("d7b4ff")]
const DIRECTION_WIDTH := 96.0

func arrow(center: Vector2, value: int, radius: float, color: Color = PAPER) -> void:
	if value == 5:
		draw_arc(center, 4, 0, TAU, 16, color, 2, true)
		return
	var aim := Vector2((value - 1) % 3 - 1, 1 - floori(float(value - 1) / 3.0)).normalized()
	var side := aim.orthogonal()
	var points := PackedVector2Array([
		center + aim * radius,
		center + (aim * 0.1 + side * 0.72) * radius,
		center + (aim * 0.1 + side * 0.3) * radius,
		center + (-aim * 0.82 + side * 0.3) * radius,
		center + (-aim * 0.82 - side * 0.3) * radius,
		center + (aim * 0.1 - side * 0.3) * radius,
		center + (aim * 0.1 - side * 0.72) * radius])
	draw_circle(center, radius + 3, Color("100e17"))
	draw_colored_polygon(points, color)
	points.append(points[0])
	draw_polyline(points, Color(color, 0.75), 1, true)

func draw_directions(now: float, hit_y: float, top: float, pixels: float) -> void:
	var index := 0
	while index < session.directions.size():
		var cue := session.directions[index]
		if int(cue.value) == 5:
			index += 1
			continue
		# Rapid motion steps fan out across the direction lane. Each arrow stays
		# on its exact recorded tick; spacing them sideways avoids stacked arrows
		# without falsely stretching a quarter-circle's timing.
		var end := index + 1
		while end < mini(index + 5, session.directions.size()):
			var next := session.directions[end]
			if int(next.value) == 5 or int(next.frame) - int(session.directions[end - 1].frame) > 6: break
			end += 1
		var count := end - index
		var spacing := minf(26.0, (DIRECTION_WIDTH - 26) / maxf(1, count - 1))
		var radius := minf(12.0, spacing * 0.42)
		for i in range(index, end):
			cue = session.directions[i]
			var x := DIRECTION_WIDTH * 0.5 + (i - index - (count - 1) * 0.5) * spacing
			var y := hit_y - (int(cue.frame) - now) * pixels
			var end_y := hit_y - (int(cue.end) - now) * pixels
			if y < top or end_y > hit_y + 30: continue
			if int(cue.end) - int(cue.frame) >= 3:
				var a := clampf(y, top, hit_y + 30)
				var b := clampf(end_y, top, hit_y + 30)
				draw_line(Vector2(x, a), Vector2(x, b), Color(PAPER, 0.3), 6)
				if end_y >= top and end_y <= hit_y + 30:
					draw_line(Vector2(x - 8, end_y), Vector2(x + 8, end_y), PAPER, 2)
			if y >= top + radius + 3 and y <= hit_y + 30 - radius:
				arrow(Vector2(x, y), int(cue.value), radius)
		index = end

func text(value: String, at: Vector2, font_size: int, color: Color = PAPER) -> void:
	draw_string(GuildTheme.SEMIBOLD, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	if session == null or session.trial.is_empty(): return
	var hit_y := size.y - 112.0
	var top := 64.0
	var pixels := (hit_y - top) / 100.0
	var lane_width := (size.x - DIRECTION_WIDTH) / 5.0
	var now := float(session.clock)
	# At rest preview the first notes instead of an empty count-in.
	if session.state == "ready": now = -40
	draw_style_box(InkMenu.panel(Color("100e17"), accent, 2, 0), Rect2(Vector2.ZERO, size))
	draw_colored_polygon(InkMenu.slash(Rect2(0, 0, size.x, 48), 12), accent)
	text("FOLLOW THE INPUT", Vector2(18, 31), 22)
	draw_rect(Rect2(10, top, DIRECTION_WIDTH - 12, hit_y - top + 30), Color(PAPER, 0.035))
	for i in 5:
		var x := DIRECTION_WIDTH + lane_width * i
		draw_rect(Rect2(x, top, lane_width - 2, hit_y - top + 30), Color(LANE_COLORS[i], 0.045))
		draw_line(Vector2(x, top), Vector2(x, hit_y + 30), Color(PAPER, 0.09), 1)
		text(CombatModel.BUTTONS[i], Vector2(x + 12, 62), 17, LANE_COLORS[i])
	text("DIR", Vector2(35, 62), 15, MUTED)
	for tick in range(-120, int(session.trial.duration) + 120, 30):
		var y := hit_y - (tick - now) * pixels
		if y > top and y < hit_y + 32:
			draw_line(Vector2(14, y), Vector2(size.x - 12, y), Color(PAPER, 0.1), 1)
	draw_directions(now, hit_y, top, pixels)
	for note in session.notes:
		var y := hit_y - (int(note.frame) - now) * pixels
		var end_y := hit_y - (int(note.end) - now) * pixels
		if y < top - 15 or end_y > hit_y + 38: continue
		var lane := int(note.lane)
		var x := DIRECTION_WIDTH + lane_width * lane + lane_width * 0.5
		var color: Color = LANE_COLORS[lane]
		if note.judge == "MISSED": color = Color("f15e75")
		elif not str(note.judge).is_empty(): color = Color(PAPER, 0.5)
		if int(note.end) - int(note.frame) >= 3:
			draw_line(Vector2(x, clampf(y, top, hit_y + 30)), Vector2(x, clampf(end_y, top, hit_y + 30)), Color(color, 0.65), 10)
			if end_y >= top and end_y <= hit_y + 30: draw_line(Vector2(x - 11, end_y), Vector2(x + 11, end_y), color, 3)
		if y <= hit_y + 32:
			draw_colored_polygon(InkMenu.slash(Rect2(x - 21, y - 10, 42, 20), 5), color)
			draw_line(Vector2(x - 13, y), Vector2(x + 13, y), InkMenu.INK, 2)
	draw_line(Vector2(10, hit_y), Vector2(size.x - 10, hit_y), PAPER, 3)
	for i in 5:
		var x := DIRECTION_WIDTH + lane_width * i + lane_width * 0.5
		var lit := bool(raw & (16 << i))
		draw_circle(Vector2(x, hit_y), 14, Color(LANE_COLORS[i], 0.9 if lit else 0.09))
		draw_arc(Vector2(x, hit_y), 16, 0, TAU, 24, LANE_COLORS[i], 2, true)
	var direction := ComboTrialSession.direction(raw)
	draw_arc(Vector2(DIRECTION_WIDTH * 0.5, hit_y), 18, 0, TAU, 24, Color(PAPER, 0.45), 2, true)
	arrow(Vector2(DIRECTION_WIDTH * 0.5, hit_y), direction, 13, PAPER if direction != 5 else MUTED)
	text("PRESS HERE", Vector2(16, hit_y + 55), 21)
	text("Arrows = direction · trails = hold", Vector2(16, hit_y + 80), 14, MUTED)
	text("DIR = screen directions · 60 fps / hitstop included", Vector2(16, hit_y + 100), 13, MUTED)
