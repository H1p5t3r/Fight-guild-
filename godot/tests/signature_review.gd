extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.content_scale_size = Vector2i(1440, 1000)
	root.size = Vector2i(1440, 1000)
	var args := OS.get_cmdline_user_args()
	var character := 4 if args.has("--shark") else 5
	var model := CombatModel.new()
	var background := ColorRect.new()
	background.color = Color("17252d")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.position = Vector2(20, 20)
	root.add_child(grid)
	var slots: Array = [28, 29, 30, 31] if character == 4 else [25, 15, 26, 27]
	for phase in ["signature_windup", "signature_active"]:
		for pose in 4:
			var cell := VBoxContainer.new()
			grid.add_child(cell)
			var label := Label.new()
			label.text = "%s · %s · %s" % [CombatModel.CHARACTERS[character], CombatModel.MOVE_IDS[slots[pose]], "WINDUP" if phase.ends_with("windup") else "ACTIVE"]
			cell.add_child(label)
			var preview := FighterPreview.new()
			preview.custom_minimum_size = Vector2(344, 430)
			preview.combat_model = model
			preview.move_slot = slots[pose]
			preview.show_collision = not args.has("--clean")
			cell.add_child(preview)
			preview.present(character, phase, pose, -1 if args.has("--mirror") else 1)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	if args.has("--screenshot"):
		if root.get_texture().get_image().save_png(args[args.find("--screenshot")+1]) != OK: quit(1);return
	quit()
