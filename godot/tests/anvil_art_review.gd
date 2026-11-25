extends SceneTree

var arena: Control
var caption: Label
func _initialize() -> void: call_deferred("run")

func run() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	var model := PairedThrowFixtures.create()
	arena = load("res://scripts/arena.gd").new()
	root.add_child(arena)
	arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena.diagnostics = false
	arena.round_label = "ANVIL / BULL"
	caption = Label.new()
	caption.position = Vector2(24, 114)
	caption.add_theme_font_override("font", GuildTheme.SEMIBOLD)
	caption.add_theme_font_size_override("font_size", 22)
	caption.add_theme_color_override("font_outline_color", Color("10171e"))
	caption.add_theme_constant_override("outline_size", 6)
	root.add_child(caption)
	var args := OS.get_cmdline_user_args()
	var stills := args.has("--stills")
	var output: String = args[args.find("--output")+1]
	DirAccess.make_dir_recursive_absolute(output)
	# Real input/move data, fixed 60 Hz. Whiff and contact are labeled separately.
	var cases := [[-1,"IDLE → WALK → STEP DASH",1], [13,"BULWARK / HOLD + ADVANCE",1],
		[0,"5P / HIT",1],[2,"f.S / BLOCK",1],[3,"5Hs / WHIFF",1],[6,"2S / HIT",-1],
		[8,"6P / WHIFF",1],[28,"IRON ADVANCE / HIT",1],[21,"j.D / FALLING BULWARK",1],
		[14,"63214P / FOUNDRY DROP",1],[15,"63214K / IRON TURN",-1],[16,"63214Hs / SKY FOUNDRY",1]]
	for example in cases:
		var slot := int(example[0])
		var facing := int(example[2])
		model.reset([0,4])
		var gap := 45000 if slot in [3,8,-1,13] else 14000 if slot == 2 else 6000 if slot in [14,15,16] else 11000
		model.core.preview_place(0, 50000-facing*gap/2, 16000 if slot == 21 else 0, 10000)
		model.core.preview_place(1, 50000+facing*gap/2, 16000 if slot == 16 else 0, 0)
		model.step(0,0)
		var saved := false
		var blocked := false
		for tick in (250 if slot == 16 else 190):
			if tick == 15 and slot >= 0:
				# Set the airborne setup at activation, after the neutral lead-in.
				if slot == 16: model.core.preview_place(1, 50000+facing*gap/2, 16000, 0)
				if slot == 21: model.core.preview_place(0, 50000-facing*gap/2, 24000, 10000)
				model.core.preview_begin(0,slot)
			var input := 0
			if slot == -1:
				if tick >= 30 and tick < 90: input=2
				elif tick >= 105 and tick < 135: input=1
				elif tick == 150: input=514
			if slot == 13 and tick >= 15 and tick < 135: input=256+(2 if tick>=45 else 0)
			model.step(input,2 if slot == 2 and tick >= 15 else 0)
			var state := model.state()
			blocked = blocked or bool(state.players[1].guarding)
			caption.text = str(example[1])+"\nNATIVE BUILD · 60 FPS · ORIGINAL GAMEPLAY TIMING"
			var chosen := tick == 22 if slot in [0,2,3,6,8] else tick == 82 if slot == 13 else tick == 20 if slot == -1 else tick == 72 if slot in [14,15] else tick == 110 if slot == 16 else tick == 43
			if stills and not chosen: continue
			arena.refresh(model,state,false,false)
			await process_frame
			await RenderingServer.frame_post_draw
			if chosen and not saved:
				root.get_texture().get_image().save_png(output.path_join("anvil-%d.png"%slot))
				saved=true
		if (slot == 2 and not blocked) or (slot in [0,6,28,21,14,15,16] and model.state().players[1].health == 1000) or (slot in [3,8] and model.state().players[1].health != 1000):
			printerr("Anvil review contact did not match its label: " + str(example[1]))
			quit(1)
			return
	print("Anvil native review complete")
	quit()
