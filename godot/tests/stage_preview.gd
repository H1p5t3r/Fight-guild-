extends SceneTree

const Fixture = preload("res://tests/stage_fixture.gd")
var game
var args: PackedStringArray
var capture_dir := ""
var quick := false
func _initialize() -> void: call_deferred("run")

func frame() -> void:
	game._process(0.0)
	await process_frame
	await RenderingServer.frame_post_draw

func hold(count: int) -> void:
	for _tick in (1 if quick else count): await frame()

func capture(name: String) -> void:
	if not capture_dir.is_empty(): root.get_texture().get_image().save_png(capture_dir.path_join(name + ".png"))

func run() -> void:
	args = OS.get_cmdline_user_args()
	quick = args.has("--quick")
	if args.has("--captures"): capture_dir = args[args.find("--captures") + 1]
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	game.motion.instant = true
	game.motion.reduced = args.has("--reduced")
	game.choose_activity("local")
	game.confirm_selection()
	await game.wait_for_match_entry()
	for side in [1, -1]:
		Fixture.configure(game.model)
		await hold(45)
		capture("charter-center")
		for _tick in 220:
			game.model.step(2 if side > 0 else 1, 2 if side > 0 else 1)
			if not quick: await frame()
		await frame()
		capture("charter-right" if side > 0 else "charter-left")
		if not Fixture.splat(game.model, side): printerr("Preview failed to splat"); quit(1); return
		await hold(28)
		if not Fixture.breach(game.model, side): printerr("Preview failed to breach"); quit(1); return
		for tick in int(game.model.state().wallBreakDuration):
			if not quick or tick in [0, 40, 75, 99, 100, 130, 149]: await frame()
			if tick in [0, 40, 75, 99, 100, 130, 149]: capture("%s-travel-%03d" % ["right" if side > 0 else "left", tick])
			game.model.step(0, 0)
		await hold(80)
		capture("quay" if side > 0 else "foundry")
		for _tick in 100:
			game.model.step(1, 1)
			if not quick: await frame()
		await hold(35)
	quit()
