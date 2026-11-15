extends SceneTree

# Native contact sheet: every authored pose for one fighter, with compiled boxes.
# -- --character 0 --screenshot /absolute/path.png
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.content_scale_size = Vector2i(1440, 1080)
	root.size = Vector2i(1440, 1080)
	await process_frame
	DisplayServer.window_set_size(Vector2i(1440, 1080))
	var args := OS.get_cmdline_user_args()
	var character := int(args[args.find("--character") + 1]) if args.has("--character") else 0
	var model := CombatModel.new()
	var background := ColorRect.new()
	background.color = Color("17252d")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 20)
	root.add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)
	var heading := Label.new()
	heading.text = CombatModel.CHARACTERS[character].to_upper() + " / BODY, SPACING & STRIKE REVIEW"
	heading.add_theme_font_size_override("font_size", 24)
	column.add_child(heading)
	var note := Label.new()
	note.text = "Cyan: body hurtboxes · green: pushbox · orange: damaging strike. Weapons never extend hurtboxes."
	column.add_child(note)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(grid)
	for phase in ["active", "windup", "block"]:
		var names: Array = FighterArt.sheet(character, phase).frames
		for pose in names.size():
			var cell := VBoxContainer.new()
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
			grid.add_child(cell)
			var label := Label.new()
			label.text = "%s %02d" % [phase.to_upper(), pose]
			cell.add_child(label)
			var preview := FighterPreview.new()
			preview.custom_minimum_size = Vector2(216, 198)
			preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
			preview.combat_model = model
			preview.show_collision = true
			cell.add_child(preview)
			preview.present(character, phase, pose)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	if args.has("--screenshot"):
		var result := root.get_texture().get_image().save_png(args[args.find("--screenshot") + 1])
		if result != OK: quit(1); return
	quit()
