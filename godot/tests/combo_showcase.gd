extends SceneTree

# A recording harness, not an alternate combat simulation. Every live tick is
# replayed through FightCore and checked against the exported WASM checksum.
var model: CombatModel
var arena
var overlay: Control
var film: Dictionary
var clip: Dictionary
var mode := ""
var tick_index := 0
var display_hits := 0
var display_damage := 0
var title_alpha := 0.0
var recorded_frames := 0
var chapters: Array = []
var capture_dir := ""
var quick := false
var single_pass := false
var font := GuildTheme.SEMIBOLD
var muted := Color("a8b8c4")
var ink := Color("0b1118")
var paper := Color("f3ecdb")
var accents := FighterSelectPortrait.COLORS
var super_freeze: SuperFreeze

func _initialize() -> void: call_deferred("run")

func fail(message: String) -> void:
	printerr(message)
	quit(1)

func text(value: String, position: Vector2, height: int, color: Color) -> void:
	overlay.draw_string(font, position, value, HORIZONTAL_ALIGNMENT_LEFT, -1, height, color)

func draw_overlay() -> void:
	if clip.is_empty(): return
	var accent: Color = accents[int(clip.character)]
	var bonus: bool = clip.get("bonus") != null and tick_index >= int(clip.bonus.startFrame)
	overlay.draw_rect(Rect2(0, 0, 1280, 50), ink)
	overlay.draw_rect(Rect2(0, 650, 1280, 70), ink)
	overlay.draw_rect(Rect2(0, 48, 1280, 2), Color(accent, 0.65))
	overlay.draw_rect(Rect2(0, 648, 1280, 2), Color(accent, 0.65))
	text("FIGHT GUILD", Vector2(22, 23), 19, paper)
	text("COMBO LAB / " + str(film.date), Vector2(22, 41), 12, muted)
	text(CombatModel.CHARACTERS[int(clip.character)].to_upper() + "  /  " + (str(clip.bonus.title) if bonus else str(clip.title)), Vector2(211, 32), 28, accent)
	var score := "%d DAMAGE   /   %d %s" % [display_damage, display_hits, "HIT" if display_hits == 1 else "HITS"]
	text(score, Vector2(1256 - font.get_string_size(score, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x, 32), 28, paper)
	text("Combo ended. Wound adds bleed, with no extra hit or damage." if bonus else str(clip.condition), Vector2(22, 676), 16, muted)
	var speed := "1/2 SPEED REPLAY" if mode == "replay" else "FULL SPEED / 60 FPS"
	text(speed, Vector2(1256 - font.get_string_size(speed, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x, 676), 17, accent)
	var joined := "  >  ".join(clip.route.map(func(action): return str(action.notation)))
	var size := 22
	while font.get_string_size(joined, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > 1230: size -= 1
	var x := 22.0
	for i in clip.route.size():
		var action: Dictionary = clip.route[i]
		var active: bool = tick_index >= int(action.inputFrame) and (i == clip.route.size() - 1 or tick_index < int(clip.route[i + 1].inputFrame))
		var label: String = str(action.notation) + ("  >  " if i < clip.route.size() - 1 else "")
		text(label, Vector2(x, 706), size, accent if active else paper if tick_index >= int(action.inputFrame) else muted)
		x += font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	if bonus:
		overlay.draw_rect(Rect2(0, 682, 1280, 38), ink)
		text("5D  /  WOUND  >  BLEED APPLIED  >  NEUTRAL RESET", Vector2(22, 706), 22, accent)
	if title_alpha > 0:
		overlay.draw_rect(Rect2(0, 50, 1280, 598), Color(ink, title_alpha * 0.7))
		var name: String = CombatModel.CHARACTERS[int(clip.character)].to_upper()
		text(name, Vector2(66, 310), 100, Color(accent, title_alpha))
		text(str(clip.title), Vector2(70, 357), 36, Color(paper, title_alpha))
		text("NORMAL HIT / %d DAMAGE / %d HITS" % [clip.damage, clip.hits], Vector2(70, 398), 24, Color(paper, title_alpha))
		text("CURRENT BUILD  ·  VERIFIED INPUT REPLAY", Vector2(70, 436), 16, Color(muted, title_alpha))
		if clip.wallBreak: text("Includes the wall-break bonus", Vector2(70, 469), 19, Color(accent, title_alpha))

func frame() -> void:
	var state := model.state()
	display_damage = maxi(display_damage, int(clip.initial.get("baseHealth", 1000)) - int(state.players[1].health))
	display_hits = maxi(display_hits, int(state.players[0].combo))
	arena.refresh(model, state, false, false)
	if int(state.superFreezeTime) > 0:
		var actor: Dictionary = state.players[int(state.superFreezeActor)]
		super_freeze.present(int(actor.character), int(actor.facing), int(state.superFreezeDuration)-int(state.superFreezeTime), int(state.superFreezeDuration))
	else: super_freeze.clear()
	overlay.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	recorded_frames += 1

func reset_clip() -> void:
	model.reset(clip.initial.characters)
	for p in 2: model.core.preview_place(p, int(clip.initial.positions[p]), 0, int(clip.initial.momentum))
	for input in clip.initial.get("setupInputs", []): model.step(int(input[0]), int(input[1]))
	super_freeze.clear()
	tick_index = 0
	display_damage = 0
	display_hits = 0

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.has("--film"): fail("Pass --film /absolute/path/to/film.json"); return
	film = JSON.parse_string(FileAccess.get_file_as_string(args[args.find("--film") + 1]))
	quick = args.has("--quick")
	single_pass = args.has("--single-pass")
	if args.has("--captures"): capture_dir = args[args.find("--captures") + 1]
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	model = CombatModel.new()
	var error := model.load_file("res://data/workshop/" + str(film.source.file))
	if not error.is_empty(): fail(error); return
	var source_bytes := FileAccess.get_file_as_bytes("res://data/workshop/" + str(film.source.file))
	var sha := HashingContext.new()
	sha.start(HashingContext.HASH_SHA256)
	sha.update(source_bytes)
	if sha.finish().hex_encode() != str(film.source.sha256): fail("Workshop file differs from the searched build"); return
	sha.start(HashingContext.HASH_SHA256)
	sha.update(FileAccess.get_file_as_bytes("res://assets/fighters/manifest.json"))
	if sha.finish().hex_encode() != str(film.artSha256): fail("Artwork changed after the recording plan was prepared"); return
	var background := ColorRect.new()
	background.color = ink
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	arena = load("res://scripts/arena.gd").new()
	root.add_child(arena)
	arena.position = Vector2(0, 50)
	arena.size = Vector2(1280, 598)
	arena.diagnostics = false
	arena.round_label = "TRAINING"
	super_freeze = SuperFreeze.new()
	arena.add_child(super_freeze)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	overlay.draw.connect(draw_overlay)
	await process_frame
	for item in film.clips:
		clip = item
		chapters.append({"id": clip.id, "frame": recorded_frames, "time": float(recorded_frames) / 60.0})
		reset_clip()
		mode = "live"
		for i in (1 if quick else 105):
			title_alpha = 1.0 if quick else clampf(minf(float(i + 1) / 12.0, float(105 - i) / 24.0), 0, 1)
			model.step(0,0)
			await frame()
		if not capture_dir.is_empty(): root.get_texture().get_image().save_png(capture_dir.path_join(str(clip.id) + "-title.png"))
		for pass_index in (1 if quick or single_pass else 2):
			reset_clip()
			mode = "live" if pass_index == 0 else "replay"
			title_alpha = 0
			for i in clip.inputs.size():
				model.step(int(clip.inputs[i][0]), int(clip.inputs[i][1]))
				tick_index = i + 1
				if (model.state_hash() & 0xffffffff) != int(clip.hashes[i]): fail("Native replay differs: %s frame %d" % [clip.id, i + 1]); return
				if quick and i != int(clip.firstHit) + 3 and i != int(clip.comboEnd) - 1: continue
				await frame()
				if pass_index == 1: await frame()
				if not capture_dir.is_empty() and pass_index == 0 and i == int(clip.firstHit) + 3:
					root.get_texture().get_image().save_png(capture_dir.path_join(str(clip.id) + "-hit.png"))
				var capture_state := model.state()
				if not capture_dir.is_empty() and pass_index == 0 and int(capture_state.pairKind) == 7 and int(capture_state.pairClock) in [4, 30, 100]:
					root.get_texture().get_image().save_png(capture_dir.path_join(str(clip.id) + "-capture-%d.png" % int(capture_state.pairClock)))
			for i in (1 if quick else 75): await frame()
		print("Verified native footage: ", clip.id, " / ", clip.damage, " damage / ", clip.hits, " hits")
	if args.has("--chapters"):
		var file := FileAccess.open(args[args.find("--chapters") + 1], FileAccess.WRITE)
		file.store_string(JSON.stringify({"fps": 60, "frames": recorded_frames, "chapters": chapters}, "  ") + "\n")
	print("Combo showcase complete: ", recorded_frames, " rendered frames.")
	quit()
