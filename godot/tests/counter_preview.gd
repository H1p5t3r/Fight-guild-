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
	game.confirm_sides()
	game.confirm_selection()
	await game.wait_for_match_entry()
	game.model.reset([5, 4])
	if not args.has("--neutral"):
		var data: Dictionary = game.model.data()
		var move: Dictionary = data.characters[5].moves[0]
		move.counterTier = 3
		move.counterFreezeFrames = 31
		move.counterSlowFrames = 35
		move.counterHitstun = 0
		move.hitstun = 60
		move.pushback = 0
		game.model.load_data(data)
		game.model.reset([5, 4])
		for tick in 20: game.model.step(2, 1)
		for tick in 11: game.model.step(16 if tick < 5 else 0, 128 if tick < 5 else 0)
	game._process(0.0)
	await process_frame
	await RenderingServer.frame_post_draw
	if args.has("--screenshot"):
		if root.get_texture().get_image().save_png(args[args.find("--screenshot") + 1]) != OK: quit(1); return
	quit()
