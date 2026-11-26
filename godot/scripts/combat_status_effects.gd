class_name CombatStatusEffects
extends RefCounted

# Stateless presentation: saved status timers own every pulse and droplet.
# Repainting, pause, prediction correction and replay cannot leave stale particles.
const DIRECTORY := "res://assets/effects/status-v1/"
const BLOOD := Color("ed4268")
const LINE := Color("77e0df")
const PAPER := Color("fff1d6")
const INK := Color("071b2b")
static var textures := {}
static var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY + "manifest.json"))

static func describe(state: Dictionary, reduced: bool = false) -> Array:
	var result := []
	if state.is_empty() or int(state.get("wallBreakTime", 0)) > 0: return result
	for p in state.players.size():
		var target: Dictionary = state.players[p]
		if int(target.get("bleedTime", 0)) > 0 and int(target.get("bleedSource", 0)) > 0:
			var remaining := int(target.bleedTime)
			result.append({"kind":"bleed", "player":p, "owner":1-p, "time":remaining,
				"clock":0 if reduced else -remaining, "grey":int(target.get("greyLife", 0)),
				"pulse":0.35 if reduced else maxf(0.0, 1.0 - float(target.get("bleedClock", 0)) / 12.0),
				"alpha":0.60 + 0.40 * minf(1.0, remaining / 24.0), "reduced":reduced})
		var pulling := int(target.get("linePullTime", 0)) > 0
		if int(target.get("tetherSource", 0)) > 0 or pulling:
			var remaining := int(target.get("linePullTime", 0) if pulling else target.get("tetherTime", 0))
			result.append({"kind":"tether", "player":p, "owner":1-p, "time":remaining,
				"clock":0 if reduced else -remaining, "pulling":pulling, "reduced":reduced,
				"alpha":1.0 if pulling or remaining == 0 else 0.65 + 0.35 * minf(1.0, remaining / 24.0)})
	return result

static func texture(name: String) -> AtlasTexture:
	if not textures.has(name):
		var result := AtlasTexture.new()
		result.atlas = load(DIRECTORY + str(catalog.file))
		var rect: Array = catalog.frames[name].region
		result.region = Rect2(rect[0], rect[1], rect[2], rect[3])
		result.filter_clip = true
		textures[name] = result
	return textures[name]

static func icon(canvas: CanvasItem, name: String, point: Vector2, height: float, alpha: float, angle: float = 0.0) -> void:
	var art := texture(name)
	var extent := art.get_size() * height / art.get_height()
	canvas.draw_set_transform(point, angle)
	canvas.draw_texture_rect(art, Rect2(-extent * 0.5, extent), false, Color(1, 1, 1, alpha))
	canvas.draw_set_transform(Vector2.ZERO)

static func body_anchor(model: CombatModel, fighter: Dictionary, sprite: Sprite2D, scale: float) -> Vector2:
	# Unmasked torso geometry: a 6P's upper-body invulnerability must not move
	# the status to its surviving leg box. Weapons never contribute an anchor.
	var boxes: PackedInt32Array = model.core.pose_boxes(int(fighter.character), int(fighter.posePhase), int(fighter.poseIndex))
	var local := Vector2(0, -78)
	if boxes.size() >= 8:
		local = Vector2((boxes[4] + boxes[6]) / 200.0, -(boxes[5] + boxes[7]) / 200.0)
	elif boxes.size() >= 4:
		local = Vector2((boxes[0] + boxes[2]) / 200.0, -(boxes[1] + boxes[3]) / 200.0)
	local.x *= int(fighter.facing)
	return sprite.position + local * scale

static func place(cues: Array, model: CombatModel, state: Dictionary, sprites: Array, scale: float, floor_y: float) -> Array:
	var result := []
	for cue in cues:
		var placed: Dictionary = cue.duplicate()
		var p := int(cue.player)
		placed.point = body_anchor(model, state.players[p], sprites[p], scale)
		placed.floor_y = floor_y
		if cue.kind == "tether":
			placed.start = body_anchor(model, state.players[int(cue.owner)], sprites[int(cue.owner)], scale)
		result.append(placed)
	return result

static func line_point(cue: Dictionary, t: float, scale: float) -> Vector2:
	var sag := 0.0 if cue.pulling else 9.0 * scale
	if not cue.reduced and not cue.pulling: sag += 1.5 * scale * sin(float(cue.clock) * TAU / 90.0)
	return Vector2(cue.start).lerp(cue.point, t) + Vector2(0, sag * 4.0 * t * (1.0 - t))

