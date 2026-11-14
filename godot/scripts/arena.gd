extends Control

var model: CombatModel
var view := {}
var show_boxes := true
var paused := false
var sprites: Array[Sprite2D] = []
var font := ThemeDB.fallback_font
const ACCENT := Color("f4b45e")
const TEXT := Color("f0ede5")
const MUTED := Color("a3b8c7")

func _ready() -> void:
	custom_minimum_size = Vector2(720, 430)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	clip_contents = true
	for _p in 2:
		var sprite := Sprite2D.new()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(sprite)
		sprites.append(sprite)

func refresh(simulation: CombatModel, state: Dictionary, boxes: bool, frozen: bool) -> void:
	model = simulation
	view = state
	show_boxes = boxes
	paused = frozen
	var scale_x := size.x / 1000.0
	var floor_y := size.y - 76.0
	for p in 2:
		var fighter: Dictionary = view.players[p]
		var sprite := sprites[p]
		var crouched: bool = fighter.y == 0 and (int(fighter.raw) & 4) != 0
		var character := int(fighter.character)
		var phase := "active"
		var pose := 0
		if fighter.stun:
			pose = 10 if fighter.guarding else 9
		elif fighter.move >= 0:
			var move := model.move(character, fighter.move)
			if fighter.age < move.startup:
				phase = "windup"
				pose = 1 + int(move.button)
			elif fighter.age < move.startup + move.active:
				pose = 1 + int(move.button)
			# No fabricated recovery animation: hold ready pose while recovery runs.
			elif fighter.y > 0:
				pose = 8
			elif crouched:
				pose = 11
		elif fighter.y > 0:
			pose = 8
		elif crouched:
			pose = 11
		elif (int(fighter.raw) & 3) in [1, 2] or (int(fighter.raw) & 512) != 0:
			pose = 6 + (int(view.frame) / 8) % 2
		FighterArt.apply(sprite, character, phase, pose, scale_x, fighter.facing)
		sprite.position = Vector2(fighter.x / 100.0 * scale_x, floor_y - fighter.y / 100.0 * scale_x)
		sprite.modulate = Color("ffa69a") if fighter.stun and not fighter.guarding else Color.WHITE
	queue_redraw()

func label(value: String, point: Vector2, font_size: int = 14, color: Color = TEXT) -> void:
	draw_string(font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("202e38"))
	var sx := size.x / 1000.0
	var floor_y := size.y - 76.0
	for x in range(0, int(size.x), 70):
		draw_line(Vector2(x, 100), Vector2(x, floor_y), Color("2c3d48"))
	for y in range(120, int(floor_y), 50):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color("293b47"))
	draw_line(Vector2(0, floor_y), Vector2(size.x, floor_y), Color("7d939e"), 2)
	label("F G", Vector2(size.x * 0.43, size.y * 0.49), 64, Color("2d404b"))
	label("TRAINING FLOOR / SPRITE STUDY", Vector2(20, 118), 11, MUTED)
	if view.is_empty():
		return
	for p in 2:
		var fighter: Dictionary = view.players[p]
		var left := p == 0
		var width := size.x * 0.37
		var x := 22.0 if left else size.x - width - 22.0
		var tint := ACCENT if left else Color("91b6cb")
		label(CombatModel.CHARACTERS[fighter.character].to_upper(), Vector2(x, 34), 20)
		label("PLAYER %d / %s" % [p + 1, "SIMPLE + MOTIONS" if fighter.simple else "MOTION INPUTS"], Vector2(x, 52), 10, MUTED)
		draw_rect(Rect2(x, 64, width, 12), Color("111c23"))
		draw_rect(Rect2(x, 64, width * fighter.health / 1000.0, 12), tint)
		label(str(fighter.health), Vector2(x, 94), 11, MUTED)
		var px: float = fighter.x / 100.0 * sx
		var py: float = floor_y - fighter.y / 100.0 * sx
		var crouched: bool = fighter.y == 0 and (int(fighter.raw) & 4) != 0
		var height := 90.0 if crouched else 150.0
		if show_boxes:
			draw_rect(Rect2(px - 22 * sx, py - height * sx, 44 * sx, height * sx), Color("71a8c0"), false)
		if fighter.move >= 0:
			var move := model.move(fighter.character, fighter.move)
			if show_boxes and fighter.age >= move.startup and fighter.age < move.startup + move.active:
				var front: float = fighter.x / 100.0 + fighter.facing * move.reach / 100.0
				var back: float = fighter.x / 100.0 + fighter.facing * 12
				var hitbox := Rect2(minf(front, back) * sx, py - (move.bottom + move.height) / 100.0 * sx, absf(front - back) * sx, move.height / 100.0 * sx)
				draw_rect(hitbox, Color(1, 0.65, 0.25, 0.25))
				draw_rect(hitbox, ACCENT, false, 2)
			label("%s · %df" % [CombatModel.MOVE_IDS[fighter.move], fighter.age], Vector2(px - 25, py + 24), 12)
		else:
			label("BLOCK" if fighter.guarding else "HITSTUN" if fighter.stun else "READY", Vector2(px - 22, py + 24), 11, MUTED)
		if fighter.guarding:
			draw_arc(Vector2(px, py - 70 * sx), 58 * sx, -1.4, 1.4, 16, Color("89c3e0"), 3)
		if fighter.combo > 1 and view.players[1 - p].stun:
			label("%d HITS" % fighter.combo, Vector2(x, 170), 28, tint)
	label("%02d" % ceili(view.remaining / 60.0), Vector2(size.x / 2 - 24, 67), 42)
	if paused:
		label("PAUSED", Vector2(size.x / 2 - 28, 117), 12, ACCENT)
	label("FRAME %05d   |   %s" % [view.frame, "HITSTOP" if view.hitstop else "60 HZ"], Vector2(18, size.y - 20), 11, MUTED)
	if view.winner >= 0:
		draw_rect(Rect2(0, size.y * 0.37, size.x, 112), Color("111b23"))
		var title: String = "DRAW" if view.winner == 2 else CombatModel.CHARACTERS[view.players[view.winner].character].to_upper() + " TAKES THE ROUND"
		label(title, Vector2(size.x * 0.23, size.y * 0.37 + 46), 25, ACCENT)
		label("Reset to run it back. Online: leave and reconnect to rematch.", Vector2(size.x * 0.18, size.y * 0.37 + 80), 12, MUTED)
