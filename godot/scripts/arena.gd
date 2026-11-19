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
var camera_center := 0.5
var stage_zoom := 1.0
var stage_lift := 0.0
var camera_accent := 1.0
var accent_offset := Vector2.ZERO
var camera_zoom := 1.0
var camera_offset := Vector2.ZERO
var font := GuildTheme.SEMIBOLD
const PROJECTILE_ART = preload("res://assets/fighters/appearance-v3/projectiles.png")
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
			ArenaStage.draw_footer(hud_layer, int(view.stage), not diagnostics)
			FightHud.draw(hud_layer, view, score, round_label, diagnostics))

func refresh(simulation: CombatModel, state: Dictionary, boxes: bool, frozen: bool) -> void:
	model = simulation
	view = state
	show_boxes = boxes
	paused = frozen
	feedback.refresh(view, size)
	# Reorder only this arena's fighter children so menus keep their own layering.
	var draw_order := [1, 0] if int(view.get("foregroundPlayer", -1)) == 0 else [0, 1]
	for depth in 2:
		var p: int = draw_order[depth]
		if sprites[p].get_index() != depth * 2: move_child(sprites[p], depth * 2)
		if weapons[p].get_index() != depth * 2 + 1: move_child(weapons[p], depth * 2 + 1)
	var scale_x := size.x / 1000.0
	var floor_y := ArenaStage.floor_line(size)
	var travel := int(view.wallBreakTime) > 0
	var camera := ArenaStage.camera(view, size, feedback.reduced_motion)
	camera_center = camera.center
	camera_zoom = camera.zoom
	stage_zoom = camera.zoom
	stage_lift = camera.get("lift", 0.0)
	camera_accent = 1.0
	accent_offset = Vector2.ZERO
	camera_offset = camera.offset
	if not travel:
		var accent := feedback.zoom()
		var focus := screen_point(Vector2(clampf(float(view.get("impactX", 50000)) / 100.0 * scale_x, size.x * 0.2, size.x * 0.8), clampf(floor_y - float(view.get("impactY", 8000)) / 100.0 * scale_x, 180, floor_y)))
		camera_accent = accent
		accent_offset = focus * (1.0 - accent)
		camera_offset = accent_offset + camera_offset * accent
		camera_zoom *= accent
	for p in 2:
		var fighter: Dictionary = view.players[p]
		var sprite := sprites[p]
		var character := int(fighter.character)
		var phase: String = FighterArt.PHASES[int(fighter.posePhase)]
		var pose := int(fighter.poseIndex)
		var shot := StageTravel.fighter(view, p, size, feedback.reduced_motion) if travel else {}
		if travel and int(shot.phase) >= 0:
			phase = FighterArt.PHASES[int(shot.phase)]
			pose = int(shot.pose)
		FighterArt.apply(sprite, character, phase, pose, scale_x * (float(shot.scale) if travel else camera_zoom), fighter.facing, -1 if travel else int(fighter.idleTime))
		sprite.position = shot.position if travel else screen_point(Vector2(fighter.x / 100.0 * scale_x, floor_y - fighter.y / 100.0 * scale_x))
		sprite.rotation = float(shot.angle) if travel else 0.0
		sprite.modulate = Color(1, 1, 1, shot.alpha) if travel else Color("ffa69a") if fighter.stun and not fighter.guarding else Color.WHITE
		weapons[p].visible = false
		if not travel and character == 4 and fighter.weaponVisible:
			var move := model.move(character, fighter.move)
			var origin := Vector2((fighter.x + fighter.facing * move.hitboxBack) / 100.0 * scale_x, floor_y - (fighter.y + move.bottom) / 100.0 * scale_x)
			var back := Vector2(fighter.weaponBackX / 100.0 * scale_x, floor_y - fighter.weaponBackY / 100.0 * scale_x)
			var tip := Vector2(fighter.weaponTipX / 100.0 * scale_x, floor_y - fighter.weaponTipY / 100.0 * scale_x)
			weapons[p].present(screen_point(origin), screen_point(back), screen_point(tip), fighter.facing, scale_x * camera_zoom)
	queue_redraw()
	hud_layer.queue_redraw()
	collision_layer.queue_redraw()

