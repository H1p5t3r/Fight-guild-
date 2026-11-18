extends SceneTree

const Fixture = preload("res://tests/stage_fixture.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; printerr(message)
func _initialize() -> void: call_deferred("run")

func run() -> void:
	var model := CombatModel.new()
	var defaults := model.data()
	check(defaults.schema == 22 and defaults.recoveryRules.wallBreakFrames == 150, "New wall timing/schema missing")
	var legacy := defaults.duplicate(true)
	legacy.schema = 11
	legacy.coreVersion = 11
	for character in legacy.characters: character.moves.resize(32)
	legacy.recoveryRules.wallBreakFrames = 91
	legacy.characters[5].moves[0].damage = 133
	check(model.load_data(legacy).is_empty() and model.data().recoveryRules.wallBreakFrames == 91 and model.move(5, 0).damage == 133, "Stage migration changed authored tuning")
	model.load_data(defaults)
	var old_snapshot := model.core.snapshot()
	old_snapshot.encode_s32(old_snapshot.size() - 4, 11)
	var hash_before := model.state_hash()
	check(not model.core.restore(old_snapshot) and model.state_hash() == hash_before, "Old snapshot version was accepted or changed live state")
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
	for zoom in [0.8, 1.2, 2.3, 2.5]:
		for side in [-1, 1]:
			var offset := Vector2(bounds.x * 0.1, 0) if side < 0 else Vector2(bounds.x * (0.9 - zoom), 0)
			var wall := ArenaStage.wall_rect(bounds, side, zoom, offset)
			check(wall.position.y == 0 and wall.size.y == bounds.y, "Wall leaves a vertical gap")
			check((wall.position.x == 0 if side < 0 else wall.end.x == bounds.x) and wall.size.x > 0, "Wall does not fill the outer screen border")
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
			if travel.pan >= 0.28 and travel.pan <= 0.72:
				var from := StageTravel.source_camera(now, bounds)
				var to := StageTravel.destination_camera(now, bounds)
				for layer in [1, 2]:
					var a := ArenaStage.layer_rect(bounds, Vector2(1536, 1024), ArenaStage.DEPTHS[layer], from.center, from.zoom, from.lift)
					var b := ArenaStage.layer_rect(bounds, Vector2(1536, 1024), ArenaStage.DEPTHS[layer], to.center, to.zoom, to.lift)
					a.position += StageTravel.layer_offset(bounds, layer, side, travel.pan, false)
					b.position += StageTravel.layer_offset(bounds, layer, side, travel.pan, true)
					a = a.grow_individual(-a.size.x * ArenaStage.TRAVEL_EDGE_FADE, 0, -a.size.x * ArenaStage.TRAVEL_EDGE_FADE, 0)
					b = b.grow_individual(-b.size.x * ArenaStage.TRAVEL_EDGE_FADE, 0, -b.size.x * ArenaStage.TRAVEL_EDGE_FADE, 0)
					check(minf(a.position.x, b.position.x) <= 0 and maxf(a.end.x, b.end.x) >= bounds.x and maxf(a.position.x, b.position.x) <= minf(a.end.x, b.end.x), "Wall travel exposes a gap between scenic layers")
			for player in 2:
				var presentation := StageTravel.fighter(now, player, bounds, false)
				check(is_finite(presentation.position.x) and is_finite(presentation.scale), "Non-finite presentation")
				if tick == 0:
					var origin_camera := ArenaStage.camera(state, bounds)
					var expected: Vector2 = origin_camera.offset + Vector2(state.players[player].x * bounds.x / 100000.0, ArenaStage.floor_line(bounds) - state.players[player].y * bounds.x / 100000.0) * origin_camera.zoom
					check(presentation.position.distance_to(expected) < 0.1, "Travel jumps away from the gameplay camera")
				if tick == int(state.wallBreakDuration) - 1:
					landing[player] = presentation
					landing[player + 2] = StageTravel.fighter(now, player, bounds, true)
			model.step(1 | 16, 2 | 32)
		var final_hash: int = model.core.checksum()
		var camera := ArenaStage.camera(model.state(), bounds)
		for player in 2:
			var expected: Vector2 = camera.offset + Vector2(model.state().players[player].x * bounds.x / 100000.0, ArenaStage.floor_line(bounds)) * camera.zoom
			check(landing[player].position.distance_to(expected) < 0.1 and absf(landing[player].scale - camera.zoom) < 0.001, "Landing jumps when gameplay resumes")
			check(landing[player + 2].position.distance_to(expected) < 0.1 and absf(landing[player + 2].scale - camera.zoom) < 0.001, "Reduced-motion landing jumps when gameplay resumes")
		check(model.core.restore(origin), "Travel snapshot rejected")
		for _tick in int(state.wallBreakDuration): model.step(1 | 16, 2 | 32)
		check(model.core.checksum() == final_hash, "Travel rollback diverged")
		check(ArenaStage.next_stage(shot.target, -side) == 0, "Reverse route does not return")
		check(ArenaStage.camera(model.state(), bounds, true) == camera, "Reduced motion changes essential fighter framing")
	print("Generated stages, parallax, both wall routes, migration and landing continuity: ", failures, " failures")
	quit(int(failures != 0))
