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
	game.open_combo_trials()
	trials = game.combo_trials
	trials.set_physics_process(false)
	trials.focused = true
	for spec in [
		["01-correct", 3, 1, "ON TIME"],
		["02-early-buffer", 5, 16, "EARLY"],
		["03-late", 3, 4, "LATE"],
		["04-wrong-button", 3, 1, "WRONG INPUT"],
		["05-wrong-direction", 3, 1, "WRONG INPUT"],
		["06-missed", 3, 12, "MISSED"],
		["07-early-release", 2, 2, "RELEASED EARLY"],
		["08-mirrored", 4, 1, "ON TIME"]]:
		trials.side_picker.select(1 if spec[0] == "08-mirrored" else 0)
		trials.choose_fighter(int(spec[1]))
		trials.begin(false)
		while trials.session.clock < 0: trials.tick(0)
		for tick in int(spec[2]):
			var raw := 0
			match str(spec[0]):
				"01-correct": raw = 64
				"02-early-buffer": raw = 64 if tick == 0 else 130 if tick == 12 else 0
				"03-late": raw = 64 if tick == 3 else 0
				"04-wrong-button": raw = 16
				"05-wrong-direction": raw = 68
				"07-early-release": raw = 256 if tick == 0 else 0
				"08-mirrored": raw = 65
			trials.input_raw = raw
			trials.tick(raw)
			if not quick: await frame()
		await frame()
		if trials.session.actual_notes.is_empty() or trials.session.actual_notes[-1].judge != str(spec[3]):
			printerr("Unexpected feedback in ", spec[0], ": ", trials.session.actual_notes)
			quit(1); return
		root.get_texture().get_image().save_png(output.path_join(str(spec[0]) + ".png"))
		# Hold each actual resolved input frame for inspection in the review.
		if not quick:
			for _tick in 85: await frame()
	print("Native rhythm review: 0 failures / ", frames, " frames / eight real-input feedback cases")
	trials.close()
	game.queue_free()
	await process_frame
	# Rapid screenshot-only theme changes leave decoder retirement work on the
	# audio thread. Let it drain before shutting down the review process.
	await create_timer(0.5).timeout
	quit()
