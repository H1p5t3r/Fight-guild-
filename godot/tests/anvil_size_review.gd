extends SceneTree

# A fixed-camera contact sheet: no per-pose fitting, camera zoom or image edits.
func _initialize() -> void: call_deferred("run")

func run() -> void:
	root.content_scale_size = Vector2i(1280, 1000)
	root.size = Vector2i(1280, 1000)
	var bg := ColorRect.new()
	bg.color = Color("151a20")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var fighter: Dictionary = FighterArt.catalog().fighters[0]
	var cases := [["IDLE", "idle", 0], ["WALK", "walk", 2], ["CROUCH", "crouch_idle", 0], ["GUARD", "block", 0],
		["STEP DASH", "run", 3], ["JUMP", "active", 8], ["5P", "attack_animation", fighter.attack_animations["0"].active[0].pose],
		["f.S", "attack_animation", fighter.attack_animations["2"].active[0].pose],
		["2Hs", "attack_animation", fighter.attack_animations["7"].active[0].pose], ["j.Hs", "attack_animation", fighter.attack_animations["20"].active[0].pose],
		["FOUNDRY LIFT", "attack_animation", fighter.paired_animations["14"].keys[1].pose], ["IRON TURN", "attack_animation", fighter.paired_animations["15"].keys[1].pose],
		["HEAD RECOIL", "reaction", 0], ["AIR RECOIL", "reaction", 1], ["SOFT KNOCKDOWN", "knockdown_back", 0], ["HARD KNOCKDOWN", "knockdown", 0]]
	for i in cases.size():
		var item: Array = cases[i]
		var origin := Vector2((i % 4) * 320, (i / 4) * 250)
		var label := Label.new()
		label.text = str(item[0]) + "  /  FIXED WORLD SCALE"
		label.position = origin + Vector2(12, 10)
		label.add_theme_font_override("font", GuildTheme.SEMIBOLD)
		label.add_theme_font_size_override("font_size", 17)
		root.add_child(label)
		var line := ColorRect.new()
		line.position = origin + Vector2(8, 227)
		line.size = Vector2(304, 1)
		line.color = Color("505963")
		root.add_child(line)
		var sprite := Sprite2D.new()
		root.add_child(sprite)
		sprite.position = origin + Vector2(145, 227)
		if str(item[1]) == "reaction":
			CombatGrabs.apply_frame(sprite, CombatReactions.frame_for(0, "head" if int(item[2]) == 0 else "air", 3), 1.1, 1)
		else: FighterArt.apply(sprite, 0, str(item[1]), int(item[2]), 1.1, 1)
		for child in sprite.get_children():
			if child is Sprite2D: child.visible = false
	await process_frame
	await RenderingServer.frame_post_draw
	var args := OS.get_cmdline_user_args()
	root.get_texture().get_image().save_png(args[args.find("--output") + 1])
	print("Anvil fixed-scale review complete")
	quit()
