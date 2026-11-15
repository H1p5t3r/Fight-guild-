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
	game.choose_activity("training")
	game.confirm_selection()
	await game.wait_for_match_entry()
	game.lab.start_recording(game.model)
	var stage := 0
	for tick in 150:
		var a := 2 if tick < 24 else 4 if tick == 24 else 6 if tick == 25 else 66 if tick == 26 else 0
		var b := 1 if tick < 24 else 0
		var before: Dictionary = game.model.state()
		if before.players[0].contact and before.hitstop == 0 and stage < 2:
			a = 66 if stage == 0 else 68
			stage += 1
		game.model.step(a, b)
		game.lab.observe(game.model, before, Vector2i(a, b))
		if game.model.state().players[0].combo == 3: break
	game.lab.stop()
	game._process(0.0)
	game.open_frame_lab()
	await process_frame
	await RenderingServer.frame_post_draw
	if args.has("--screenshot"):
		if root.get_texture().get_image().save_png(args[args.find("--screenshot") + 1]) != OK: quit(1); return
	quit()
