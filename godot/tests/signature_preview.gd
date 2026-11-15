extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	game.motion.instant = true
	game.choose_activity("local")
	game.confirm_selection()
	await game.wait_for_match_entry()
	game.show_boxes = args.has("--boxes")
	game.model.reset([4, 5])
	var air := args.has("--air")
	var followed := false
	for frame in 110:
		var input: int = (8 if frame == 0 else 4 if frame == 1 else 5 if frame == 2 else 17 if frame == 3 else 0) if air else (4 if frame == 0 else 5 if frame == 1 else 65 if frame == 2 else 0)
		var other: int = 8 if not air and frame == 12 else 0
		var state: Dictionary = game.model.state()
		if state.players[0].contact and state.hitstop == 0 and not followed:
			input = 16
			followed = true
		game.model.step(input, other)
		state = game.model.state()
		if (args.has("--stab") and state.players[0].combo == 2) or (not args.has("--stab") and state.players[1].reaction == 5): break
	game._process(0.0)
	await process_frame
	await RenderingServer.frame_post_draw
	if args.has("--screenshot"):
		if root.get_texture().get_image().save_png(args[args.find("--screenshot") + 1]) != OK: quit(1);return
	quit()
