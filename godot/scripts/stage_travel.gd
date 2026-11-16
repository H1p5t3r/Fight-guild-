class_name StageTravel
extends RefCounted

const TRAVEL_WEIGHTS := [0.26, 0.72, 1.0]

# Every pose, layer and particle is a function of authoritative break ticks.
# No retained tween state: seeking, pausing and rollback reproduce the same view.
static func describe(state: Dictionary) -> Dictionary:
	var duration := maxi(1, int(state.get("wallBreakDuration", 150)))
	var remaining := int(state.get("wallBreakTime", 0))
	var active := remaining > 0
	var progress := clampf(float(duration - remaining) / duration, 0.0, 1.0) if active else 0.0
	var side := int(state.get("wallBreakSide", 1))
	if side == 0: side = 1
	var changed := active and remaining <= duration / 3
	var stage := int(state.get("stage", 0))
	var source := ArenaStage.next_stage(stage, -side) if changed else stage
	var target := stage if changed else ArenaStage.next_stage(stage, side)
	return {"active": active, "progress": progress, "side": side, "source": source, "target": target,
		"pan": smoothstep(0.14, 0.78, progress), "changed": changed, "actor": int(state.get("wallBreakActor", 0))}

static func source_camera(state: Dictionary, bounds: Vector2) -> Dictionary:
	var xs: Array = state.get("wallBreakX", [42000, 58000])
	var ys: Array = state.get("wallBreakY", [0, 0])
	var mock := {"players": [{"x": xs[0], "y": ys[0]}, {"x": xs[1], "y": ys[1]}]}
	return ArenaStage.camera(mock, bounds)

static func destination_camera(state: Dictionary, bounds: Vector2) -> Dictionary:
	var shot := describe(state)
	var xs := [42000, 58000] if shot.actor == int(shot.side < 0) else [58000, 42000]
	return ArenaStage.camera({"players": [{"x": xs[0]}, {"x": xs[1]}]}, bounds)

static func layer_offset(bounds: Vector2, layer: int, side: int, pan: float, incoming: bool) -> Vector2:
	return Vector2(bounds.x * TRAVEL_WEIGHTS[layer] * side * (1.0 - pan if incoming else -pan), 0)

static func draw_background(canvas: Control, state: Dictionary, reduced: bool) -> void:
	var shot := describe(state)
	var p: float = shot.progress
	var t: float = shot.pan
	var camera := source_camera(state, canvas.size)
	var destination := destination_camera(state, canvas.size)
	canvas.draw_rect(Rect2(Vector2.ZERO, canvas.size), Color("17252d"))
	if reduced:
		# A quiet dissolve keeps location readable without rapid camera motion or flight.
		var blend := smoothstep(0.38, 0.82, p)
		for layer in 3: ArenaStage.draw_plane(canvas, shot.source, layer, camera.center, camera.zoom, Vector2.ZERO, 1.0, false, camera.lift)
		ArenaStage.draw_boundaries(canvas, shot.source, camera.zoom, camera.offset, 0, 0.0, 1.0 - blend)
		for layer in 3: ArenaStage.draw_plane(canvas, shot.target, layer, destination.center, destination.zoom, Vector2.ZERO, blend, false, destination.lift)
		ArenaStage.draw_boundaries(canvas, shot.target, destination.zoom, destination.offset, 0, 0.0, blend)
		return
	for layer in 3:
		# Foreground travels fastest. Keep architecture overlap wide enough for the
		# narrower scenic view, instead of opening a vertical gap during the break.
		var source_offset := layer_offset(canvas.size, layer, shot.side, t, false)
		var target_offset := layer_offset(canvas.size, layer, shot.side, t, true)
		# Distant atmosphere crossfades; the architecture and floor pass laterally.
		var source_alpha := 1.0 - t if layer == 0 else 1.0 - smoothstep(0.72, 1.0, t)
		var target_alpha := t if layer == 0 else smoothstep(0.0, 0.28, t)
		ArenaStage.draw_plane(canvas, shot.source, layer, camera.center, camera.zoom, source_offset, source_alpha, layer > 0, camera.lift)
		ArenaStage.draw_plane(canvas, shot.target, layer, destination.center, destination.zoom, target_offset, target_alpha, layer > 0, destination.lift)
	if p < 0.28:
		ArenaStage.draw_boundaries(canvas, shot.source, camera.zoom, camera.offset, shot.side, smoothstep(0.02, 0.24, p))
	elif p > 0.76:
		ArenaStage.draw_boundaries(canvas, shot.target, destination.zoom, destination.offset)
	var alpha := smoothstep(0.08, 0.30, p) * (1.0 - smoothstep(0.65, 0.88, p))
	var between_outer: bool = shot.source != 0 and shot.target != 0
	var forge: bool = shot.source == 2 or shot.target == 2
	ArenaStage.portal(canvas, "forge-breach" if forge else "quay-breach", t, shot.side, alpha)
	if between_outer: ArenaStage.portal(canvas, "quay-breach", clampf(t + 0.2, 0.0, 1.0), shot.side, alpha * 0.65)

