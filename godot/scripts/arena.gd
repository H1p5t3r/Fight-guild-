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
var weapons: Array[HookWeapon] = []
var collision_layer: Control
var hud_layer: Control
var feedback := CombatFeedback.new()
var camera_zoom := 1.0
var camera_offset := Vector2.ZERO
var font := GuildTheme.SEMIBOLD
const ACCENT := Color("f4b45e")
const TEXT := Color("f0ede5")
const MUTED := Color("a3b8c7")

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	custom_minimum_size = Vector2(720, 430)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	clip_contents = true
	for _p in 2:
		var sprite := Sprite2D.new()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(sprite)
		sprites.append(sprite)
		var weapon := HookWeapon.new()
		add_child(weapon)
		weapons.append(weapon)
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
		if not view.is_empty():
			draw_wall_break()
			FightHud.draw(hud_layer, view, score, round_label, diagnostics))

func refresh(simulation: CombatModel, state: Dictionary, boxes: bool, frozen: bool) -> void:
	model = simulation
	view = state
	show_boxes = boxes
	paused = frozen
	feedback.refresh(view, size)
	var scale_x := size.x / 1000.0
	var floor_y := size.y - 76.0
	camera_zoom = feedback.zoom()
	var focus := Vector2(clampf(float(view.get("impactX", 50000)) / 100.0 * scale_x, size.x * 0.2, size.x * 0.8), clampf(floor_y - float(view.get("impactY", 8000)) / 100.0 * scale_x, 180, floor_y))
	camera_offset = focus * (1.0 - camera_zoom)
	for p in 2:
		var fighter: Dictionary = view.players[p]
		var sprite := sprites[p]
		var character := int(fighter.character)
		var phase: String = FighterArt.PHASES[int(fighter.posePhase)]
		var pose := int(fighter.poseIndex)
		FighterArt.apply(sprite, character, phase, pose, scale_x * camera_zoom, fighter.facing)
		sprite.position = screen_point(Vector2(fighter.x / 100.0 * scale_x, floor_y - fighter.y / 100.0 * scale_x))
		sprite.modulate = Color("ffa69a") if fighter.stun and not fighter.guarding else Color.WHITE
		weapons[p].visible = false
		if character == 4 and fighter.weaponVisible:
			var move := model.move(character, fighter.move)
			var origin := Vector2((fighter.x + fighter.facing * move.hitboxBack) / 100.0 * scale_x, floor_y - (fighter.y + move.bottom) / 100.0 * scale_x)
			var back := Vector2(fighter.weaponBackX / 100.0 * scale_x, floor_y - fighter.weaponBackY / 100.0 * scale_x)
			var tip := Vector2(fighter.weaponTipX / 100.0 * scale_x, floor_y - fighter.weaponTipY / 100.0 * scale_x)
			weapons[p].present(screen_point(origin), screen_point(back), screen_point(tip), fighter.facing, scale_x * camera_zoom)
	queue_redraw()
	hud_layer.queue_redraw()
	collision_layer.queue_redraw()

func screen_point(point: Vector2) -> Vector2:
	return camera_offset + point * camera_zoom

