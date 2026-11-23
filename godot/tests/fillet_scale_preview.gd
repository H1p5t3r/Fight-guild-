extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	root.content_scale_size = Vector2i(1440, 520)
	root.size = Vector2i(1440, 520)
	var background := ColorRect.new()
	background.color = Color("18252e")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var heading := Label.new()
	heading.text = "FILLET / HIT REACTION SCALE     ·     SAME CAMERA, SAME GROUND LINE"
	heading.position = Vector2(16, 18)
	heading.add_theme_font_override("font", GuildTheme.SEMIBOLD)
	heading.add_theme_font_size_override("font_size", 25)
	root.add_child(heading)
	var examples := [["ready",0,"STANCE",0],["attack_animation",0,"ATTACK ENTRY",0],
		["active",9,"BEFORE / HIT",310],["active",9,"FIXED / HIT",0]]
	for i in examples.size():
		var example: Array = examples[i]
		var x := float(i % 4) * 360.0
		var label := Label.new()
		label.text = str(example[2])
		label.position = Vector2(x + 14, 80)
		label.add_theme_font_override("font", GuildTheme.SEMIBOLD)
		label.add_theme_font_size_override("font_size", 22)
		root.add_child(label)
		var line := ColorRect.new()
		line.position = Vector2(x + 12, 470)
		line.size = Vector2(336, 1)
		line.color = Color("6c827e")
		root.add_child(line)
		var sprite := Sprite2D.new()
		var frame: Dictionary = FighterArt.sheet(5, example[0]).frames[example[1]]
		var previous: Variant = frame.get("body_height")
		if int(example[3]) > 0: frame.body_height = example[3]
		FighterArt.apply(sprite, 5, example[0], example[1], 2.2, 1)
		if previous == null: frame.erase("body_height")
		else: frame.body_height = previous
		sprite.position = Vector2(x + 180, 470)
		root.add_child(sprite)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var args := OS.get_cmdline_user_args()
	if args.has("--screenshot"):
		var result := root.get_texture().get_image().save_png(args[args.find("--screenshot") + 1])
		if result != OK: quit(1); return
	quit()