func draw_projectiles() -> void:
	if view.is_empty() or int(view.wallBreakTime) > 0: return
	var sx := size.x / 1000.0
	var floor_y := ArenaStage.floor_line(size)
	for q in view.get("projectiles", []):
		var from := screen_point(Vector2((q.x - q.width * 0.5) / 100.0 * sx, floor_y - (q.y + q.height * 0.5) / 100.0 * sx))
		var extent := Vector2(q.width, q.height) / 100.0 * sx * camera_zoom
		var target := Rect2(from, extent)
		if int(q.facing) < 0: target.position.x += extent.x; target.size.x = -extent.x
		var source := Rect2(797, 350, 708, 390) if int(q.kind) == 2 else Rect2(28, 326, 695, 432)
		var art: Texture2D = PROJECTILE_ART
		var custom: Dictionary = FighterArt.projectile_art(int(view.players[int(q.owner)].character), int(q.move), int(q.life), int(q.age))
		if not custom.is_empty():
			var path: String = FighterArt.DIRECTORY + custom.file
			if not FighterArt.textures.has(custom.file): FighterArt.textures[custom.file] = load(path)
			art = FighterArt.textures[custom.file]
			var r: Array = custom.region
			source = Rect2(r[0], r[1], r[2], r[3])
		draw_texture_rect_region(art, target, source)

func screen_point(point: Vector2) -> Vector2:
	return camera_offset + point * camera_zoom

