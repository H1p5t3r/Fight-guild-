extends SceneTree

var failures := 0
func check(value: bool, message: String) -> void:
	if not value: failures += 1; printerr(message)
func _initialize() -> void: call_deferred("run")

func silhouette_height(sprite: Sprite2D, phase: String, pose: int) -> float:
	var bounds: Array = FighterArt.sheet(5, phase).frames[pose].bounds
	return float(bounds[3] - bounds[1]) * absf(sprite.scale.y)

func run() -> void:
	var sprite := Sprite2D.new()
	var model := CombatModel.new()
	var batch: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	check(model.load_file("res://data/workshop/" + str(batch.file)).is_empty(), "Latest move data failed to load")
	FighterArt.apply(sprite, 5, "ready", 0, 1, 1)
	var ready_height := silhouette_height(sprite, "ready", 0)
	for facing in [-1, 1]:
		for slot in [2, 7]: # A grounded strike and the two-hit launcher, both facings.
			model.reset([4, 5])
			model.core.preview_place(0, 50000 - facing * 4500, 0, 0)
			model.core.preview_place(1, 50000 + facing * 4500, 0, 0)
			model.step(0, 0)
			model.core.preview_begin(0, slot)
			var reacted := false
			for tick in 100:
				model.step(0, 0)
				var receiver: Dictionary = model.state().players[1]
				if receiver.posePhase != 0 or receiver.poseIndex != 9: continue
				reacted = true
				var before := model.state_hash()
				FighterArt.apply(sprite, 5, "active", 9, 1, int(receiver.facing))
				check(silhouette_height(sprite, "active", 9) <= ready_height * 1.08, "Fillet visibly grows on impact")
				check(is_equal_approx(absf(sprite.scale.x), sprite.scale.y), "Reaction stretched instead of using uniform scale")
				var pivot: Array = FighterArt.sheet(5, "active").frames[9].pivot
				check((sprite.offset + Vector2(pivot[0], pivot[1])).is_zero_approx(), "Reaction moved the foot root")
				check(signf(sprite.scale.x) == int(receiver.facing), "Reaction mirrored incorrectly")
				check(model.state_hash() == before, "Scale correction changed combat during rendering")
			check(reacted, "Actual strike never exercised Fillet's hit reaction")
	# Get-up settles should retain their approved stance-sized presentation.
	for phase in ["knockdown", "knockdown_back"]:
		FighterArt.apply(sprite, 5, phase, 5, 1, 1)
		check(absf(silhouette_height(sprite, phase, 5) / ready_height - 1.0) < 0.05, "Get-up scale no longer matches the stance")
	sprite.free()
	print("Fillet reaction scale: %d failures; grounded/air hits, facing, planted root and get-up size" % failures)
	quit(1 if failures else 0)