static func draw_behind(canvas: CanvasItem, cues: Array, scale: float) -> void:
	for cue in cues:
		if cue.kind != "tether": continue
		var distance: float = Vector2(cue.start).distance_to(cue.point)
		if distance < scale: continue
		var points := PackedVector2Array()
		for i in 25: points.append(line_point(cue, i / 24.0, scale))
		var thickness := (5.4 if cue.pulling else 4.1) * scale
		canvas.draw_polyline(points, Color(INK, cue.alpha), thickness + 3.0 * scale, true)
		canvas.draw_polyline(points, Color(LINE, float(cue.alpha) * 0.8), thickness, true)
		# Short original-art sections follow the curve; never stretch one braid
		# across the entire stage or use an independent rope physics simulation.
		var pieces := clampi(ceili(distance / (48.0 * scale)), 2, 18)
		for i in pieces:
			var a := line_point(cue, float(i) / pieces, scale)
			var b := line_point(cue, float(i + 1) / pieces, scale)
			canvas.draw_set_transform(a, (b - a).angle())
			canvas.draw_texture_rect(texture("cord"), Rect2(0, -thickness * 0.5, a.distance_to(b) + 0.6, thickness), false, Color(1, 1, 1, cue.alpha))
		canvas.draw_set_transform(Vector2.ZERO)

static func draw_front(canvas: CanvasItem, cues: Array, scale: float) -> void:
	for cue in cues:
		var point: Vector2 = cue.point
		if cue.kind == "bleed":
			# A compact persistent wound, not another hit spark or a fighter tint.
			icon(canvas, "wound", point, (32.0 + float(cue.pulse) * 2.5) * scale, (0.77 + float(cue.pulse) * 0.18) * float(cue.alpha))
			for i in 3:
				var progress := fposmod(float(cue.clock) + i * 16.0, 48.0) / 48.0
				if cue.reduced: progress = 0.25 + i * 0.19
				var offset := Vector2([-15.0, 9.0, 21.0][i], 9.0 + 45.0 * progress * progress) * scale
				var alpha := float(cue.alpha) * 0.80 * (1.0 - smoothstep(0.62, 1.0, progress))
				var height := (8.0 + i * 1.5) * scale
				# Prone wounds sit close to the floor. Fade before the droplet's
				# lower edge reaches it, rather than falling through toward the HUD.
				alpha *= clampf((float(cue.floor_y) - point.y - offset.y - height * 0.5) / (8.0 * scale), 0.0, 1.0)
				if alpha > 0.0: icon(canvas, "drop", point + offset, height, alpha)
		else:
			var pulse := 0.0 if cue.reduced else sin(float(cue.clock) * TAU / (12.0 if cue.pulling else 60.0))
			icon(canvas, "hook", point, (39.0 + pulse * (1.8 if cue.pulling else 0.7)) * scale, cue.alpha)
			# Pull pulses travel from the marked target back to its owner. The
			# attached-but-idle state has no directional arrows implying motion.
			if cue.pulling:
				for i in 2:
					var progress := 0.32 + i * 0.34 if cue.reduced else fposmod(-float(cue.clock) / 10.0 + i * 0.5, 1.0)
					var a := line_point(cue, clampf(progress - 0.02, 0, 1), scale)
					var b := line_point(cue, clampf(progress + 0.02, 0, 1), scale)
					icon(canvas, "reel", line_point(cue, progress, scale), 12.0 * scale, 0.95, (b - a).angle())

static func draw_hud(canvas: CanvasItem, cues: Array, player: int, edge: Vector2, right: bool) -> void:
	var offset := 0.0
	for cue in cues:
		if int(cue.player) != player: continue
		var bleed: bool = cue.kind == "bleed"
		var color := BLOOD if bleed else LINE
		var caption := "BLEED  %d" % cue.grey if bleed else "REELING" if cue.pulling else "TETHERED"
		var width := 136.0 if bleed else 142.0
		var origin := edge + Vector2(-offset - width if right else offset, 0)
		var shape := PackedVector2Array([origin + Vector2(7, 0), origin + Vector2(width, 0), origin + Vector2(width - 7, 23), origin + Vector2(0, 23)])
		canvas.draw_colored_polygon(shape, Color(INK, 0.82))
		canvas.draw_line(origin + Vector2(4, 23), origin + Vector2(width - 8, 23), Color(color, 0.92), 2, true)
		# Keep the caller's HUD transform intact; icon() intentionally resets it.
		canvas.draw_texture_rect(texture("bleed_icon" if bleed else "hook"), Rect2(origin + Vector2(6, 1), Vector2(21, 21)), false)
		canvas.draw_string(CombatTypography.FONT, origin + Vector2(32, 17), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, PAPER)
		offset += width + 7
