extends SceneTree

var failures := 0
var checks := 0
var arena: Control
var tableau: PauseTableau
var model := CombatModel.new()

func _initialize() -> void: call_deferred("run")

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("Pause tableau: " + description)

func freeze_pose(label: String) -> void:
	arena.refresh(model, model.state(), false, false)
	var snapshot := model.core.snapshot()
	tableau.capture(arena, model.state(), model.frame())
	tableau.amount = 1.0
	check(model.core.snapshot() == snapshot, label + ": pause changed simulation")
	check(tableau.copies.size() >= 2, label + ": missing fighters")
	check(tableau.group_bounds.has_area() and tableau.focal_point.is_equal_approx(tableau.group_bounds.get_center() / tableau.captured_size), label + ": pause did not center on the pair as one composition")
	var images := []
	var transforms := []
	for copy in tableau.copies:
		var original := instance_from_id(copy.get_meta("source_id")) as Sprite2D
		check(copy.texture == original.texture, label + ": replaced displayed texture")
		check(copy.offset == original.offset, label + ": lost pivot")
		check(copy.get_global_transform_with_canvas().is_equal_approx(original.get_global_transform_with_canvas()), label + ": lost camera, facing or scale")
		images.append(copy.texture)
		transforms.append(copy.transform)
	# Even if the live game continues (online), the menu's picture stays frozen.
	for tick in 26: model.step(2, 1)
	arena.refresh(model, model.state(), false, false)
	for i in tableau.copies.size():
		check(tableau.copies[i].texture == images[i] and tableau.copies[i].transform == transforms[i], label + ": online update moved captured art")
	check(tableau.captured_frame < model.frame(), label + ": fixture did not advance live combat")

func run() -> void:
	arena = load("res://scripts/arena.gd").new()
	arena.size = Vector2(1280, 720)
	root.add_child(arena)
	tableau = PauseTableau.new()
	root.add_child(tableau)
	await process_frame
	for character in 6:
		model.reset([character, (character + 1) % 6])
		freeze_pose("idle " + str(character))
		for copy in tableau.copies:
			if copy.get_meta("character") == character and character != 2:
				check(copy.material.get_shader_parameter("weapon_mode") == 1, "Actual idle missing an authored weapon region " + str(character))
		model.reset([character, (character + 1) % 6])
		model.core.preview_place(0, 70000, 0, 0)
		model.core.preview_place(1, 30000, 0, 0)
		check(model.core.preview_begin(0, 3), "Could not start mirrored Hs fixture")
		for tick in int(model.move(character, 3).startup): model.step(0, 0)
		freeze_pose("mirrored active " + str(character))
		model.reset([character, (character + 1) % 6])
		model.core.preview_place(0, 40000, 9000, 0)
		freeze_pose("airborne " + str(character))
		model.reset([character, (character + 1) % 6])
		model.core.preview_status(0, 0, 30)
		freeze_pose("knockdown " + str(character))
	for character in [1, 3, 4, 5]:
		PairedThrowFixtures.prepare(model, character, 2, 23, 0, 1, 50000)
		model.core.preview_begin(0, 23)
		for tick in 7: model.step(0, 0)
		freeze_pose("paired grip " + str(character))
	model.reset([4, 5])
	model.core.preview_place(0, 30000, 0, 0)
	model.core.preview_place(1, 70000, 0, 0)
	model.core.preview_begin(0, 13)
	for tick in int(model.move(4, 13).startup) + 2: model.step(0, 0)
	freeze_pose("detached hook")
	# Authored material mattes are separate from collision and do not depend on
	# a bright-pixel threshold (white hair, cloth and armor must remain guild ink).
	for character in [0, 1, 3, 4, 5]:
		var sprite := Sprite2D.new()
		var phase := InkMenu.idle_phase(character)
		for pose in (FighterArt.sheet(character, phase).frames.size() if phase == "idle" else 1):
			FighterArt.apply(sprite, character, phase, pose, 1.0, 1)
			check(tableau.material_for(sprite, character).get_shader_parameter("weapon_mode") == 1, "Missing stance weapon matte " + str(character) + "/" + str(pose))
		sprite.free()
	print("Frozen pause presentation: %d failures / %d checks" % [failures, checks])
	quit(1 if failures else 0)
