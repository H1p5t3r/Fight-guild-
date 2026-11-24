extends SceneTree

const ORDER := [5, 4, 2, 3, 1, 0]
const FAMILIES := ["legs", "chest", "head", "air"]
var sprites: Array[Sprite2D] = []
var captions: Array[Label] = []
var heading: Label
var clock: Label

func label_at(text: String, position: Vector2, font_size: int, color := Color("eee7d7")) -> Label:
	var label := Label.new()
	label.text = text; label.position = position
	label.add_theme_font_override("font", GuildTheme.SEMIBOLD)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	root.add_child(label)
	return label

func _initialize() -> void: call_deferred("run")

func run() -> void:
	root.content_scale_size = Vector2i(1440, 810)
	root.size = Vector2i(1440, 810)
	var background := ColorRect.new()
	background.color = Color("17262f")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	heading = label_at("", Vector2(28, 30), 38)
	label_at("A / COMPACT SNAP", Vector2(29, 85), 22, Color("dfae60"))
	clock = label_at("", Vector2(28, 737), 23)
	for index in 5:
		var x := index * 288.0
		var line := ColorRect.new()
		line.position = Vector2(x + 12, 654); line.size = Vector2(264, 2)
		line.color = Color("5a747d"); root.add_child(line)
		var sprite := Sprite2D.new()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.position = Vector2(x + 144, 654 - (65 if index == 4 else 0))
		root.add_child(sprite); sprites.append(sprite)
		var name: String = "CURRENT IDLE" if index == 0 else ["LEG HIT", "CHEST HIT", "HEAD HIT", "AIR HIT"][index-1]
		label_at(name, Vector2(x + 25, 168), 25)
		captions.append(label_at("", Vector2(x + 25, 686), 20, Color("a4b6bd")))
	await process_frame
	var args := OS.get_cmdline_user_args()
	var output := args[args.find("--output")+1] if args.has("--output") else "user://"
	var stills_only := args.has("--stills")
	DirAccess.make_dir_recursive_absolute(output)
	for character in ORDER:
		heading.text = str(CombatModel.CHARACTERS[character]).to_upper() + "  /  RECEIVER ANIMATIONS"
		var scale := 1.65 if character == 0 else 1.95
		var art: Dictionary = FighterArt.catalog().fighters[character]
		var idle_phase := "idle" if art.has("idle") else "ready" if art.has("ready") else "active"
		for tick in (1 if stills_only else 240):
			# Two normal-speed hits, then one half-speed review. Eight ticks of
			# hitstop, contact ages 0-1, recoil ages 2-4, hold through stun.
			var t := 33 if stills_only else tick % 60 if tick < 120 else (tick - 120) / 2
			var hurt := t >= 12 and t < 48
			var age := maxi(0, int(t) - 20)
			FighterArt.apply(sprites[0], character, idle_phase, 0, scale, 1, 0)
			captions[0].text = "Scale reference"
			for column in 4:
				var sprite := sprites[column+1]
				FighterArt.apply(sprite, character, "active" if hurt else idle_phase, 9 if hurt else 0, scale, 1, -1 if hurt else 0)
				var fighter := {"character": character, "facing": 1, "stun": 40 if hurt else 0, "guarding": 0, "reaction": 1 if column == 3 and hurt else 0, "y": 5000 if column == 3 else 0}
				CombatReactions.apply(sprite, fighter, {"flags": [2,4,6,8][column], "age": age}, scale)
				captions[column+1].text = ["Contact / frozen", "Recoil", "Stun hold"][CombatReactions.key(age)] if hurt else "Ready"
			clock.text = "POSE REVIEW  /  " + ("0.5× playback" if tick >= 120 and not stills_only else "Normal timing") + "  /  8f hitstop · contact → recoil → held stun"
			await process_frame
			await RenderingServer.frame_post_draw
			if stills_only or tick == 33:
				var result := root.get_texture().get_image().save_png(output.path_join(str(character) + "-reactions.png"))
				if result != OK: quit(1); return
	print("Compact Snap native pose review: 6 fighters / 24 clips")
	quit()