func label(value: String, point: Vector2, font_size: int = 14, color: Color = TEXT) -> void:
	draw_string(font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	draw_set_transform(camera_offset, 0.0, Vector2.ONE * camera_zoom)
	ArenaStage.draw(self, show_boxes, int(view.get("stage", 0)))
	draw_set_transform(Vector2.ZERO)
	var sx := size.x / 1000.0
	var floor_y := size.y - 76.0
	if view.is_empty():
		return
	# Draw in the stage background before the HUD and before child fighter sprites.
	feedback.draw(self)
	draw_walls()
	for p in 2:
		var fighter: Dictionary = view.players[p]
		var point := screen_point(Vector2(fighter.x / 100.0 * sx, floor_y - fighter.y / 100.0 * sx))
		var px := point.x
		var py := point.y
		if fighter.move >= 0:
			if diagnostics: label("%s · %df" % [CombatModel.MOVE_IDS[fighter.move], fighter.age], Vector2(px + 28, py - 10), 12)
		elif diagnostics:
			var status := "HITSTUN" if fighter.stun else "READY"
			if fighter.guarding:
				status = "GUARD BREAK" if fighter.guardBreak else "BLOCK · attacker %+df" % fighter.blockAdvantage
			elif fighter.faultless: status = "FAULTLESS"
			elif fighter.reaction == 1: status = "AIR REEL · %d%% gravity" % fighter.gravityPercent
			elif fighter.reaction == 2: status = "HARD DOWN" if fighter.knockdown == 2 else "SOFT DOWN · AUTO TECH"
			elif fighter.reaction == 3: status = "WAKEUP · %df" % fighter.recoveryTime
			elif fighter.reaction == 4: status = "WALL SPLAT · %df" % fighter.wallSplatTime
			elif fighter.reaction == 5: status = "HOOK PULL · %df" % fighter.pullTime
			elif fighter.prejumpTime: status = "PREJUMP · %df" % fighter.prejumpTime
			elif fighter.landingTime: status = "LANDING · %df" % fighter.landingTime
			elif fighter.running: status = "RUN"
			elif fighter.dashTicks: status = "STEP"
			if fighter.counterSlowTime: status += " · ½ SPEED %df" % fighter.counterSlowTime
			label(status, Vector2(clampf(px + 28, 12, size.x - 165), py - 10), 12, Color("f68b79") if fighter.guardBreak else MUTED)
		if fighter.positiveTime > 0:
			FightHud.centered(self, "POSITIVE BONUS", Vector2(size.x * (0.22 if p == 0 else 0.78), size.y - 96), 18, Color("a8e9b1"), 2)
		if fighter.faultless or (fighter.guarding and not fighter.guardBreak):
			var angle := 0.0 if fighter.facing == 1 else PI
			var guard_color := Color("75dcbc") if fighter.faultless else Color("89c3e0")
			draw_arc(Vector2(px, py - 70 * sx * camera_zoom), 58 * sx * camera_zoom, angle - 1.4, angle + 1.4, 24, guard_color, 5 if fighter.faultless else 2)
	if paused:
		FightHud.centered(self, "PAUSED", Vector2(size.x * 0.5, 151), 17, GuildTheme.BRASS)
	if diagnostics:
		FightHud.centered(self, "%05d · %s" % [view.frame, "STOP" if view.hitstop else "60HZ"], Vector2(size.x * 0.5, size.y - 9), 12, MUTED)
	if view.winner >= 0 and not presentation_active:
		var title: String = "DRAW" if view.winner == 2 else CombatModel.CHARACTERS[view.players[view.winner].character].to_upper() + " TAKES " + str(MatchCeremony.script().roundName).to_upper()
		FightHud.stamp(self, title, Vector2(size.x * 0.5, size.y * 0.42), 32, GuildTheme.BRASS)
		FightHud.centered(self, "Reset to run it back.", Vector2(size.x * 0.5, size.y * 0.42 + 63), 18, MUTED)

# Presentation reads fixed-tick state, so prediction corrections cannot leave stale effects.
func draw_walls() -> void:
	var threshold: int = model.config[model.config.size() - CombatModel.RULE_COUNT + 16]
	for fighter in view.players:
		if fighter.wallDamage == 0: continue
		var side := -1.0 if fighter.x < 50000 else 1.0
		var x := 12.0 if side < 0 else size.x - 12.0
		var pressure := clampf(float(fighter.wallDamage) / threshold, 0.0, 1.0)
		var center := Vector2(x, size.y - 155 - fighter.y / 100.0 * size.x / 1000.0)
		var color := Color("f4b45e") if fighter.reaction != 4 else Color("f5e3c5")
		draw_line(Vector2(x, 165), Vector2(x, size.y - 76), Color(color, 0.12 + pressure * 0.5), 2 + pressure * 4)
		for i in ceili(pressure * 7):
			var end := center + Vector2(-side * (20 + i % 3 * 15), (i - 3) * 24)
			var kink := center.lerp(end, 0.55) + Vector2(-side * 8, 7)
			draw_polyline(PackedVector2Array([center, kink, end]), Color(color, 0.2 + pressure * 0.7), 2, true)
		if fighter.reaction == 4:
			FightHud.stamp(self, "WALL SPLAT", Vector2(size.x * (0.24 if side < 0 else 0.76), 275), 23, ACCENT)

func draw_wall_break() -> void:
	if view.wallBreakTime <= 0: return
	var progress := 1.0 - float(view.wallBreakTime) / float(view.wallBreakDuration)
	var actor: int = view.wallBreakActor
	var tint: Color = FighterSelectPortrait.COLORS[view.players[actor].character]
	var side: int = view.wallBreakSide
	var origin := Vector2(0 if side < 0 else size.x, size.y * 0.55)
	var expansion := smoothstep(0.0, 0.7, progress)
	var fade := 1.0 - smoothstep(0.65, 1.0, progress)
	hud_layer.draw_rect(Rect2(Vector2.ZERO, size), Color("081219", 0.60 * fade))
	for i in 12:
		var distance := 35.0 + expansion * size.x * (0.25 + (i % 4) * 0.25)
		var point := origin + Vector2(-side * distance, (i - 5.5) * (14.0 + expansion * 60.0))
		var shard := PackedVector2Array([point, point + Vector2(-side * (32 + i * 4), -18), point + Vector2(-side * 14, 24)])
		hud_layer.draw_colored_polygon(shard, Color(tint.lightened(0.25), 0.65 * fade))
	var slide := Vector2(-side * (1.0 - smoothstep(0.0, 0.25, progress)) * 80.0, 0)
	FightHud.stamp(hud_layer, "WALL BREAK", size * Vector2(0.5, 0.43) + slide, int(clampf(size.x * 0.052, 30, 64)), tint, fade)
	var grants_bonus: bool = model.config[model.config.size() - CombatModel.RULE_COUNT + 23] > 0
	FightHud.centered(hud_layer, "POSITIVE BONUS" if grants_bonus else "NEUTRAL RESET", size * Vector2(0.5, 0.43) + Vector2(0, 75), 23, Color("a8e9b1", fade), 2)
	FightHud.centered(hud_layer, "NEXT GROUND", size * Vector2(0.5, 0.43) + Vector2(0, 106), 15, Color(TEXT, fade))
	# The core changes ground at two-thirds of the transition, under this curtain.
	var curtain := smoothstep(0.50, 0.65, progress) * (1.0 - smoothstep(0.68, 1.0, progress))
	hud_layer.draw_rect(Rect2(Vector2.ZERO, size), Color("081219", curtain))

# Draw the simulation's actual rectangles above the sprites, below the HUD.
func draw_collisions() -> void:
	if not show_boxes or view.is_empty() or model == null: return
	var sx := size.x / 100000.0
	var floor_y := size.y - 76.0
	collision_layer.draw_set_transform(camera_offset, 0.0, Vector2.ONE * camera_zoom)
	var colors := [Color("67d5ff"), Color("9ce56b"), Color("ff8859")]
	for p in 2:
		for kind in 3:
			var boxes: PackedInt32Array = model.core.boxes(p, kind)
			for i in range(0, boxes.size(), 4):
				var rect := Rect2(boxes[i] * sx, floor_y - boxes[i + 3] * sx, (boxes[i + 2] - boxes[i]) * sx, (boxes[i + 3] - boxes[i + 1]) * sx)
				var color: Color = colors[kind]
				collision_layer.draw_rect(rect, Color(color, 0.07 if kind == 0 else 0.12))
				collision_layer.draw_rect(rect, color, false, 1.0 if kind == 0 else 2.0)
	collision_layer.draw_set_transform(Vector2.ZERO)
	var left := 18.0
	for kind in 3:
		var caption: String = ["HURT · body", "PUSH · spacing", "HIT · active"][kind]
		collision_layer.draw_string(font, Vector2(left, 129), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, colors[kind])
		left += 145.0
