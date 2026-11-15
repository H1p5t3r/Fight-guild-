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
var collision_layer: Control
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
	collision_layer = Control.new()
	collision_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	collision_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(collision_layer)
	collision_layer.draw.connect(draw_collisions)
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
		var character := int(fighter.character)
		var phase: String = ["active", "windup", "block"][int(fighter.posePhase)]
		var pose := int(fighter.poseIndex)
		FighterArt.apply(sprite, character, phase, pose, scale_x, fighter.facing)
		sprite.position = Vector2(fighter.x / 100.0 * scale_x, floor_y - fighter.y / 100.0 * scale_x)
		sprite.modulate = Color("ffa69a") if fighter.stun and not fighter.guarding else Color.WHITE
	queue_redraw()
	hud_layer.queue_redraw()
	collision_layer.queue_redraw()

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
		if fighter.move >= 0:
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

# Draw the simulation's actual rectangles above the sprites, below the HUD.
func draw_collisions() -> void:
	if not show_boxes or view.is_empty() or model == null: return
	var sx := size.x / 100000.0
	var floor_y := size.y - 76.0
	var colors := [Color("67d5ff"), Color("9ce56b"), Color("ff8859")]
	for p in 2:
		for kind in 3:
			var boxes: PackedInt32Array = model.core.boxes(p, kind)
			for i in range(0, boxes.size(), 4):
				var rect := Rect2(boxes[i] * sx, floor_y - boxes[i + 3] * sx, (boxes[i + 2] - boxes[i]) * sx, (boxes[i + 3] - boxes[i + 1]) * sx)
				var color: Color = colors[kind]
				collision_layer.draw_rect(rect, Color(color, 0.07 if kind == 0 else 0.12))
				collision_layer.draw_rect(rect, color, false, 1.0 if kind == 0 else 2.0)
	var left := 18.0
	for kind in 3:
		var caption: String = ["HURT · body", "PUSH · spacing", "HIT · active"][kind]
		collision_layer.draw_string(font, Vector2(left, 129), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, colors[kind])
		left += 145.0