func label(value: String, point: Vector2, font_size: int = 14, color: Color = TEXT) -> void:
	draw_string(font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	if int(view.get("wallBreakTime", 0)) > 0:
		StageTravel.draw_background(self, view, feedback.reduced_motion)
		return
	draw_set_transform(accent_offset, 0.0, Vector2.ONE * camera_accent)
	ArenaStage.draw(self, show_boxes, int(view.get("stage", 0)), camera_center, stage_zoom, stage_lift)
	draw_set_transform(Vector2.ZERO)
	ArenaStage.draw_boundaries(self, int(view.get("stage", 0)), camera_zoom, camera_offset)
	var sx := size.x / 1000.0
	var floor_y := ArenaStage.floor_line(size)
	if view.is_empty():
		return
	draw_ground_shadows()
	draw_projectiles()
	for p in 2:
		var target: Dictionary = view.players[p]
		var owner: Dictionary = view.players[1-p]
		if target.get("tetherSource", 0) > 0 or target.get("linePullTime", 0) > 0:
			var start := screen_point(Vector2(owner.x / 100.0 * sx, floor_y - (owner.y / 100.0 + 85) * sx))
			var end := screen_point(Vector2(target.x / 100.0 * sx, floor_y - (target.y / 100.0 + 70) * sx))
			if FighterArt.catalog().fighters[owner.character].has("line_fx"):
				var cord := FighterArt.texture(owner.character, "line_fx", 4)
				draw_set_transform(start, (end - start).angle())
				var thickness := 3.3 * sx * camera_zoom
				draw_texture_rect(cord, Rect2(0, -thickness / 2, start.distance_to(end), thickness), false)
				draw_set_transform(Vector2.ZERO)
				if target.tetherSource > 0:
					var seal := FighterArt.texture(owner.character, "line_fx", 3)
					var diameter := 26 * sx * camera_zoom
					draw_texture_rect(seal, Rect2(end - Vector2.ONE * diameter / 2, Vector2.ONE * diameter), false, Color(1, 1, 1, 0.86))
			else:
				draw_line(start, end, Color("57bcca", 0.8), 2.5, true)
	# Draw in the stage background before the HUD and before child fighter sprites.
	feedback.draw(self)
	draw_walls()
	for p in 2:
		var fighter: Dictionary = view.players[p]
		var point := screen_point(Vector2(fighter.x / 100.0 * sx, floor_y - fighter.y / 100.0 * sx))
		var px := point.x
		var py := point.y
		if fighter.get("bleedTime", 0) > 0:
			label("BLEED · %d GREY" % fighter.greyLife, Vector2(px - 52, py - 185 * sx * camera_zoom), 13, Color("eba4b6"))
		elif fighter.get("tetherSource", 0) > 0:
			label("LINE · %.1fs" % (fighter.get("tetherTime", 0) / 60.0) if fighter.get("tetherTime", 0) > 0 else "TETHER · PULLED" if fighter.tetherUsed else "TETHER", Vector2(px - 40, py - 185 * sx * camera_zoom), 13, Color("79d3df"))
		if fighter.move >= 0:
			if diagnostics: label("%s · %df" % [model.move_name(fighter.character, fighter.move), fighter.age], Vector2(px + 28, py - 10), 12)
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
			elif fighter.dashTicks: status = "AIR DASH PAUSE" if fighter.y > 0 and fighter.dashAge == 0 else "AIR DASH" if fighter.y > 0 else "STEP"
			if fighter.counterSlowTime: status += " · ½ SPEED %df" % fighter.counterSlowTime
			label(status, Vector2(clampf(px + 28, 12, size.x - 165), py - 10), 12, Color("f68b79") if fighter.guardBreak else MUTED)
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
	# Wall health is intentionally hidden. Only a pinned fighter announces a splat.
	for fighter in view.players:
		if fighter.reaction != 4: continue
		var side := -1 if fighter.x < 50000 else 1
		FightHud.stamp(self, "WALL SPLAT", Vector2(size.x * (0.24 if side < 0 else 0.76), 275), 23, ACCENT)

func draw_wall_break() -> void:
	if view.wallBreakTime <= 0: return
	StageTravel.draw_front(hud_layer, view, feedback.reduced_motion)
	var progress: float = StageTravel.describe(view).progress
	var arrival := smoothstep(0.72, 0.85, progress) * (1.0 - smoothstep(0.96, 1.0, progress))
	var grants_bonus: bool = model.config[model.config.size() - CombatModel.RULE_COUNT + 23] > 0
	FightHud.centered(hud_layer, "POSITIVE BONUS" if grants_bonus else "NEUTRAL RESET", size * Vector2(0.5, 0.27) + Vector2(0, 60), 18, Color("a8e9b1", arrival), 2)

# Draw the simulation's actual rectangles above the sprites, below the HUD.
func draw_collisions() -> void:
	if not show_boxes or view.is_empty() or model == null or int(view.wallBreakTime) > 0: return
	var sx := size.x / 100000.0
	var floor_y := ArenaStage.floor_line(size)
	collision_layer.draw_set_transform(camera_offset, 0.0, Vector2.ONE * camera_zoom)
	var colors := [Color("67d5ff"), Color("9ce56b"), Color("ff8859")]
	for p in 2:
		for kind in [0, 1, 2, 4]:
			var boxes: PackedInt32Array = model.core.boxes(p, kind)
			for i in range(0, boxes.size(), 4):
				var rect := Rect2(boxes[i] * sx, floor_y - boxes[i + 3] * sx, (boxes[i + 2] - boxes[i]) * sx, (boxes[i + 3] - boxes[i + 1]) * sx)
				var color: Color = Color("d7a7ff") if kind == 4 else colors[kind]
				collision_layer.draw_rect(rect, Color(color, 0.07 if kind == 0 else 0.12))
				collision_layer.draw_rect(rect, color, false, 1.0 if kind == 0 else 2.0)
	var walls: PackedInt32Array = model.core.boxes(-1, 3)
	for i in range(0, walls.size(), 4):
		var wall := Rect2(walls[i] * sx, floor_y - walls[i + 3] * sx, (walls[i + 2] - walls[i]) * sx, (walls[i + 3] - walls[i + 1]) * sx)
		collision_layer.draw_rect(wall, Color("d49cf7", 0.12))
		collision_layer.draw_rect(wall, Color("d49cf7", 0.8), false, 2.0)
	collision_layer.draw_set_transform(Vector2.ZERO)
	collision_layer.draw_string(font, Vector2(460, 129), "WALL · boundary", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("d49cf7"))
	var left := 18.0
	for kind in 3:
		var caption: String = ["HURT · body", "PUSH · spacing", "HIT · active"][kind]
		collision_layer.draw_string(font, Vector2(left, 129), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, colors[kind])
		left += 145.0

func draw_ground_shadows() -> void:
	# Read the lowest body hurtbox, never the weapon or extended attack rectangle.
	# The shadow stays on the world floor and softens as the body leaves it.
	var sx := size.x / 100000.0
	for p in 2:
		var fighter: Dictionary = view.players[p]
		var boxes: PackedInt32Array = model.core.boxes(p, 0)
		if boxes.is_empty(): continue
		var leg := 0
		for i in range(4, boxes.size(), 4):
			if boxes[i + 1] < boxes[leg + 1]: leg = i
		var ground := screen_point(Vector2((boxes[leg] + boxes[leg + 2]) * 0.5 * sx, ArenaStage.floor_line(size)))
		var height := maxf(0, float(fighter.y) / 100.0)
		var width := clampf((boxes[leg + 2] - boxes[leg]) / 200.0, 20.0, 60.0)
		var spread := 1.0 + minf(height / 300.0, 0.5)
		var radius := Vector2(width * spread * 1.15, 5.0 * spread) * size.x / 1000.0 * camera_zoom
		draw_set_transform(ground, 0, radius)
		for ring in 7:
			draw_circle(Vector2.ZERO, 1.0 - ring * 0.10, Color("080d16", 0.075 / (1.0 + height / 120.0)), true, -1, true)
		draw_set_transform(Vector2.ZERO)
		if height < 8.0:
			for side in [-1, 1]:
				var foot: Vector2 = ground + Vector2(side * radius.x * 0.68, 0)
				draw_set_transform(foot, 0, Vector2(radius.x * 0.36, radius.y * 0.55))
				for ring in 4:
					draw_circle(Vector2.ZERO, 1.0 - ring * 0.16, Color("080d16", 0.11 * (1.0 - height / 8.0)), true, -1, true)
				draw_set_transform(Vector2.ZERO)
