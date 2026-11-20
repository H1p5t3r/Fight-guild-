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
	if not args.has("--home"):
		game.choose_activity("development" if args.has("--editor") else "local")
		if not args.has("--select"):
			game.confirm_selection()
			await game.wait_for_match_entry()
			if args.has("--splat") or args.has("--break") or args.has("--bonus"):
				var fixture := preload("res://tests/stage_fixture.gd")
				fixture.configure(game.model)
				fixture.approach(game.model, 1)
				if not fixture.splat(game.model, 1): printerr("Preview did not splat"); quit(1); return
				if args.has("--break") or args.has("--bonus"):
					if not fixture.breach(game.model, 1): printerr("Preview did not break"); quit(1); return
					for _tick in (int(game.model.state().wallBreakDuration) if args.has("--bonus") else 24): game.model.step(0, 0)
			game._process(0.0)
	await process_frame
	if args.has("--reactions"):
		game.editor_shell.get_child(0).ensure_control_visible(game.fields.launch.control)
		await process_frame
	await RenderingServer.frame_post_draw
	if args.has("--screenshot"):
		root.get_texture().get_image().save_png(args[args.find("--screenshot") + 1])
	quit()
