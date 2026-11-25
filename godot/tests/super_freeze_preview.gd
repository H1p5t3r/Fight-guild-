extends SceneTree

# Actual renderer at 60 Hz. This fixture freezes core stepping for the cut-in;
# it never assigns a super move or modifies an attack for the recording.
var model := CombatModel.new()
var arena: Control
var cut_in: SuperFreeze
var caption: Label
var output := ""
var stills := false
var failed := false
var inset := false
const INSPECTION_TICKS := [0, 3, 6, 10, 14, 20, 34, 39, 44, 49, 52, 53]

func _initialize() -> void: call_deferred("run")

func draw_frame() -> void:
	arena.refresh(model, model.state(), false, false)
	await process_frame
	await RenderingServer.frame_post_draw

func save_still(name: String) -> void:
	if not output.is_empty():
		if root.get_texture().get_image().save_png(output.path_join(name + ".png")) != OK: failed = true

func check_intact_screen(before: Image, description: String) -> void:
	var after := root.get_texture().get_image()
	var mismatches := 0
	for y in range(7, before.get_height(), 29):
		for x in range(7, before.get_width(), 29):
			var a := before.get_pixel(x, y)
			var b := after.get_pixel(x, y)
			if maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b))) > 0.009: mismatches += 1
	if mismatches > 0:
		failed = true
		printerr("Tear did not restore the frozen screen: %s (%d pixels)" % [description, mismatches])

func check_outside_arena(before: Image) -> void:
	var after := root.get_texture().get_image()
	var scale := Vector2(before.get_size()) / root.get_visible_rect().size
	var rect: Rect2 = arena.get_global_rect()
	rect = Rect2(rect.position * scale, rect.size * scale).grow(2)
	for y in range(7, before.get_height(), 29):
		for x in range(7, before.get_width(), 29):
			if not rect.has_point(Vector2(x, y)) and before.get_pixel(x, y) != after.get_pixel(x, y):
				failed = true
				printerr("Screen tear changed a pixel outside the training arena")
				return

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.has("--output"): output = args[args.find("--output") + 1]
	stills = args.has("--stills")
	inset = args.has("--inset")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	var error := model.load_file("res://data/workshop/" + data.file)
	if not error.is_empty(): printerr(error); quit(1); return
	var canvas := Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(canvas)
	arena = load("res://scripts/arena.gd").new()
	arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena.diagnostics = false
	arena.round_label = "1ST SCRUM"
	canvas.add_child(arena)
	if inset:
		arena.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		arena.position = Vector2(90, 160)
		arena.size = root.get_visible_rect().size - Vector2(180, 240)
	cut_in = SuperFreeze.new()
	arena.add_child(cut_in)
	caption = Label.new()
	caption.position = Vector2(24, 125)
	caption.add_theme_font_override("font", InkMenu.FONT)
	caption.add_theme_font_size_override("font_size", 20)
	caption.add_theme_color_override("font_color", Color("fff7e8"))
	caption.add_theme_color_override("font_outline_color", Color("08090d"))
	caption.add_theme_constant_override("outline_size", 6)
	canvas.add_child(caption)
	await process_frame
	for character in [5, 4, 2, 3, 1, 0]:
		var player := 1 if character % 2 == 0 else 0
		model.reset([character if player == 0 else (character + 1) % 6, character if player == 1 else (character + 1) % 6])
		caption.text = "SUPER FREEZE STUDY / %s / %s" % [CombatModel.CHARACTERS[character].to_upper(), "P1" if player == 0 else "P2"]
		for tick in (1 if stills else 24):
			model.step(0, 0)
			await draw_frame()
		var snapshot: PackedByteArray = model.core.snapshot()
		var fighter: Dictionary = model.state().players[player]
		var intact := root.get_texture().get_image()
		var frames: Array = INSPECTION_TICKS if stills else range(SuperFreeze.DEFAULT_TICKS)
		for tick in frames:
			cut_in.present(character, int(fighter.facing), tick)
			await draw_frame()
			if tick == 20: save_still(CombatModel.CHARACTERS[character].to_lower())
			if tick == 20 and inset: check_outside_arena(intact)
			if character == 5 and tick in INSPECTION_TICKS: save_still("fillet-%02d" % tick)
			if tick in [0, 53]: check_intact_screen(intact, "%s / %d" % [CombatModel.CHARACTERS[character], tick])
			if model.core.snapshot() != snapshot: failed = true
		cut_in.clear()
		for tick in (1 if stills else 24):
			model.step(0, 0)
			await draw_frame()
	# Same effect with all travel/tearing suppressed by Reduced Motion.
	model.reset([5, 4])
	cut_in.reduced_motion = true
	caption.text = "SUPER FREEZE STUDY / REDUCED MOTION"
	await draw_frame()
	var intact := root.get_texture().get_image()
	var reduced_frames: Array = [0, 20, 53] if stills else range(SuperFreeze.DEFAULT_TICKS)
	for tick in reduced_frames:
		cut_in.present(5, 1, tick)
		await draw_frame()
		if tick == 20: save_still("reduced")
		if tick in [0, 53]: check_intact_screen(intact, "Reduced Motion / %d" % tick)
	cut_in.clear()
	print("Native super freeze review: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
