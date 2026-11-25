extends SceneTree

var model := CombatModel.new()
var arena: Control
var freeze: SuperFreeze
var audio: CombatAudio
var caption: Label
var output := ""
var quick := false
var failures := 0

func _initialize() -> void: call_deferred("run")

func show_frame(mark: String) -> void:
	var state := model.state()
	var saved: PackedByteArray = model.core.snapshot()
	arena.refresh(model,state,false,false)
	if model.core.snapshot() != saved: failures += 1
	if int(state.superFreezeTime)>0:
		var actor: Dictionary = state.players[int(state.superFreezeActor)]
		freeze.present(int(actor.character),int(actor.facing),int(state.superFreezeDuration)-int(state.superFreezeTime),int(state.superFreezeDuration),"Sky Foundry")
	else: freeze.clear()
	await process_frame
	await RenderingServer.frame_post_draw
	if not mark.is_empty(): root.get_texture().get_image().save_png(output.path_join(mark+".png"))

func run() -> void:
	var args := OS.get_cmdline_user_args()
	quick = args.has("--stills")
	SuperAnimation.enabled = not args.has("--baseline")
	output = args[args.find("--output")+1] if args.has("--output") else "user://sky-foundry"
	DirAccess.make_dir_recursive_absolute(output)
	var batch: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	var error := model.load_file("res://data/workshop/"+str(batch.file))
	if not error.is_empty(): printerr(error);quit(1);return
	root.size = Vector2i(1280,720)
	arena = load("res://scripts/arena.gd").new(); root.add_child(arena)
	arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena.diagnostics = false; arena.round_label = "SKY FOUNDRY"
	freeze = SuperFreeze.new(); arena.add_child(freeze)
	if args.has("--baseline"): freeze.move_portraits.clear()
	audio = CombatAudio.new(); root.add_child(audio)
	caption = Label.new(); caption.position = Vector2(28,116)
	caption.add_theme_font_override("font",CombatTypography.FONT)
	caption.add_theme_font_size_override("font_size",23)
	caption.add_theme_constant_override("outline_size",6)
	root.add_child(caption)
	await process_frame
	var examples := [[0,4,1,"catch"],[1,5,-1,"mirrored"],[0,4,1,"grounded-miss"]]
	if args.has("--baseline"): examples = [examples[0]]
	for example in examples:
		var owner := int(example[0]);var facing := int(example[2]);var id := str(example[3])
		model.reset([0,int(example[1])] if owner==0 else [int(example[1]),0])
		model.core.preview_place(owner,50000-facing*5000,0,10000)
		model.core.preview_place(1-owner,50000+facing*5000,0 if id=="grounded-miss" else 16000,0)
		caption.text = "SKY FOUNDRY  /  63214Hs  /  " + ("GROUNDED TARGET IS SAFE" if id=="grounded-miss" else "60 FPS  /  " + ("BEFORE" if args.has("--baseline") else "FULL ANIMATION"))
		await show_frame(id+"-idle")
		if not quick:
			for tick in 30: await show_frame("")
		model.core.preview_begin(owner,16)
		var stamps := {}
		var saw_pair := false
		for tick in 290:
			var state := model.state(); var actor: Dictionary = state.players[owner]
			saw_pair = saw_pair or int(state.pairKind)>0
			var mark := ""
			if tick == 20: mark="cutin"
			elif tick == 58: mark="load"
			elif int(state.pairKind)>0 and int(state.pairClock) in [0,12,30,58,88,100,111]: mark="pair-%03d" % int(state.pairClock)
			elif int(actor.pairRecovery)>0 and int(actor.pairRecovery) in [24,20,16,9,3]: mark="recovery-%02d" % int(actor.pairRecovery)
			elif tick==260: mark="settled"
			if stamps.has(mark): mark=""
			if not mark.is_empty(): stamps[mark]=true
			audio.consume(model,model.frame()-1,not quick)
			if not quick or not mark.is_empty(): await show_frame(id+"-"+mark if not mark.is_empty() else "")
			model.step(0,0)
		var damage := 1000-int(model.state().players[1-owner].health)
		var expected := 0 if id=="grounded-miss" else 333
		if damage!=expected or saw_pair!=(expected>0): failures+=1
		print("Sky Foundry / ",id," / damage ",damage," / paired ",saw_pair)
	print("Sky Foundry review: %d failures" % failures)
	quit(1 if failures else 0)
