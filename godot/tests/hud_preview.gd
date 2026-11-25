extends SceneTree

# Native visual fixture. Changes are in memory only and never saved to move data.
# --drive / --development / --training / --neutral / --collisions / --review / --low-health / --hits N / --fd / --p1 N / --p2 N / --screenshot PATH
var game: Control

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	var args := OS.get_cmdline_user_args()
	game.motion.instant = true
	game.choose_activity("development" if args.has("--development") else "training" if args.has("--training") else "local")
	if game.screen == "sides": game.confirm_sides()
	game.menus.selection.choose_fighter(0, 0)
	game.menus.selection.choose_fighter(1, 4)
	for p in 2:
		var flag := "--p" + str(p + 1)
		if args.has(flag): game.menus.selection.choose_fighter(p, int(args[args.find(flag) + 1]))
	game.confirm_selection()
	await game.wait_for_match_entry()
	game.motion.instant = false
	if args.has("--drive"):
		for _tick in 30: game.model.step(2, 1)
		game.model.step(0, 0)
		game.model.step(256, 0)
		for _tick in 100: game.model.step(0, 0)
	elif args.has("--collisions"):
		game.show_boxes = true
		for _tick in 40: game.model.step(2, 0)
		for _tick in game.model.move(game.characters[0], 0).startup: game.model.step(16, 0)
	elif not args.has("--neutral"):
		var data: Dictionary = game.model.data().duplicate(true)
		for character in data.characters:
			for move in character.moves: move.pushback = 0
			for slot in [0, 4]:
				character.moves[slot].damage = 180 if args.has("--low-health") else 70
				character.moves[slot].startup = 5
				character.moves[slot].reach = 50000
		game.model.load_data(data)
		# Real contacts create health loss, Momentum and the combo display.
		game.model.reset(game.characters, game.simple)
		for _i in 18: game.model.step(2, 0)
		if args.has("--fd"):
			game.model.core.set_training_momentum(1, 6500)
			for _tick in 5: game.model.step(16, 2 | 2048)
		else:
			var hit_count := 12 if args.has("--low-health") else 6
			if args.has("--hits"): hit_count = clampi(int(args[args.find("--hits") + 1]), 2, 20)
			for hit in hit_count:
				while game.model.state().hitstop > 0: game.model.step(0, 0)
				for _tick in 5: game.model.step(16 | (4 if hit % 2 else 0), 128 if hit == 0 else 0)
		game.match_score.wins = [1, 1]
		game.round_number = 3
	game._process(0.0)
	var state: Dictionary = game.model.state()
	print("HUD preview HP=", [state.players[0].health, state.players[1].health], " combo=", state.players[0].comboDisplay)
	if args.has("--review"): game.show_sprite_review()
	await process_frame
	await RenderingServer.frame_post_draw
	if args.has("--screenshot"):
		root.get_texture().get_image().save_png(args[args.find("--screenshot") + 1])
	quit()
