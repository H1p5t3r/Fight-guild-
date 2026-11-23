extends SceneTree

var arena: Control
var audio: CombatAudio
var model := CombatModel.new()
var caption: Label

func _initialize() -> void: call_deferred("run")

func run() -> void:
	# Match a normal game boot, including the latest authored workshop data.
	var batch: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	var load_error := model.load_file("res://data/workshop/" + str(batch.file))
	if not load_error.is_empty():
		printerr(load_error); quit(1); return
	arena = load("res://scripts/arena.gd").new()
	root.add_child(arena)
	arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena.diagnostics = false
	audio = CombatAudio.new(); root.add_child(audio)
	caption = Label.new(); caption.position = Vector2(28, 650)
	caption.add_theme_font_override("font", GuildTheme.SEMIBOLD)
	caption.add_theme_font_size_override("font_size", 24)
	root.add_child(caption)
	await process_frame
	var args := OS.get_cmdline_user_args()
	var verify_only := args.has("--verify")
	var directory := args[args.find("--output") + 1] if args.has("--output") else "user://"
	DirAccess.make_dir_recursive_absolute(directory)
	var cases := [
		[5,3,"cut","KNIFE / HIT",0,false], [1,3,"blunt","HAMMER / HIT",0,false],
		[4,2,"pierce","SPEAR / HIT",0,true], [2,16,"fire","FLAME / HIT",0,false],
		[2,15,"gas","POISON / HIT",0,false], [5,3,"block","BLOCK",2,false],
		[5,3,"faultless","FAULTLESS DEFENSE",2050,false], [1,3,"counter","COUNTER HIT",0,false],
		[2,16,"guard_break","GUARD BREAK",2,false], [4,7,"multi","TWO-HIT SCOOP",0,false],
		[5,7,"air","AIRBORNE CONTACT",0,false]]
	var failures := 0
	for example in cases:
		model.reset([int(example[0]), 4 if int(example[0]) != 4 else 5])
		var facing := -1 if example[5] else 1
		model.core.preview_place(0, 50000 - facing * 4500, 0, 10000)
		model.core.preview_place(1, 50000 + facing * 4500, 0, 10000)
		model.step(0, 0)
		caption.text = "INK SNAP  /  " + str(example[3]) + "  /  60 FPS"
		arena.round_label = "IMPACT REVIEW"
		var saved := false
		var contacts := 0
		var required_kind: int = {"block":2,"faultless":6,"counter":3,"guard_break":5}.get(example[2],1)
		var startup: int = model.move(int(example[0]), int(example[1])).startup
		for tick in 110:
			if tick == 16: model.core.preview_begin(0, int(example[1]))
			if example[2] == "counter" and tick == 16 + startup - 3: model.core.preview_begin(1, 3)
			# Hold position until contact: walking back through the entire lead-in
			# would turn a block demonstration into a legitimate spacing whiff.
			var guard := int(example[4]) if tick >= 16 + startup - 2 else 0
			if facing < 0 and guard: guard = (guard & ~2) | 1
			if example[2] == "air" and tick >= 16 and tick <= 20: guard = 8
			model.step(0, guard)
			for event in model.cues.events_at(model.frame() - 1):
				if not verify_only: audio.play_cue(event)
				if int(event.kind) == required_kind: contacts += 1
			if verify_only: continue
			arena.refresh(model, model.state(), false, false)
			await process_frame
			await RenderingServer.frame_post_draw
			if not saved and model.cues.visible_at(model.frame()).any(func(c: Dictionary) -> bool: return c.kind == required_kind):
				root.get_texture().get_image().save_png(directory.path_join(str(example[2]) + ".png"))
				saved = true
		var enough := contacts >= (2 if example[2] == "multi" else 1)
		if not enough or (not verify_only and not saved): failures += 1
		print("Review ", example[2], ": ", contacts, " contacts; ", "verified" if verify_only else "captured" if saved else "MISSING")
	print("Native impact review: %d failures" % failures)
	quit(1 if failures else 0)
