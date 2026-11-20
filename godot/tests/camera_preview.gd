extends SceneTree

var game
var capture_dir := ""
func _initialize() -> void: call_deferred("run")

func capture(label: String) -> void:
	game._process(0.0)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(capture_dir.path_join(label + ".png"))
	var heights := []
	for p in 2:
		var sprite: Sprite2D = game.arena.sprites[p]
		var info := FighterArt.sheet(game.characters[p], sprite.get_meta("phase"))
		var art: Array = info.frames[int(sprite.get_meta("pose"))].bounds
		heights.append(snappedf((art[3] - art[1]) * sprite.scale.y / game.get_viewport_rect().size.y * 100.0, 0.1))
	print(label, " window=", root.size, " viewport=", game.get_viewport_rect().size, " arena=", game.arena.size, " zoom=", game.arena.camera_zoom, " silhouette%=", heights)

func run() -> void:
	var args := OS.get_cmdline_user_args()
	capture_dir = args[args.find("--captures") + 1] if args.has("--captures") else "user://"
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	game.motion.instant = true
	game.motion.reduced = args.has("--reduced")
	game.choose_activity("development" if args.has("--editor") else "local")
	game.confirm_selection()
	await game.wait_for_match_entry()
	await capture("neutral")
	for _tick in 22: game.model.step(8, 0)
	await capture("jump")
	game.model.reset(game.characters)
	for _tick in 22: game.model.step(8, 8)
	await capture("air-duel")
	game.model.reset(game.characters)
	for _tick in 220: game.model.step(1, 2)
	await capture("wide")
	game.model.reset(game.characters)
	for _tick in 220: game.model.step(2, 2)
	await capture("corner")
	game.show_boxes = true
	await capture("collision")
	game.show_boxes = false
	game.model.reset(game.characters)
	game.model.step(4, 0)
	game.model.step(4 | 2, 0)
	game.model.step(2 | 64, 0)
	for _tick in 12: game.model.step(0, 0)
	await capture("rekka")
	quit()
