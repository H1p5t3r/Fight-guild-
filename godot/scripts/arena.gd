extends Control

var model: CombatModel
var view := {}
var show_boxes := true
var paused := false
var round_label := ""
var score := [0, 0]
var presentation_active := false
var diagnostics := true
var sprites: Array[Sprite2D] = []
var hud_layer: Control
var feedback := CombatFeedback.new()
var font := GuildTheme.SEMIBOLD
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
	hud_layer = Control.new()
	hud_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	hud_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hud_layer)
	hud_layer.draw.connect(func():
		if not view.is_empty(): FightHud.draw(hud_layer, view, score, round_label, diagnostics))

func refresh(simulation: CombatModel, state: Dictionary, boxes: bool, frozen: bool) -> void:
	model = simulation
	view = state
	show_boxes = boxes
	paused = frozen
	feedback.refresh(view, size)
	var scale_x := size.x / 1000.0
	var floor_y := size.y - 76.0
	for p in 2:
		var fighter: Dictionary = view.players[p]
		var sprite := sprites[p]
		var crouched: bool = fighter.y == 0 and (int(fighter.raw) & 4) != 0
		var character := int(fighter.character)
		var phase := "active"
		var pose := 0
		if fighter.guarding and fighter.blockReaction > 0:
			phase = "block"
			pose = (int(fighter.blockReaction) - 1) * 2 + (1 if fighter.blockAge >= 4 else 0)
		elif fighter.stun:
			pose = 9
		elif fighter.faultless:
			phase = "block"
			pose = 1
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
	hud_layer.queue_redraw()

func label(value: String, point: Vector2, font_size: int = 14, color: Color = TEXT) -> void:
	draw_string(font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	ArenaStage.draw(self, show_boxes)
	var sx := size.x / 1000.0
	var floor_y := size.y - 76.0
	if view.is_empty():
		return
	# Draw in the stage background before the HUD and before child fighter sprites.
	feedback.draw(self)
	for p in 2:
		var fighter: Dictionary = view.players[p]
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
			if diagnostics: label("%s · %df" % [CombatModel.MOVE_IDS[fighter.move], fighter.age], Vector2(px + 28, py - 10), 12)
		elif diagnostics:
			var status := "HITSTUN" if fighter.stun else "READY"
			if fighter.guarding:
				status = "GUARD BREAK" if fighter.guardBreak else "BLOCK · attacker %+df" % fighter.blockAdvantage
			elif fighter.faultless: status = "FAULTLESS"
			label(status, Vector2(clampf(px + 28, 12, size.x - 165), py - 10), 12, Color("f68b79") if fighter.guardBreak else MUTED)
		if fighter.faultless or (fighter.guarding and not fighter.guardBreak):
			var angle := 0.0 if fighter.facing == 1 else PI
			var guard_color := Color("75dcbc") if fighter.faultless else Color("89c3e0")
			draw_arc(Vector2(px, py - 70 * sx), 58 * sx, angle - 1.4, angle + 1.4, 24, guard_color, 5 if fighter.faultless else 2)
	if paused:
		FightHud.centered(self, "PAUSED", Vector2(size.x * 0.5, 151), 17, GuildTheme.BRASS)
	if diagnostics:
		FightHud.centered(self, "%05d · %s" % [view.frame, "STOP" if view.hitstop else "60HZ"], Vector2(size.x * 0.5, size.y - 9), 12, MUTED)
	if view.winner >= 0 and not presentation_active:
		var title: String = "DRAW" if view.winner == 2 else CombatModel.CHARACTERS[view.players[view.winner].character].to_upper() + " TAKES " + str(MatchCeremony.script().roundName).to_upper()
		FightHud.stamp(self, title, Vector2(size.x * 0.5, size.y * 0.42), 32, GuildTheme.BRASS)
		FightHud.centered(self, "Reset to run it back.", Vector2(size.x * 0.5, size.y * 0.42 + 63), 18, MUTED)
