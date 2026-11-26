extends SceneTree

var game: Control
var trials: ComboTrialsWindow
var output := ""
var quick := false
var frames := 0
func _initialize() -> void: call_deferred("run")

func frame() -> void:
	trials.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	frames += 1

func capture(name: String) -> void:
	root.get_texture().get_image().save_png(output.path_join(name + ".png"))

func run() -> void:
	var args := OS.get_cmdline_user_args()
	quick = args.has("--quick")
	output = args[args.find("--output") + 1]
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.motion.instant = true
	game.finish_menu_motion()
	game.set_physics_process(false)
	await process_frame
	await RenderingServer.frame_post_draw
	capture("00-home")
	game.open_combo_trials()
	trials = game.combo_trials
	trials.set_physics_process(false)
	trials.focused = true
	await frame()
	await frame()
	capture("01-ready")
	for character in [5, 2, 4, 3, 1, 0]:
		trials.choose_fighter(character)
		trials.begin(true)
		trials.focused = true
		while trials.session.running():
			trials.tick(0)
			if not quick or trials.session.clock in [-30, 20, 40, 70] or not trials.session.running():
				await frame()
			if trials.session.clock == 20: capture("%d-chart" % character)
		if trials.session.state != "success": printerr("Demo failed: ", trials.session.failure); quit(1); return
		for _tick in (1 if quick else 45): await frame()
		capture("%d-complete" % character)
	# Show a genuine failed attempt, then a full successful player-input replay.
	trials.choose_fighter(3)
	trials.begin(false)
	for tick in 122:
		trials.tick(68 if tick > 119 else 0)
		if not quick: await frame()
	await frame()
	capture("07-wrong-direction")
	if not quick:
		for _tick in 60: await frame()
	trials.begin(false)
	while trials.session.running():
		var next := trials.session.clock + 1
		trials.tick(trials.session.inputs[next - 1] if next > 0 and next <= trials.session.inputs.size() else 0)
		if not quick: await frame()
	await frame()
	capture("08-clear")
	if not quick:
		for _tick in 75: await frame()
	print("Native rhythm review: 0 failures / ", frames, " frames")
	trials.close()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
