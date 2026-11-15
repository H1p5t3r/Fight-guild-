extends SceneTree

# Native visual review: --fighters / --online / --training / --mirror and --screenshot PATH.
var game: Control

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	var args := OS.get_cmdline_user_args()
	if args.has("--tour"):
		await tour()
		quit()
		return
	if args.has("--fighters") or args.has("--online") or args.has("--training") or args.has("--mirror"):
		game.choose_activity("online" if args.has("--online") else "training" if args.has("--training") else "local")
		game.menus.selection.choose_fighter(0, 0)
		game.menus.selection.choose_fighter(1, 0 if args.has("--mirror") else 4)
	for p in 2:
		var flag := "--p" + str(p + 1)
		if args.has(flag): game.menus.selection.choose_fighter(p, int(args[args.find(flag) + 1]))
	await game.wait_for_menu_motion()
	await process_frame
	if args.has("--layout"): dump(game.menus, 0)
	if args.has("--screenshot"):
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(args[args.find("--screenshot") + 1])
	quit()

func dump(node: Node, level: int) -> void:
	if node is Control and node.is_visible_in_tree(): print("  ".repeat(level), node.get_class(), " ", node.size, " at=", node.position, " min=", node.get_combined_minimum_size())
	if level < 10:
		for child in node.get_children(): dump(child, level + 1)

func tour() -> void:
	# --write-movie PATH.avi --fixed-fps 60 records these real native transitions.
	await create_timer(0.8).timeout
	game.menu_action("matches")
	await create_timer(0.65).timeout
	game.menu_action("local")
	await create_timer(1.0).timeout
	game.menus.selection.tiles[2].grab_focus()
	await create_timer(0.6).timeout
	game.menus.selection.tiles[4].grab_focus()
	await create_timer(0.6).timeout
	game.menus.selection.slot_buttons[1].pressed.emit()
	game.menus.selection.tiles[5].grab_focus()
	await create_timer(0.9).timeout
	game.confirm_selection()
	await game.wait_for_match_entry()
	await create_timer(0.8).timeout
	game.open_pause()
	await create_timer(0.7).timeout
	game.go_home()
	await create_timer(0.7).timeout
