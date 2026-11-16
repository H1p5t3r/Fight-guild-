extends SceneTree

var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; printerr(message)
func _initialize() -> void: call_deferred("run")

func run() -> void:
	var neutral := {"players": [{"x": 42000, "y": 0}, {"x": 58000, "y": 0}]}
	var bounds := Vector2(1248, 642)
	var close := ArenaStage.camera(neutral, bounds)
	for character in [4, 5]:
		var sprite := Sprite2D.new()
		FighterArt.apply(sprite, character, "active", 0, bounds.x / 1000.0 * close.zoom, 1)
		var art: Dictionary = FighterArt.sheet(character)
		var silhouette: Array = art.frames[0].bounds
		var height: float = (silhouette[3] - silhouette[1]) * sprite.scale.y
		check(height / 720.0 >= 0.57 and height / 720.0 <= 0.61, "Neutral silhouette misses the supplied ~60% screen-height reference")
		sprite.free()
	# Visibility/coverage contract across match, training, editor and wider windows.
	for area in [bounds, Vector2(1404, 722), Vector2(720, 430), Vector2(1884, 992), Vector2(1884, 722)]:
		for xs in [[42000, 58000], [1800, 9000], [91000, 98200], [1800, 98200], [58000, 42000]]:
			for ys in [[0, 0], [13000, 0], [0, 30000], [60000, 60000]]:
				var state := {"players": [{"x": xs[0], "y": ys[0]}, {"x": xs[1], "y": ys[1]}]}
				var camera := ArenaStage.camera(state, area)
				check(camera == ArenaStage.camera(state, area, true), "Accessibility preference shrinks the fighters")
				for p in 2:
					var feet: Vector2 = camera.offset + Vector2(xs[p] * area.x / 100000.0, area.y - 76 - ys[p] * area.x / 100000.0) * camera.zoom
					var body_half_width: float = 65.0 * area.x / 1000.0 * camera.zoom
					var head_y: float = feet.y - 152.0 * area.x / 1000.0 * camera.zoom
					check(feet.x - body_half_width >= -0.01 and feet.x + body_half_width <= area.x + 0.01, "Fighter body leaves a horizontal screen edge")
					check(head_y >= 135.0 * minf(area.x / 1248.0, 1.0) and feet.y <= area.y - 75.99, "Airborne head or feet leave the fighting area")
				for depth in ArenaStage.DEPTHS:
					var plane := ArenaStage.layer_rect(area, Vector2(1536, 1024), depth, camera.center, camera.zoom)
					check(plane.position.x <= 0.01 and plane.position.y <= 0.01 and plane.end.x >= area.x - 0.01 and plane.end.y >= area.y - 0.01, "Zoom exposes a parallax image edge")
	var model := CombatModel.new()
	model.reset([5, 4])
	for _tick in 22: model.step(8, 0)
	var air := ArenaStage.camera(model.state(), bounds)
	check(air.zoom < close.zoom, "Real jump does not create headroom")
	var saved := model.core.snapshot()
	for _tick in 40: model.step(0, 0)
	check(model.core.restore(saved) and air == ArenaStage.camera(model.state(), bounds), "Restored simulation has stale camera easing")
	print("Camera silhouette ratio, corner/air visibility, parallax coverage and rollback: ", failures, " failures")
	quit(int(failures != 0))
