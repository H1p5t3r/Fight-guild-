class_name FrameTimeline
extends Control

var lab: TrainingLab
var selected := -1
const COLORS := {"READY": Color("465460"), "START": Color("e7be64"), "ACTIVE": Color("ef6c61"), "RECOVER": Color("7497d0"), "GUARD": Color("67cfbb"), "HIT": Color("c48cdb"), "REEL": Color("c48cdb"), "DOWN": Color("89818e"), "LAND": Color("7497d0")}

func _ready() -> void:
	custom_minimum_size = Vector2(760, 160)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseMotion:
			selected = clampi(int((event.position.x - 35) / maxf(1.0, (size.x - 40) / TrainingLab.TRACE_LENGTH)), 0, TrainingLab.TRACE_LENGTH - 1)
			queue_redraw())

func text(value: String, point: Vector2, color: Color = GuildTheme.IVORY) -> void:
	draw_string(GuildTheme.REGULAR, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, color)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("141c24"))
	if lab == null: return
	text("START   ACTIVE   RECOVERY   GUARD   HIT / REEL     • white mark = contact; dim = hitstop", Vector2(10, 19))
	var width := (size.x - 40.0) / TrainingLab.TRACE_LENGTH
	for p in 2:
		text("P%d" % (p+1), Vector2(4, 46 + p*28))
		for i in lab.trace.size():
			var tick: Dictionary = lab.trace[i]
			var sample: Dictionary = tick.players[p]
			var color: Color = COLORS.get(sample.phase, COLORS.READY)
			if tick.freeze: color = color.darkened(0.55)
			var rect := Rect2(35+i*width, 30+p*28, maxf(1, width-1), 21)
			draw_rect(rect, color)
			if sample.contact: draw_line(rect.position, rect.position + Vector2(width, 0), Color.WHITE, 3)
			if sample.cancelMask: draw_line(rect.end - Vector2(width, 0), rect.end, GuildTheme.BRASS, 2)
	if lab.trace.is_empty(): text("Play or record an exchange, then inspect its last 180 ticks here.", Vector2(10, 112)); return
	var index := mini(selected, lab.trace.size()-1) if selected >= 0 else lab.trace.size()-1
	var tick: Dictionary = lab.trace[index]
	draw_line(Vector2(35+index*width, 28), Vector2(35+index*width, 82), Color.WHITE)
	for p in 2:
		var item: Dictionary = tick.players[p]
		var move: String = CombatModel.MOVE_IDS[item.move] if item.move >= 0 else "—"
		var details := "P%d · %s %s · age %df · input %d · stun %df · spacing %.1fpx" % [p+1, move, item.phase, item.age, item.input, item.stun, item.spacing]
		if item.gap >= 0: details += " · gap %df" % item.gap
		if item.advantage != null: details += " · attacker %+df" % item.advantage
		text(details, Vector2(10, 106+p*22))
	text("Tick %d · gold underline = open cancel window · hover to inspect" % tick.frame, Vector2(10, 151), GuildTheme.BRASS)
