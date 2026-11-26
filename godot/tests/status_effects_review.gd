extends SceneTree

var model := CombatModel.new()
var arena: Control
var audio: CombatAudio
var caption: Label
var failures := 0
var directory := "user://"
var verify := false

func _initialize() -> void: call_deferred("run")
func present(name: String = "") -> void:
	if verify: return
	arena.refresh(model, model.state(), false, false)
	await process_frame
	await RenderingServer.frame_post_draw
	if not name.is_empty(): root.get_texture().get_image().save_png(directory.path_join(name + ".png"))

func run() -> void:
	var args := OS.get_cmdline_user_args()
	verify = args.has("--verify")
	if args.has("--output"): directory = args[args.find("--output") + 1]
	DirAccess.make_dir_recursive_absolute(directory)
	var current: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	if not model.load_file("res://data/workshop/" + str(current.file)).is_empty(): quit(1); return
	arena = load("res://scripts/arena.gd").new(); root.add_child(arena)
	arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); arena.diagnostics = false
	arena.round_label = "STATUS EFFECTS"
	audio = CombatAudio.new(); root.add_child(audio)
	caption = Label.new(); caption.position = Vector2(28, 142)
	caption.add_theme_font_override("font", CombatTypography.FONT)
	caption.add_theme_font_size_override("font_size", 23)
	caption.add_theme_color_override("font_outline_color", Color("07131c"))
	caption.add_theme_constant_override("outline_size", 4); root.add_child(caption)
	await process_frame
	for example in ["bleed", "bleed-floor", "tether", "pull-mirrored", "both"]:
		var shark_first: bool = example in ["tether","pull-mirrored"]
		var mirrored: bool = example == "pull-mirrored"
		model.reset([4,5] if shark_first else [5,4])
		model.core.preview_place(0,65000 if mirrored else 37000,0,10000)
		model.core.preview_place(1,35000 if mirrored else 63000,0,10000)
		if example == "bleed":
			model.core.preview_place(0,40000,0,10000)
			model.core.preview_place(1,60000,0,10000)
		caption.text = {"bleed":"BLEED / WOUND, DROPLETS & GREY-LIFE CASH-OUT", "bleed-floor":"BLEED / GROUNDED WOUND FOLLOWS THE GET-UP", "tether":"TETHERED / ATTACHED UNTIL THE LINE EXPIRES", "pull-mirrored":"REELING / THE OPPONENT CAN STILL ATTACK", "both":"BLEED + TETHER / DISTINCT STATES ON BOTH FIGHTERS"}[example]
		var saw_status := false
		var saw_pull := false
		var actionable := false
		var saw_cashout := false
		var saw_downed := false
		var saw_getup := false
		for tick in (300 if example == "bleed" else 180 if example == "bleed-floor" else 240):
			if tick == 20:
				if example == "bleed-floor": model.core.preview_status(1,0,90)
				if shark_first: model.core.preview_status(1,2,14)
				else: model.core.preview_status(1,1,45)
				if example == "both": model.core.preview_status(0,2,14)
			if example == "bleed" and tick == 170: model.core.preview_begin(0,45)
			if example == "pull-mirrored" and tick == 130: model.core.preview_begin(0,22)
			if example == "both" and tick == 130: model.core.preview_begin(1,22)
			var input_a := 0
			var input_b := 0
			if example in ["bleed","tether"]:
				if tick >= 65 and tick < 95: input_b = 4
				if tick == 108: input_b = 8
			if example == "pull-mirrored" and tick == 142: input_b = 16
			model.step(input_a,input_b)
			if not verify: audio.consume(model,model.frame()-1,true)
			var state := model.state()
			var cues := CombatStatusEffects.describe(state)
			saw_status = saw_status or not cues.is_empty()
			if example == "bleed-floor" and not cues.is_empty():
				saw_downed = saw_downed or int(state.players[1].reaction) == 2
				saw_getup = saw_getup or (saw_downed and int(state.players[1].reaction) == 0)
			saw_pull = saw_pull or cues.any(func(c: Dictionary) -> bool: return c.kind == "tether" and c.pulling)
			if example == "pull-mirrored" and int(state.players[1].linePullTime) > 0 and int(state.players[1].move) >= 0 and int(state.players[1].stun) == 0: actionable = true
			if example == "bleed" and tick > 200 and state.players[1].bleedTime == 0 and state.players[1].health < 1000: saw_cashout = true
			var mark: String = str(example) + "-" + str(tick) if tick in [40,80,120,144,205,280] else ""
			await present(mark)
		if not saw_status: failures += 1
		if example in ["pull-mirrored","both"] and not saw_pull: failures += 1
		if example == "pull-mirrored" and not actionable: failures += 1
		if example == "bleed" and not saw_cashout: failures += 1
		if example == "bleed-floor" and not (saw_downed and saw_getup): failures += 1
		if not CombatStatusEffects.describe(model.state()).is_empty() and example not in ["both","bleed-floor"]: failures += 1
		print("Status review ",example,": present=",saw_status," pull=",saw_pull," actionable=",actionable," cashout=",saw_cashout," downed=",saw_downed," recovered=",saw_getup)
	print("Status effects review: %d failures" % failures)
	quit(1 if failures else 0)
