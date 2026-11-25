extends SceneTree

var model := CombatModel.new()
var arena: Control
var freeze: SuperFreeze
var audio: CombatAudio
var caption: Label
var output := ""
var quick := false
var failures := 0
var entry: Dictionary

func _initialize() -> void: call_deferred("run")

func show_frame(mark: String) -> void:
	var state := model.state()
	var saved: PackedByteArray = model.core.snapshot()
	arena.refresh(model,state,false,false)
	if model.core.snapshot()!=saved: failures+=1
	if int(state.superFreezeTime)>0:
		var actor: Dictionary = state.players[int(state.superFreezeActor)]
		freeze.present(int(actor.character),int(actor.facing),int(state.superFreezeDuration)-int(state.superFreezeTime),int(state.superFreezeDuration),entry.name)
	else: freeze.clear()
	await process_frame
	await RenderingServer.frame_post_draw
	if not mark.is_empty():root.get_texture().get_image().save_png(output.path_join(mark+".png"))

func run() -> void:
	var args := OS.get_cmdline_user_args()
	quick=args.has("--stills")
	SuperAnimation.enabled=not args.has("--baseline")
	var character := int(args[args.find("--character")+1]) if args.has("--character") else 0
	var slot := int(args[args.find("--slot")+1]) if args.has("--slot") else 31
	entry=CombatSupers.info(character,slot)
	output=args[args.find("--output")+1] if args.has("--output") else "user://super-review"
	DirAccess.make_dir_recursive_absolute(output)
	var batch: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	var error:=model.load_file("res://data/workshop/"+str(batch.file))
	if not error.is_empty():printerr(error);quit(1);return
	root.size=Vector2i(1280,720)
	arena=load("res://scripts/arena.gd").new();root.add_child(arena)
	arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena.diagnostics=false;arena.round_label=entry.name.to_upper()
	freeze=SuperFreeze.new();arena.add_child(freeze)
	if args.has("--baseline"):freeze.move_portraits.clear()
	audio=CombatAudio.new();root.add_child(audio)
	caption=Label.new();caption.position=Vector2(28,116)
	caption.add_theme_font_override("font",CombatTypography.FONT)
	caption.add_theme_font_size_override("font_size",23)
	caption.add_theme_constant_override("outline_size",6);root.add_child(caption)
	await process_frame
	var examples: Array=[[0,4,1,"hit"],[1,5,-1,"mirrored"],[0,4,1,"block"],[0,4,1,"whiff"]]
	if args.has("--baseline"):examples=[examples[0]]
	var move:=model.move(character,slot)
	for example in examples:
		var owner:=int(example[0]);var facing:=int(example[2]);var id:=str(example[3])
		model.reset([character,int(example[1])] if owner==0 else [int(example[1]),character])
		model.core.preview_place(owner,50000-facing*(33000 if id=="whiff" else 6000),0,10000)
		model.core.preview_place(1-owner,50000+facing*(33000 if id=="whiff" else 6000),0,0)
		caption.text="%s  /  %s  /  %s" % [entry.name.to_upper(),entry.input,"BEFORE" if args.has("--baseline") else id.to_upper()+" / 60 FPS"]
		await show_frame(id+"-idle")
		if not quick:
			for tick in 24:await show_frame("")
		model.core.preview_begin(owner,slot)
		var stamps:={};var saw_pair:=false
		for tick in 290:
			var state:=model.state();var actor:Dictionary=state.players[owner]
			saw_pair=saw_pair or int(state.pairKind)>0
			var mark:=""
			if tick==20:mark="cutin"
			elif int(actor.age)==int(move.startup)-1 and int(actor.move)==slot:mark="last-load"
			elif int(state.pairKind)>0 and int(state.pairClock) in [0,16,27,40,58,70,84]:mark="pair-%03d"%int(state.pairClock)
			elif int(actor.pairRecovery)>0 and int(actor.pairRecovery) in [24,17,7]:mark="recovery-%02d"%int(actor.pairRecovery)
			elif int(actor.age)==int(move.startup) and int(actor.move)==slot:mark="active"
			elif tick==260:mark="settled"
			if stamps.has(mark):mark=""
			if not mark.is_empty():stamps[mark]=true
			audio.consume(model,model.frame()-1,not quick)
			if not quick or not mark.is_empty():await show_frame(id+"-"+mark if not mark.is_empty() else "")
			var guard:=2 if facing>0 else 1
			model.step(guard if id=="block" and owner==1 else 0,guard if id=="block" and owner==0 else 0)
		var damage:=1000-int(model.state().players[1-owner].health)
		var hit:=id in ["hit","mirrored"]
		if saw_pair!=hit or (hit and damage!=int(move.damage)) or (id=="whiff" and damage!=0):failures+=1
		print(entry.name," / ",id," / damage ",damage," / paired ",saw_pair)
	print("Super animation review: %d failures"%failures)
	quit(1 if failures else 0)
