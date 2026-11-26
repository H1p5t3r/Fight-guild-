class_name ComboTrialHighway
extends Control

var session: ComboTrialSession
var accent := Color("bf2446")
var raw := 0
const PAPER := InkMenu.PAPER
const MUTED := Color("8c8799")
const LANE_COLORS := [Color("8de4ed"), Color("a9e8a3"), Color("ffe490"), Color("ffb383"), Color("d7b4ff")]
const DIRECTION_WIDTH := 96.0
const CORRECT := Color("9aefbc")
const EARLY := Color("ffd381")
const LATE := Color("9ccfff")
const WRONG := Color("ff7f95")

static func indicator_color(event: Dictionary) -> Color:
	match str(event.judge):
		"ON TIME": return CORRECT if event.accepted else PAPER
		"EARLY", "RELEASED EARLY": return EARLY
		"LATE": return LATE
		_: return WRONG

func latest_indicator(lane: int = -1) -> Dictionary:
	for i in range(session.actual_notes.size() - 1, -1, -1):
		var event := session.actual_notes[i]
		if lane >= 0 and int(event.lane) != lane: continue
		if session.running() and session.clock - int(event.frame) > 72: return {}
		return event
	return {}

func centered(value: String, x: float, y: float, font_size: int, color: Color) -> void:
	var width := GuildTheme.SEMIBOLD.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	text(value, Vector2(x - width * 0.5, y), font_size, color)

func mark(center: Vector2, event: Dictionary, color: Color) -> void:
	if event.judge == "ON TIME" and event.accepted:
		draw_polyline(PackedVector2Array([center + Vector2(-7, 0), center + Vector2(-2, 5), center + Vector2(8, -6)]), color, 3, true)
	elif event.judge in ["WRONG INPUT", "MISSED", "NOT ACCEPTED"]:
		draw_line(center + Vector2(-6, -6), center + Vector2(6, 6), color, 3, true)
		draw_line(center + Vector2(-6, 6), center + Vector2(6, -6), color, 3, true)
	elif event.judge in ["EARLY", "LATE", "RELEASED EARLY"]:
		var y := -6.0 if int(event.delta) < 0 else 6.0
		draw_polyline(PackedVector2Array([center + Vector2(-7, -y), center + Vector2(0, y), center + Vector2(7, -y)]), color, 3, true)
	else: draw_circle(center, 4, color)

func draw_indicator(event: Dictionary, x: float, hit_y: float, top: float, pixels: float, lane_width: float) -> void:
	var color := indicator_color(event)
	var age := maxf(0, session.clock - int(event.frame))
	var pulse := 1.0 - clampf(age / 18.0, 0, 1)
	draw_rect(Rect2(x - lane_width * 0.5, top, lane_width - 2, hit_y - top + 24), Color(color, 0.04 + pulse * 0.12))
	if event.judge in ["EARLY", "LATE", "RELEASED EARLY"]:
		# The outlined note shows where the cue was WHEN the button was pressed.
		# Its distance from the fixed input line is the signed timing error.
		var offset := clampf(float(event.delta) * pixels, -82, 16)
		var target_y := hit_y + offset
		draw_line(Vector2(x, target_y), Vector2(x, hit_y), Color(color, 0.65), 2, true)
		draw_rect(Rect2(x - 18, target_y - 5, 36, 10), color, false, 2)
	elif event.judge == "WRONG INPUT" and int(event.expected_lane) >= 0 and int(event.expected_lane) != int(event.lane):
		var expected_x := DIRECTION_WIDTH + lane_width * (float(event.expected_lane) + 0.5)
		draw_arc(Vector2(expected_x, hit_y), 21, 0, TAU, 32, Color(WRONG, 0.7), 2, true)
	if event.direction_error:
		draw_arc(Vector2(DIRECTION_WIDTH * 0.5, hit_y), 23, 0, TAU, 32, WRONG, 3, true)
		centered("WRONG", DIRECTION_WIDTH * 0.5, hit_y + 37, 14, WRONG)
	draw_circle(Vector2(x, hit_y), 17, Color("100e17"))
	draw_arc(Vector2(x, hit_y), 18 + (1.0 - pulse) * 7.0, 0, TAU, 32, Color(color, 0.3 + 0.7 * pulse), 2, true)
	mark(Vector2(x, hit_y), event, color)
	var label := str(event.judge)
	if label == "ON TIME": label = "OK" if event.accepted else "WAIT"
	elif label == "WRONG INPUT": label = "WRONG"
	elif label == "RELEASED EARLY": label = "RELEASE"
	elif label == "NOT ACCEPTED": label = "NO MOVE"
	centered(label, x, hit_y + 37, 14, color)
	if event.judge in ["EARLY", "LATE", "RELEASED EARLY"]:
		centered("%+df" % int(event.delta), x, hit_y + 52, 13, color)

func draw_feedback(hit_y: float) -> void:
	var event := latest_indicator()
	if event.is_empty():
		text("PRESS HERE", Vector2(16, hit_y + 80), 21)
		text("Arrows = direction · trails = hold", Vector2(16, hit_y + 101), 14, MUTED)
		text("DIR = screen directions · 60 fps / hitstop included", Vector2(16, hit_y + 122), 13, MUTED)
		return
	var color := indicator_color(event)
	var button: String = CombatModel.BUTTONS[int(event.lane)]
	var title := ""
	var detail := ""
	match str(event.judge):
		"ON TIME":
			title = "CORRECT · " + button if event.accepted else "ON TIME · " + button
			detail = "Move registered." if event.accepted else "Waiting for the buffered move."
		"EARLY", "LATE":
			title = "TOO %s · %df" % [str(event.judge), absi(int(event.delta))]
			detail = "%s pressed %s the cue%s" % [button, "before" if int(event.delta) < 0 else "after", " · move registered." if event.accepted else "."]
		"RELEASED EARLY":
			title = "RELEASED EARLY · " + button
			detail = "Hold for %d more frames, to the end cap." % absi(int(event.delta))
		"MISSED":
			title = "MISSED · " + button
			detail = "No press reached this note."
		"NOT ACCEPTED":
			title = "INPUT NOT ACCEPTED"
			detail = button + " was on time, but the move did not start."
		_:
			title = "WRONG INPUT · " + button
			detail = str(event.detail)
			if detail.is_empty():
				detail = "Expected " + CombatModel.BUTTONS[int(event.expected_lane)] + "." if int(event.expected_lane) >= 0 else "No matching button in this part of the route."
	draw_line(Vector2(14, hit_y + 62), Vector2(size.x - 14, hit_y + 62), Color(color, 0.6), 2)
	text(title, Vector2(16, hit_y + 86), 23, color)
	text(detail, Vector2(16, hit_y + 107), 15, PAPER)
	text("Timing is measured against the demo · 60 fps", Vector2(16, hit_y + 125), 12, MUTED)

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
	var hit_y := size.y - 136.0
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
		if note.result == "RELEASED EARLY": color = EARLY
		elif not str(note.result).is_empty() or note.judge == "MISSED": color = WRONG
		elif int(note.event) >= 0: color = indicator_color(session.actual_notes[int(note.event)])
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
	for lane in 5:
		var event := latest_indicator(lane)
		if not event.is_empty():
			draw_indicator(event, DIRECTION_WIDTH + lane_width * (lane + 0.5), hit_y, top, pixels, lane_width)
	draw_feedback(hit_y)
