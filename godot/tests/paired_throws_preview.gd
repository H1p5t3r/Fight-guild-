extends SceneTree

var arena: Control
var caption: Label
var model: CombatModel

func _initialize() -> void: call_deferred("run")

func run() -> void:
	model = PairedThrowFixtures.create()
	arena = load("res://scripts/arena.gd").new()
	root.add_child(arena)
	arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena.diagnostics = false
	arena.round_label = "THROW PRESENTATION"
	caption = Label.new()
	# Canvas coordinates follow the project's 1280x720 content size even when
	# Movie Maker records a larger window. Keep the review labels below the HUD.
	caption.position = Vector2(24, 116)
	caption.add_theme_font_override("font", GuildTheme.SEMIBOLD)
	caption.add_theme_font_size_override("font_size", 20)
	caption.add_theme_color_override("font_outline_color", Color("10171e"))
	caption.add_theme_constant_override("outline_size", 6)
	root.add_child(caption)
	await process_frame
	var args := OS.get_cmdline_user_args()
	var directory := args[args.find("--output") + 1] if args.has("--output") else "user://"
	DirAccess.make_dir_recursive_absolute(directory)
	# Current production data, normal simulation speed. Grip art is still the
	# existing art; the new A/B direction sheet is intentionally not installed.
	var cases := [
		[5, 4, 24, 0, 1, 50000, "FILLET / FORWARD THROW", false],
		[5, 1, 23, 1, -1, 89000, "FILLET / BACK THROW AT THE WALL", false],
		[5, 2, 45, 0, 1, 50000, "FILLET / 236D COMMAND GRAB", false],
		[5, 3, 46, 1, -1, 50000, "FILLET / 214D COMMAND GRAB", false],
		[5, 4, 24, 0, 1, 50000, "THROW TECH / NO FALSE HIT REACTION", true],
		[5, 4, 13, 0, 1, 50000, "WOUND SETUP / EXISTING GET-UP", false],
		[3, 5, 13, 0, 1, 50000, "TAPPER / COLLAR CAPTURE", false]]
	var failures := 0
	for example in cases:
		var owner := int(example[3])
		PairedThrowFixtures.prepare(model, example[0], example[1], example[2], owner, example[4], example[5])
		var teched := false
		var captured := false
		var released := false
		var saved := false
		for tick in 140:
			if tick == 16: model.core.preview_begin(owner, example[2])
			var before := model.state()
			var input := 0
			if example[7] and not teched and int(before.pairKind) > 0 and int(before.hitstop) == 0:
				input = 48; teched = true
			model.step(input if owner == 1 else 0, input if owner == 0 else 0)
			var state := model.state()
			var receiver: Dictionary = state.players[1 - owner]
			var gripping := int(state.pairKind) > 0 or int(receiver.grabOwner) == owner
			if gripping: captured = true
			elif captured: released = true
			var reaction := model.cues.reaction_at(model.frame(), 1 - owner)
			var beat := "APPROACH"
			if gripping: beat = "CAPTURE / CURRENT GRIP ART"
			elif not reaction.is_empty(): beat = "RELEASE / " + ["CONTACT", "RECOIL", "HOLD"][CombatReactions.key(int(reaction.age))]
			elif released: beat = "RECOVERY"
			caption.text = str(example[6]) + "\n" + beat + "   •   60 FPS / GAMEPLAY UNCHANGED"
			arena.refresh(model, state, false, false)
			await process_frame
			await RenderingServer.frame_post_draw
			if not saved and not reaction.is_empty() and int(reaction.age) == 3:
				root.get_texture().get_image().save_png(directory.path_join("%d-%d-release.png" % [example[0], example[2]]))
				saved = true
		if not captured or not released: failures += 1
		print("Throw review ", example[6], ": captured=", captured, ", released=", released)
	print("Native paired throw review: %d failures" % failures)
	quit(1 if failures else 0)
