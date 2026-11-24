extends SceneTree

var failures := 0
var checks := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr(message)
func _initialize() -> void: call_deferred("run")

func fixture(facing: int) -> CombatModel:
	var model := CombatModel.new()
	var batch: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	check(model.load_file("res://data/workshop/" + str(batch.file)).is_empty(), "Current Workshop data rejected")
	model.reset([5, 0])
	model.core.preview_place(0, 30000 if facing == 1 else 70000, 0, 0)
	model.core.preview_place(1, 85000 if facing == 1 else 15000, 0, 0)
	model.step(0, 0)
	return model

func run() -> void:
	for sheet in CombatMovement.catalog().sheets.values():
		var path := CombatMovement.DIRECTORY + str(sheet.file)
		check(FileAccess.get_sha256(path) == sheet.sha256, "Movement source bytes/provenance changed")
		var source := Image.new()
		check(source.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK, "Movement PNG cannot decode")
		check(source.get_size() == Vector2i(sheet.size[0], sheet.size[1]), "Movement atlas dimensions changed")
		for point in [Vector2i(0, 0), Vector2i(source.get_width() - 1, 0), Vector2i(0, source.get_height() - 1)]:
			check(source.get_pixelv(point).a < 0.03, "Movement background is opaque")
	var arena = load("res://scripts/arena.gd").new()
	root.add_child(arena); arena.size = Vector2(1440, 810)
	var seen := {}
	for facing in [-1, 1]:
		for action in [0, 16, 32, 512]:
			var model := fixture(facing)
			var landed := false
			var airborne := false
			var began_attack := false
			var snapshot: PackedByteArray
			var replay := []
			for tick in 95:
				var input := 8 if tick == 5 else 0
				if tick == 12: input = action | ((2 if facing == 1 else 1) if action == 512 else 0)
				if tick == 20: snapshot = model.core.snapshot()
				model.step(input, 0)
				var state := model.state()
				var fighter: Dictionary = state.players[0]
				var choice := CombatMovement.selection(fighter, model.movement(5))
				if tick >= 20 and tick < 35: replay.append({"hash": model.state_hash(), "choice": choice})
				if fighter.y > 0: airborne = true
				if airborne and fighter.y == 0: landed = true
				if fighter.move >= 0: began_attack = true
				var before: PackedByteArray = model.core.snapshot()
				var boxes: PackedInt32Array = model.core.boxes(0, 0)
				arena.refresh(model, state, false, false)
				check(model.core.snapshot() == before and model.core.boxes(0, 0) == boxes, "Movement art changed simulation/collision")
				var sprite := arena.sprites[0] as Sprite2D
				check(signf(sprite.scale.x) == facing, "Movement art turned the fighter")
				check(is_equal_approx(absf(sprite.scale.x), sprite.scale.y), "Movement stretched the body")
				if not choice.is_empty():
					seen["%s/%d" % [choice.sheet, choice.key]] = true
					check(str(sprite.texture.atlas.resource_path).contains("movement-v1/"), "Arena did not install movement art")
					if choice.beat == "dash pause": check(fighter.vx == 0 and fighter.vy == 0, "Pause art ignored arrested momentum")
					if choice.beat == "landing": check(fighter.y == 0 and fighter.landingTime > 0, "Landing art invented a recovery lock")
				else:
					check(sprite.texture == FighterArt.texture(5, FighterArt.PHASES[fighter.posePhase], fighter.poseIndex), "Movement art replaced an attack/neutral pose")
			check(airborne and landed, "Jump fixture did not land")
			if action in [16, 32]: check(began_attack, "Air input never started an attack")
			check(model.core.restore(snapshot), "Movement replay snapshot rejected")
			for expected in replay:
				model.step(0, 0)
				check(model.state_hash() == expected.hash, "Replay gameplay diverged")
				check(CombatMovement.selection(model.state().players[0], model.movement(5)) == expected.choice, "Replay chose different movement art")
	for key in ["fillet_ground/1", "fillet_ground/2", "fillet_ground/3", "fillet_ground/4", "fillet_flight/0", "fillet_flight/1", "fillet_flight/2", "fillet_flight/3", "fillet_flight/4", "fillet_flight/5"]:
		check(seen.has(key), "Actual movement did not exercise " + key)
	# New legal actions and all special receiver states take priority over air art.
	var model := fixture(1)
	model.step(8, 0)
	for tick in 6: model.step(0, 0)
	var neutral: Dictionary = model.state().players[0]
	check(not CombatMovement.selection(neutral, model.movement(5)).is_empty(), "Air priority fixture stayed grounded")
	var retreat := neutral.duplicate()
	retreat.dashTicks = 3; retreat.dashPause = 0; retreat.vx = -1000 * retreat.facing
	var retreat_art := CombatMovement.selection(retreat, model.movement(5))
	check(retreat_art.beat == "dash retreat" and retreat_art.key == 2, "Optional air retreat leaned into forward travel")
	for field in ["move", "displayMove", "stun", "pairRecovery", "faultless"]:
		var fighter := neutral.duplicate()
		fighter[field] = 1
		check(CombatMovement.selection(fighter, model.movement(5)).is_empty(), "Movement masked " + field)
	for reaction in range(1, 8):
		var fighter := neutral.duplicate(); fighter.reaction = reaction
		check(CombatMovement.selection(fighter, model.movement(5)).is_empty(), "Movement masked a receiver state")
	arena.queue_free(); await process_frame
	print("Movement presentation: %d failures; %d checks, real jumps, air attacks, dash arrest/burst, landing, both facings and replay" % [failures, checks])
	quit(1 if failures else 0)
