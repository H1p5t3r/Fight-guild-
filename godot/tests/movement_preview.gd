extends SceneTree

var model: CombatModel
var arena: Control
var caption: Label
var records: Array = []

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var output := args[args.find("--output") + 1] if args.has("--output") else "user://movement-review"
	var label := args[args.find("--label") + 1] if args.has("--label") else "CURRENT"
	DirAccess.make_dir_recursive_absolute(output)
	model = CombatModel.new()
	var batch: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	var error := model.load_file("res://data/workshop/" + str(batch.file))
	if not error.is_empty(): printerr(error); quit(1); return
	arena = load("res://scripts/arena.gd").new()
	root.add_child(arena)
	arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena.diagnostics = false
	arena.round_label = "MOVEMENT"
	caption = Label.new()
	caption.position = Vector2(24, 116)
	caption.add_theme_font_override("font", GuildTheme.SEMIBOLD)
	caption.add_theme_font_size_override("font_size", 20)
	caption.add_theme_color_override("font_outline_color", Color("10171e"))
	caption.add_theme_constant_override("outline_size", 6)
	root.add_child(caption)
	await process_frame
	for character in [1, 5, 3]:
		model.reset([character, 0])
		model.core.preview_place(0, 36000, 0, 0)
		model.core.preview_place(1, 91000 if character != 3 else 43000, 0, 0)
		for tick in 250:
			var input := 0
			var beat := "IDLE"
			if character == 1:
				if tick >= 20 and tick < 54: input = 2; beat = "WALK"
				elif tick >= 66 and tick < 100: input = 1; beat = "RETREAT"
				elif tick >= 110 and tick < 134: input = 2 | (512 if tick == 110 else 0); beat = "RUN"
				elif tick == 134: input = 16; beat = "RUN INTO 5P"
				elif tick >= 134 and tick < 154: beat = "5P / SETTLE"
				elif tick == 170: input = 8; beat = "JUMP"
				elif tick > 170 and tick < 215: beat = "JUMP / LAND"
			elif character == 5:
				if tick == 20 or tick == 100 or tick == 180: input = 8
				if tick >= 20 and tick < 65: beat = "EMPTY JUMP / LAND"
				elif tick >= 100 and tick < 155: beat = "JUMP INTO j.P / AIR RETURN"
				elif tick >= 180 and tick < 235: beat = "JUMP INTO j.K / LAND"
				if tick == 106: input = 16
				if tick == 186: input = 32
			else:
				if tick == 16: model.core.preview_begin(0, 13)
				if tick >= 16 and tick < 90: beat = "HEADBUTT INTO ROLLING STANCE"
				elif tick >= 90 and tick < 115: beat = "STANCE IDLE"
				elif tick >= 115 and tick < 140: input = 1; beat = "STANCE RETREAT"
				elif tick >= 148 and tick < 170: input = 2; beat = "STANCE ADVANCE"
				elif tick >= 178 and tick < 210: beat = "STANCE HOOK / RETURN"
				elif tick >= 216: beat = "STANCE EXIT / SETTLE"
				if tick == 178: input = 64
				if tick == 216: input = 4 | 256
			model.step(input, 0)
			var state := model.state()
			var f: Dictionary = state.players[0]
			records.append({"character":character,"tick":tick,"hash":model.state_hash(),"input":input,"x":f.x,"y":f.y,"move":f.move,"phase":f.posePhase,"pose":f.poseIndex})
			caption.text = "%s / %s\n%s   •   60 FPS" % [label, CombatModel.CHARACTERS[character].to_upper(), beat]
			arena.refresh(model, state, false, false)
			await process_frame
			await RenderingServer.frame_post_draw
			if tick in [0, 24, 40, 54, 80, 108, 115, 130, 142, 158, 178, 188, 218, 230]:
				root.get_texture().get_image().save_png(output.path_join("%d-%03d.png" % [character, tick]))
	var file := FileAccess.open(output.path_join("states.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(records))
	print("Native movement review: 750 simulation frames captured")
	quit()
