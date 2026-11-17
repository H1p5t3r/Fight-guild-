extends SceneTree

var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; printerr(message)
func _initialize() -> void: call_deferred("run")

func run() -> void:
	var neutral := {"players": [{"x": 42000, "y": 0}, {"x": 58000, "y": 0}]}
	var bounds := Vector2(1280, 720)
	var close := ArenaStage.camera(neutral, bounds)
	for character in [4, 5]:
		var sprite := Sprite2D.new()
		FighterArt.apply(sprite, character, "active", 0, bounds.x / 1000.0 * close.zoom, 1)
		var art: Dictionary = FighterArt.sheet(character)
		var silhouette: Array = art.frames[0].bounds
		var height: float = (silhouette[3] - silhouette[1]) * sprite.scale.y
		check(height / bounds.y >= 0.59 and height / bounds.y <= 0.62, "Neutral silhouette misses the supplied ~60% screen-height reference")
		# The new low Stalker stance must bend at the same anatomical scale,
		# rather than stretching back to the upright character's screen height.
		FighterArt.apply(sprite, character, "ready", 0, bounds.x / 1000.0 * close.zoom, 1)
		var ready: Dictionary = FighterArt.sheet(character, "ready")
		var ready_bounds: Array = ready.frames[0].bounds
		var ready_height: float = (ready_bounds[3] - ready_bounds[1]) * sprite.scale.y / bounds.y
		check(ready_height >= (0.48 if character == 5 else 0.59) and ready_height <= (0.52 if character == 5 else 0.62), "New stance changed anatomical scale or camera composition")
		check(ArenaStage.floor_line(bounds) / bounds.y > 0.91, "Floor is still raised onto a HUD panel")
		sprite.free()
	# World projection at match, practice, editor and wider window sizes.
	for area in [bounds, Vector2(1248, 642), Vector2(720, 430), Vector2(1884, 992), Vector2(1884, 722)]:
		for xs in [[42000, 58000], [1800, 9000], [91000, 98200], [1800, 98200], [58000, 42000]]:
			for ys in [[0, 0], [13000, 0], [0, 30000], [60000, 60000]]:
				var state := {"players": [{"x": xs[0], "y": ys[0]}, {"x": xs[1], "y": ys[1]}]}
				var camera := ArenaStage.camera(state, area)
				check(camera == ArenaStage.camera(state, area, true), "Accessibility preference changes essential framing")
				for p in 2:
					var feet: Vector2 = camera.offset + Vector2(xs[p] * area.x / 100000.0, ArenaStage.floor_line(area) - ys[p] * area.x / 100000.0) * camera.zoom
					var body_half_width: float = 65.0 * area.x / 1000.0 * camera.zoom
					var head_y: float = feet.y - 152.0 * area.x / 1000.0 * camera.zoom
					check(feet.x - body_half_width >= -0.01 and feet.x + body_half_width <= area.x + 0.01, "Fighter leaves a horizontal screen edge: %s at %s" % [area, xs])
					check(head_y >= FightHud.TOP_CLEARANCE * minf(area.x / 1248.0, 1.0) - 0.01 and feet.y <= ArenaStage.floor_line(area) + 0.01, "Airborne body leaves the fighting area")
				var floor_rect := ArenaStage.layer_rect(area, Vector2(1536, 1024), 1.0, camera.center, camera.zoom, camera.lift)
				var wall_left := ArenaStage.wall_rect(area, -1, camera.zoom, camera.offset).end.x
				var wall_right := ArenaStage.wall_rect(area, 1, camera.zoom, camera.offset).position.x
				check(floor_rect.position.x <= wall_left + 0.01 and floor_rect.end.x >= wall_right - 0.01, "Floor ends inside the playable space")
				# A landmark on the floor must have the same projection as the same
				# point in combat space. This catches zoom caps AND pan/overscan drift.
				for world_x in [100.0, 500.0, 900.0]:
					var u: float = 0.5 + (world_x - 500.0) / ArenaStage.SCENE_WORLD_WIDTH
					var actual := floor_rect.position + floor_rect.size * Vector2(u, ArenaStage.SCENE_BASELINE)
					var expected: Vector2 = camera.offset + Vector2(world_x * area.x / 1000.0, ArenaStage.floor_line(area)) * camera.zoom
					check(actual.distance_to(expected) < 0.02, "Floor landmark slides or scales independently of combat space")
				var middle := ArenaStage.layer_rect(area, Vector2(1536, 1024), 0.54, camera.center, camera.zoom, camera.lift)
				check(absf(middle.position.y + middle.size.y * 735.0 / 1024.0 - floor_rect.position.y - floor_rect.size.y * 735.0 / 1024.0) < 0.02, "Architecture detached from the floor")
	var model := CombatModel.new()
	model.reset([5, 4])
	for _tick in 22: model.step(8, 0)
	var air := ArenaStage.camera(model.state(), bounds)
	check(air.zoom < close.zoom, "Real jump does not create headroom")
	var standing_floor := ArenaStage.layer_rect(bounds, Vector2(1536, 1024), 1.0, close.center, close.zoom)
	var jumping_floor := ArenaStage.layer_rect(bounds, Vector2(1536, 1024), 1.0, air.center, air.zoom)
	check(absf(jumping_floor.size.x / standing_floor.size.x - air.zoom / close.zoom) < 0.001, "A jump shrinks the fighter without shrinking nearby scenery")
	var shared_air := ArenaStage.camera({"players": [{"x": 42000, "y": 60000}, {"x": 58000, "y": 60000}]}, bounds)
	check(shared_air.zoom >= close.zoom * 0.9 and shared_air.lift > 0, "Shared air height needlessly shrinks both fighters")
	var saved := model.core.snapshot()
	for _tick in 40: model.step(0, 0)
	check(model.core.restore(saved) and air == ArenaStage.camera(model.state(), bounds), "Restored simulation has stale camera easing")
	print("Camera composition, shared floor projection, corner/air visibility and rollback: ", failures, " failures")
	quit(int(failures != 0))
