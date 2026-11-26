class_name ComboTrialHighway
extends Control

var session: ComboTrialSession
var accent := Color("bf2446")
var raw := 0
const PAPER := InkMenu.PAPER
const MUTED := Color("8c8799")
const LANE_COLORS := [Color("8de4ed"), Color("a9e8a3"), Color("ffe490"), Color("ffb383"), Color("d7b4ff")]
const ARROWS := ["", "↙", "↓", "↘", "←", "·", "→", "↖", "↑", "↗"]

func text(value: String, at: Vector2, font_size: int, color: Color = PAPER) -> void:
	draw_string(GuildTheme.SEMIBOLD, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	if session == null or session.trial.is_empty(): return
	var hit_y := size.y - 112.0
	var top := 64.0
	var pixels := (hit_y - top) / 100.0
	var lane_width := (size.x - 72) / 5.0
	var now := float(session.clock)
	# At rest preview the first notes instead of an empty count-in.
	if session.state == "ready": now = -40
	draw_style_box(InkMenu.panel(Color("100e17"), accent, 2, 0), Rect2(Vector2.ZERO, size))
	draw_colored_polygon(InkMenu.slash(Rect2(0, 0, size.x, 48), 12), accent)
	text("FOLLOW THE INPUT", Vector2(18, 31), 22)
	for i in 5:
		var x := 72 + lane_width * i
		draw_rect(Rect2(x, top, lane_width - 2, hit_y - top + 30), Color(LANE_COLORS[i], 0.045))
		draw_line(Vector2(x, top), Vector2(x, hit_y + 30), Color(PAPER, 0.09), 1)
		text(CombatModel.BUTTONS[i], Vector2(x + 12, 62), 17, LANE_COLORS[i])
	text("DIR", Vector2(20, 62), 15, MUTED)
	for tick in range(-120, int(session.trial.duration) + 120, 30):
		var y := hit_y - (tick - now) * pixels
		if y > top and y < hit_y + 32:
			draw_line(Vector2(14, y), Vector2(size.x - 12, y), Color(PAPER, 0.1), 1)
	# Tiny direction diamonds preserve one-frame motions without overlapping
	# text. Group fast direction changes into a readable motion ribbon.
	var last_label := -1000
	for i in session.directions.size():
		var cue := session.directions[i]
		var y := hit_y - (int(cue.frame) - now) * pixels
		var end_y := hit_y - (int(cue.end) - now) * pixels
		if y < top or end_y > hit_y + 35: continue
		if int(cue.value) == 5: continue
		draw_line(Vector2(48, clampf(y, top, hit_y + 30)), Vector2(48, clampf(end_y, top, hit_y + 30)), Color(PAPER, 0.3), 3)
		if y <= hit_y + 30:
			draw_circle(Vector2(48, y), 3, PAPER)
			if int(cue.frame) - last_label > 8:
				var label := str(cue.value)
				for j in range(i + 1, mini(i + 5, session.directions.size())):
					var next := session.directions[j]
					if int(next.frame) - int(cue.frame) > 6 or int(next.value) == 5: break
					label += str(next.value)
					last_label = int(next.frame)
				last_label = maxi(last_label, int(cue.frame))
				text(label, Vector2(9, y - 6), 16)
	for note in session.notes:
		var y := hit_y - (int(note.frame) - now) * pixels
		var end_y := hit_y - (int(note.end) - now) * pixels
		if y < top - 15 or end_y > hit_y + 38: continue
		var lane := int(note.lane)
		var x := 72 + lane_width * lane + lane_width * 0.5
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
		var x := 72 + lane_width * i + lane_width * 0.5
		var lit := bool(raw & (16 << i))
		draw_circle(Vector2(x, hit_y), 14, Color(LANE_COLORS[i], 0.9 if lit else 0.09))
		draw_arc(Vector2(x, hit_y), 16, 0, TAU, 24, LANE_COLORS[i], 2, true)
	var direction := ComboTrialSession.direction(raw)
	text(ARROWS[direction], Vector2(20, hit_y + 9), 30)
	text("PRESS HERE", Vector2(16, hit_y + 55), 21)
	text("Long notes = hold · digits = direction", Vector2(16, hit_y + 80), 14, MUTED)
	text("DIR = screen directions · 60 fps / hitstop included", Vector2(16, hit_y + 100), 13, MUTED)