static func fighter(state: Dictionary, player: int, bounds: Vector2, reduced: bool) -> Dictionary:
	var shot := describe(state)
	var p: float = shot.progress
	var attacker: bool = player == shot.actor
	var floor_y := ArenaStage.floor_line(bounds)
	var final_x := bounds.x * (0.42 if attacker == (shot.side > 0) else 0.58)
	var camera := source_camera(state, bounds)
	var start := Vector2(float(state.wallBreakX[player]) / 100000.0 * bounds.x,
		floor_y - float(state.wallBreakY[player]) / 100000.0 * bounds.x)
	start = camera.offset + start * camera.zoom
	var destination := destination_camera(state, bounds)
	var finish: Vector2 = destination.offset + Vector2(final_x, floor_y) * destination.zoom
	if reduced:
		return {"position": finish if shot.changed else start,
			"scale": destination.zoom if shot.changed else camera.zoom, "angle": 0.0, "phase": -1, "pose": -1,
			"alpha": 1.0 - smoothstep(0.35, 0.57, p) if not shot.changed else smoothstep(0.70, 0.88, p)}
	var flight := smoothstep(0.06, 0.92, p)
	var arc := sin(flight * PI)
	var scale := lerpf(float(camera.zoom), float(destination.zoom), flight) * (1.0 - 0.32 * arc)
	var point := start.lerp(finish, flight)
	var headroom := maxf(0.0, point.y - ArenaStage.FRAME_HEAD_HEIGHT * bounds.x / 1000.0 * scale - FightHud.TOP_CLEARANCE * minf(bounds.x / 1248.0, 1.0))
	var lift := minf(arc * bounds.y * (0.25 if attacker else 0.34), headroom)
	point.y -= lift
	var phase := -1 if p < 0.10 else 0
	var pose := -1 if phase == -1 else (8 if attacker else 9) if p < 0.84 else 11 if p < 0.96 else 0
	var angle: float = shot.side * (0.10 if attacker else 0.35) * sin(flight * PI)
	return {"position": point, "scale": scale, "angle": angle, "phase": phase, "pose": pose, "alpha": 1.0}

static func draw_front(canvas: Control, state: Dictionary, reduced: bool) -> void:
	var shot := describe(state)
	var p: float = shot.progress
	var side: int = shot.side
	if not reduced:
		# Generated fragments: a deterministic burst, then a sparse trail across the passage.
		var fly := clampf((p - 0.02) / 0.75, 0.0, 1.0)
		var opacity := smoothstep(0.0, 0.04, p) * (1.0 - smoothstep(0.58, 0.90, p))
		for i in 14:
			var tile: int = (i % 4) if shot.source != 1 else [3, 2, 5, 7][i % 4]
			if i > 10: tile = 6 if shot.target == 2 else 7
			var source := ArenaStage.tile("debris-kit.png", tile, 4)
			var start_x := canvas.size.x * (0.96 if side > 0 else 0.04)
			var speed := 0.38 + float(i % 5) * 0.17
			var point := Vector2(start_x - side * fly * canvas.size.x * speed,
				canvas.size.y * (0.48 + float(i % 4) * 0.07) - sin(fly * PI) * (35 + i * 11) + fly * fly * 140)
			var extent := Vector2(30 + (i % 4) * 15, 42 + (i % 4) * 21) * canvas.size.x / 1280.0
			canvas.draw_set_transform(point, side * fly * (i % 3 + 1))
			canvas.draw_texture_rect(source, Rect2(-extent * 0.5, extent), false, Color(1, 1, 1, opacity * 0.85))
		canvas.draw_set_transform(Vector2.ZERO)
	var break_alpha := (1.0 - smoothstep(0.26, 0.48, p)) * 0.85
	FightHud.stamp(canvas, "WALL BREAK", canvas.size * Vector2(0.5, 0.25), int(clampf(canvas.size.x * 0.043, 30, 60)), ArenaStage.COLORS[shot.source], break_alpha)
	var arrive := smoothstep(0.68, 0.82, p) * (1.0 - smoothstep(0.96, 1.0, p))
	FightHud.stamp(canvas, ArenaStage.NAMES[shot.target], canvas.size * Vector2(0.5, 0.27), int(clampf(canvas.size.x * 0.035, 25, 48)), ArenaStage.COLORS[shot.target], arrive)
