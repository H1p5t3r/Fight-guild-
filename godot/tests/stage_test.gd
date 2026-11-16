extends SceneTree

const Fixture = preload("res://tests/stage_fixture.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; printerr(message)
func _initialize() -> void: call_deferred("run")

func run() -> void:
	var model := CombatModel.new()
	var defaults := model.data()
	check(defaults.schema == 11 and defaults.recoveryRules.wallBreakFrames == 150, "New wall timing/schema missing")
	var legacy := defaults.duplicate(true)
	legacy.schema = 10
	legacy.coreVersion = 10
	legacy.recoveryRules.wallBreakFrames = 91
	legacy.characters[5].moves[0].damage = 133
	check(model.load_data(legacy).is_empty() and model.data().recoveryRules.wallBreakFrames == 91 and model.move(5, 0).damage == 133, "Stage migration changed authored tuning")
	model.load_data(defaults)
	var bounds := Vector2(1404, 722)
	for path in ArenaStage.asset_paths():
		var texture := load(path) as Texture2D
		check(texture != null and texture.get_size() == Vector2(1536, 1024), "Missing generated plane: " + path)
	var shifts := []
	for depth in ArenaStage.DEPTHS:
		var left := ArenaStage.layer_rect(bounds, Vector2(1536, 1024), depth, 0.32, 1.19)
		var right := ArenaStage.layer_rect(bounds, Vector2(1536, 1024), depth, 0.68, 1.19)
		check(left.position.x <= 0 and right.end.x >= bounds.x, "Camera exposed a layer edge")
		shifts.append(left.position.x - right.position.x)
	check(shifts[0] > 0 and shifts[0] < shifts[1] and shifts[1] < shifts[2], "Depths do not scroll independently")
	for side in [1, -1]:
		Fixture.configure(model)
		Fixture.approach(model, side)
		check(Fixture.splat(model, side), "Approach failed to splat")
		check(Fixture.breach(model, side), "Follow-up failed to break")
		if model.state().wallBreakTime <= 0: continue
		var state := model.state()
		var shot := StageTravel.describe(state)
		check(shot.source == 0 and shot.target == (1 if side > 0 else 2), "Wrong adjoining arena")
		var origin: PackedByteArray = model.core.snapshot()
		var positions: Array = state.wallBreakX.duplicate()
		var landing := {}
		for tick in int(state.wallBreakDuration):
			var now := model.state()
			var travel := StageTravel.describe(now)
			check(travel.source == shot.source and travel.target == shot.target, "Route changed across reset")
			check(now.wallBreakX == positions and now.remaining == state.remaining, "Travel lost origin or advanced round timer")
			for player in 2:
				var presentation := StageTravel.fighter(now, player, bounds, false)
				check(is_finite(presentation.position.x) and is_finite(presentation.scale), "Non-finite presentation")
				if tick == int(state.wallBreakDuration) - 1: landing[player] = presentation
			model.step(1 | 16, 2 | 32)
		var final_hash: int = model.core.checksum()
		var camera := ArenaStage.camera(model.state(), bounds)
		for player in 2:
			var expected: Vector2 = camera.offset + Vector2(model.state().players[player].x * bounds.x / 100000.0, bounds.y - 76) * camera.zoom
			check(landing[player].position.distance_to(expected) < 0.1 and absf(landing[player].scale - camera.zoom) < 0.001, "Landing jumps when gameplay resumes")
		check(model.core.restore(origin), "Travel snapshot rejected")
		for _tick in int(state.wallBreakDuration): model.step(1 | 16, 2 | 32)
		check(model.core.checksum() == final_hash, "Travel rollback diverged")
		check(ArenaStage.next_stage(shot.target, -side) == 0, "Reverse route does not return")
		check(ArenaStage.camera(model.state(), bounds, true).zoom == 1.0, "Reduced motion tracks camera")
	print("Generated stages, parallax, both wall routes, migration and landing continuity: ", failures, " failures")
	quit(int(failures != 0))
