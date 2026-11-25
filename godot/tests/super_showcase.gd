extends SceneTree

var model := CombatModel.new()
var arena
var freeze: SuperFreeze
var overlay: Control
var current: Dictionary = {}
var captures := ""
var quick := false
var damage := 0
var tick := 0
func _initialize() -> void: call_deferred("run")

func draw_overlay() -> void:
	if current.is_empty(): return
	overlay.draw_rect(Rect2(0, 650, 1280, 70), Color("09090c"))
	var font := CombatTypography.FONT
	var accent: Color = FighterSelectPortrait.COLORS[int(current.character)]
	overlay.draw_string(font, Vector2(24, 680), current.name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 29, accent)
	var input := "%s   /   2 MOMENTUM SEGMENTS   /   %d DAMAGE" % [current.input, damage]
	overlay.draw_string(font, Vector2(24, 708), input, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("fff7e9"))
	var rule := "CONFIRMED CINEMATIC / NO CANCELS" if current.cinematic else "UTILITY / ACT AFTER CAST / FOLLOW UP"
	overlay.draw_string(font, Vector2(1256-font.get_string_size(rule,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x,694), rule,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("fff7e9"))

func display_frame(mark: String = "") -> void:
	var state := model.state()
	damage = maxi(damage, 1000-int(state.players[1].health))
	arena.refresh(model, state, false, false)
	if state.superFreezeTime > 0:
		var actor: Dictionary = state.players[int(state.superFreezeActor)]
		freeze.present(int(actor.character), int(actor.facing), int(state.superFreezeDuration)-int(state.superFreezeTime), int(state.superFreezeDuration), current.name)
	else: freeze.clear()
	overlay.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	if not captures.is_empty() and not mark.is_empty():
		root.get_texture().get_image().save_png(captures+"/%02d-%s.png" % [int(current.role),mark])

func run() -> void:
	var args := OS.get_cmdline_user_args()
	quick = args.has("--quick")
	if args.has("--captures"): captures = args[args.find("--captures")+1]; DirAccess.make_dir_recursive_absolute(captures)
	var batch: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	var error := model.load_data(JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/"+batch.file)))
	if not error.is_empty(): printerr(error); quit(1); return
	root.size = Vector2i(1280,720)
	arena = load("res://scripts/arena.gd").new()
	arena.position = Vector2(0,40)
	arena.size = Vector2(1280,610)
	arena.diagnostics = false
	root.add_child(arena)
	freeze = SuperFreeze.new();arena.add_child(freeze)
	overlay = Control.new();overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(overlay);overlay.draw.connect(draw_overlay)
	CombatSupers.info(0,16)
	for item in CombatSupers.roster:
		current = item;damage = 0
		var c := int(item.character)
		model.reset([c, (c+1)%6])
		model.core.preview_place(0,35000,0,10000)
		model.core.preview_place(1,60000 if item.role == 5 else 47000,16000 if item.role == 0 else 0,0)
		if item.role == 11: model.core.preview_status(1,1,150)
		await display_frame("idle")
		if not quick:
			for i in 36: await display_frame()
		model.core.preview_begin(0,int(item.slot))
		var saw_pair := false
		var captured_impact := false
		for i in 320:
			tick = i
			var state := model.state()
			var mark := ""
			if i == 20: mark = "cutin"
			elif i == 55: mark = "windup"
			elif state.pairKind > 0 and not saw_pair: mark="connect";saw_pair=true
			elif state.pairKind > 0 and state.pairClock >= state.pairTicks*0.78 and not captured_impact: mark="finish";captured_impact=true
			elif i == 110 and not item.cinematic: mark = "field"
			elif i == 260: mark = "result"
			if not quick or not mark.is_empty(): await display_frame(mark)
			# Show caster movement while utility cover remains, followed by a
			# normal. These are real inputs; the renderer never changes the state.
			var input := 0
			if not item.cinematic:
				if i >= 100 and i < 113: input = 2|512
				elif i == 114: input = 64
			model.step(input,0)
		print("Super review: %s / damage %d / cinematic %s" % [item.name,damage,saw_pair])
	print("Super showcase complete")
	quit(0)
