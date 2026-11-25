extends SceneTree

# Capture actual native entry phases, or record --tour / --match-tour with --write-movie.
var game: Control

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	var args := OS.get_cmdline_user_args()
	game.choose_activity("local")
	game.confirm_sides()
	game.menus.selection.choose_fighter(0, 0)
	game.menus.selection.choose_fighter(1, 4)
	for p in 2:
		var flag := "--p" + str(p + 1)
		if args.has(flag): game.menus.selection.choose_fighter(p, int(args[args.find(flag) + 1]))
	await game.wait_for_menu_motion()
	if args.has("--match-tour"):
		# Review-only KO fixture, never saved: exercises the real match/intermission flow.
		var data: Dictionary = game.model.data().duplicate(true)
		for fighter in game.menus.selection.chosen:
			var move: Dictionary = data.characters[fighter].moves[0]
			move.damage = 1000
			move.startup = 5
			move.reach = 50000
			move.hitstop = 0
		game.model.load_data(data)
	await create_timer(0.6).timeout
	game.confirm_selection()
	if args.has("--tour") or args.has("--match-tour"):
		await game.wait_for_match_entry()
		if args.has("--match-tour"):
			for winner in [0, 1, 0]:
				await create_timer(0.65).timeout
				for _tick in 5: game.model.step(16 if winner == 0 else 0, 16 if winner == 1 else 0)
				game._process(0.0)
				await game.wait_for_match_entry()
		await create_timer(0.9).timeout
	else:
		if args.has("--loading"):
			game.match_entry.set_process(false)
			game.match_entry._process(game.motion.duration(0.25))
		else:
			while game.match_entry.phase != "intro": await process_frame
			game.match_entry.set_process(false)
			if args.has("--opening") or args.has("--call") or args.has("--release"):
				game.match_entry.request_skip()
				if args.has("--call") or args.has("--release"):
					for beat in 2: game.match_entry._process(float(MatchCeremony.script().beatSeconds[beat]) + 0.01)
					if args.has("--final"):
						game.match_entry.round_number = 3
						game.round_number = 3
						game.match_score.wins = [1, 1]
				if args.has("--release"): game.match_entry._process(float(MatchCeremony.script().beatSeconds[2]) + 0.01)
			else:
				if args.has("--second"): game.match_entry._process(float(MatchCeremony.script().introSeconds) + 0.01)
			game.match_entry._process(0.4 if args.has("--release") else 1.0)
		await process_frame
		await RenderingServer.frame_post_draw
		if args.has("--screenshot"):
			root.get_texture().get_image().save_png(args[args.find("--screenshot") + 1])
	quit()
