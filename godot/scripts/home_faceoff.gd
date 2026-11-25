class_name MenuFighterPoster
extends Control

# Uses the approved, pivot-registered combat idles; the print effect is presentation only.
var palette := MenuPalette.new()
var motion := MenuMotion.new()
var character := 5
var opponent := -1
var portrait := Sprite2D.new()
var shadow := Sprite2D.new()
var title: Label
var ticks := 0.0
var arrival := 1.0:
	set(value):
		arrival = value
		queue_redraw()
var tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	custom_minimum_size = Vector2(400, 300)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	for sprite in [shadow, portrait]:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(sprite)
	shadow.material = InkMenu.material(palette.accent, true)
	portrait.material = InkMenu.material(palette.accent)
	title = Label.new()
	title.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	title.offset_top = -90
	title.offset_bottom = -10
	title.add_theme_font_override("font", InkMenu.FONT)
	title.add_theme_font_size_override("font_size", 66)
	title.add_theme_color_override("font_color", InkMenu.PAPER)
	title.add_theme_color_override("font_outline_color", InkMenu.INK)
	title.add_theme_constant_override("outline_size", 10)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	palette.changed.connect(refresh_palette)
	resized.connect(queue_redraw)
	refresh_palette()

func refresh_palette() -> void:
	portrait.material.set_shader_parameter("accent", palette.accent)
	queue_redraw()

func present(index: int, rival: int = -1) -> void:
	character = index
	opponent = rival
	ticks = 0.0
	if tween: tween.kill()
	if motion.reduced or motion.instant or not is_visible_in_tree():
		arrival = 1.0
	else:
		arrival = 0.0
		tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "arrival", 1.0, motion.duration(0.26))
	queue_redraw()

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	if not motion.reduced and not motion.instant: ticks += delta * 60.0
	queue_redraw()

func apply_idle(sprite: Sprite2D, index: int, scale_value: float, facing: int) -> void:
	var phase := InkMenu.idle_phase(index)
	var pose := FighterArt.idle_pose(index, int(ticks)) if phase == "idle" else 0
	FighterArt.apply(sprite, index, phase, pose, scale_value, facing)

func _draw() -> void:
	if title == null: return
	var w := size.x
	var h := size.y
	var accent := palette.accent
	var name: String = CombatModel.CHARACTERS[character].to_upper()
	InkMenu.word(self, name, Vector2(w * 0.18, h * 0.29), int(h * 0.19), InkMenu.INK, -0.08, w * 0.78)
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.03, h * 0.76), Vector2(w * 0.92, h * 0.28), Vector2(w, h * 0.42), Vector2(w * 0.05, h * 0.87)]), InkMenu.PAPER)
	apply_idle(shadow, opponent if opponent >= 0 else character, h * 1.04 / 150.0, -1 if opponent >= 0 else 1)
	shadow.position = Vector2(w * 0.76, h * 1.03)
	shadow.modulate.a = 1.0
	apply_idle(portrait, character, h * 0.92 / 150.0, 1)
	portrait.position = Vector2(w * 0.40 + motion.distance(80.0) * (1.0 - arrival), h * 0.97)
	portrait.modulate.a = 0.5 + arrival * 0.5
	title.text = name
	# A printed guild seal and pitch marks use the same angular geometry as the match UI.
	for i in 3:
		draw_colored_polygon(InkMenu.slash(Rect2(w * 0.03 + i * 23, h * 0.87, 15, 40), 8), accent.darkened(0.65))
