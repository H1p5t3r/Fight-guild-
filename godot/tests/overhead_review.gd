extends SceneTree

var model := CombatModel.new()
var arena: Control
var audio: CombatAudio
var caption: Label
var detail: Label
var failures := 0
var verify := false
var directory := "user://"

func _initialize() -> void: call_deferred("run")
func present(name: String = "") -> void:
	if verify: return
	arena.refresh(model,model.state(),false,false)
	# Half-speed review only: the simulation still uses its authored frame data.
	for repeat in 2:
		await process_frame
		await RenderingServer.frame_post_draw
	if not name.is_empty(): root.get_texture().get_image().save_png(directory.path_join(name + ".png"))

func run() -> void:
	var args := OS.get_cmdline_user_args()
	verify = args.has("--verify")
	if args.has("--output"): directory = args[args.find("--output")+1]
	DirAccess.make_dir_recursive_absolute(directory)
	var batch: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	if not model.load_file("res://data/workshop/" + str(batch.file)).is_empty(): quit(1); return
	arena = load("res://scripts/arena.gd").new(); root.add_child(arena)
	arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena.diagnostics = false; arena.round_label = "OVERHEAD"
	audio = CombatAudio.new(); root.add_child(audio)
	caption = Label.new(); caption.position = Vector2(28,142)
	caption.add_theme_font_override("font",CombatTypography.FONT)
	caption.add_theme_font_size_override("font_size",23)
	caption.add_theme_color_override("font_outline_color",Color("11161d")); caption.add_theme_constant_override("outline_size",4)
	root.add_child(caption)
	detail = Label.new(); detail.position = Vector2(28,172)
	detail.add_theme_font_override("font",GuildTheme.SEMIBOLD); detail.add_theme_font_size_override("font_size",17)
	detail.add_theme_color_override("font_color",Color("ffe2a2")); detail.add_theme_constant_override("outline_size",3)
	root.add_child(detail)
	await process_frame
	# character, move, name, caption, air height, crouch guard, mirrored, hold D
	var examples := [
		[5,26,"fillet","FILLET / CROWN CUT",0,true,false,false],
		[1,15,"hammer","HAMMER / OVERHEAD SPECIAL",0,false,true,false],
		[3,38,"tapper","TAPPER / STANCE OVERHEAD",0,false,false,false],
		[2,13,"smoke","SMOKE / UNCHARGED OVERHEAD",0,false,false,false],
		[2,13,"charge","SMOKE / HELD OVERHEAD",0,false,false,true],
		[4,20,"shark-air","SHARK / JUMP ATTACK - NO AMBER WARNING",11000,false,true,false],
		[0,20,"anvil-air","ANVIL / JUMP ATTACK - NO AMBER WARNING",14000,false,false,false],
		[5,6,"low-control","LOW SWEEP / NO AMBER WARNING",0,true,false,false]]
	for example in examples:
		model.reset([example[0],4 if example[0] != 4 else 5])
		var direction := -1 if example[6] else 1
		var actor_x := 50000-direction*4500
		model.core.preview_place(0,actor_x,0,10000)
		model.core.preview_place(1,50000+direction*4500,0,10000)
		model.step(0,0)
		caption.text = example[3]
		detail.text = "HALF-SPEED REVIEW / LOW GUARD BLOCKS THE SWEEP" if example[2] == "low-control" else "HALF-SPEED REVIEW / CROUCH GUARD LOSES TO THE OVERHEAD" if example[5] else "HALF-SPEED REVIEW / STANDING GUARD BLOCKS THE OVERHEAD"
		if example[4] > 0: detail.text = "HALF-SPEED REVIEW / AMBER IS RESERVED FOR OVERHEADS THAT START ON THE GROUND"
		var seen := false
		var contacts := 0
		var saved := false
		var required_kind := 1 if example[5] and example[2] != "low-control" else 2
		for tick in 100:
			if tick == 16:
				if example[4] > 0: model.core.preview_place(0,actor_x,example[4],10000)
				model.core.preview_begin(0,example[1])
			var actor: Dictionary = model.state().players[0]
			var guard := 0
			if actor.move >= 0:
				var move := model.move(actor.character,actor.move)
				var threshold := int(move.startup)-2
				if example[7] and move.actionType == 5: threshold = maxi(move.startup,move.holdFrame)-2
				if actor.age >= threshold: guard = (1 if direction < 0 else 2) | (4 if example[5] else 0)
			model.step(256 if example[7] and tick >= 16 else 0,guard)
			if not verify: audio.consume(model,model.frame()-1,true)
			var cues := CombatOverhead.describe(model,model.state())
			seen = seen or not cues.is_empty()
			for event in model.cues.events_at(model.frame()-1):
				if int(event.kind) == required_kind: contacts += 1
			var mark := ""
			if example[4] > 0 and tick == 20: mark = str(example[2])+"-startup"
			if not cues.is_empty() and int(cues[0].age) >= 4 and not saved:
				mark = str(example[2])+"-warning"; saved = true
			if tick in [28,55,94]: mark = str(example[2])+"-"+str(tick)
			await present(mark)
		var expected_warning: bool = example[2] != "low-control" and example[4] == 0
		if seen != expected_warning or contacts == 0 or not CombatOverhead.describe(model,model.state()).is_empty(): failures += 1
		print("Overhead review ",example[2],": cue=",seen," contact kind=",required_kind," count=",contacts)
	print("Native overhead review: %d failures" % failures)
	quit(1 if failures else 0)
