class_name FighterSelectPortrait
extends Control

const GUILDS := ["BLACKSMITHS", "MASONS", "ALCHEMISTS", "BREWERS", "FISHERMEN", "BUTCHERS"]
const COLORS := [Color("aeb4bc"), Color("99b0c2"), Color("a8ba76"), Color("d99a59"), Color("5ab5b5"), Color("dc143c")]
const PLAYER_COLORS := [GuildTheme.BRASS, Color("79c8d2")]
var motion := MenuMotion.new()
var player := 0
var character := -1
var previous := 0
var editing := false
var arrival := 1.0:
	set(value):
		arrival = value
		queue_redraw()
var previous_alpha := 1.0
var idle_ticks := 0.0
var tween: Tween
var portrait := Sprite2D.new()
var ghost := Sprite2D.new()
var fighter_name: Label
var guild_name: Label
var role: Label
var tagline: Label
const LINES := ["HOLD THE LINE.", "BREAK THE WALL.", "BREATHE IT IN.", "LAST ORDERS.", "SMELL BLOOD.", "CUT DEEP."]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	custom_minimum_size = Vector2(280, 210)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	for sprite in [ghost, portrait]:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(sprite)
	fighter_name = make_label(58)
	fighter_name.add_theme_font_override("font", InkMenu.FONT)
	fighter_name.rotation = -0.055 if player == 0 else 0.035
	fighter_name.add_theme_color_override("font_shadow_color", Color("071016"))
	fighter_name.add_theme_constant_override("shadow_offset_x", 3)
	fighter_name.add_theme_constant_override("shadow_offset_y", 3)
	fighter_name.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	fighter_name.offset_top = -110
	fighter_name.offset_bottom = -28
	guild_name = make_label(17)
	guild_name.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	guild_name.offset_top = -31
	guild_name.offset_bottom = -10
	tagline = make_label(18)
	tagline.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	tagline.offset_top = 32
	tagline.offset_bottom = 55
	tagline.add_theme_color_override("font_color", GuildTheme.MUTED)
	role = make_label(19)
	role.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	role.offset_top = 5
	role.offset_bottom = 30
	role.add_theme_font_override("font", GuildTheme.SEMIBOLD)
	role.add_theme_color_override("font_color", InkMenu.PAPER)
	for label in [fighter_name, guild_name, role, tagline]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if player == 0 else HORIZONTAL_ALIGNMENT_RIGHT
		label.add_theme_color_override("font_outline_color", Color("071016"))
		label.add_theme_constant_override("outline_size", 3)
	portrait.material = InkMenu.material(COLORS[maxi(character, 0)])
	ghost.material = InkMenu.material(COLORS[maxi(previous, 0)])
	resized.connect(queue_redraw)

func make_label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func present(index: int) -> void:
	if character == index: return
	if tween: tween.kill()
	previous = maxi(character, 0)
	previous_alpha = arrival
	var first := character < 0
	character = index
	idle_ticks = 0.0
	portrait.material.set_shader_parameter("accent", COLORS[index])
	ghost.material.set_shader_parameter("accent", COLORS[previous])
	fighter_name.text = CombatModel.CHARACTERS[index].to_upper()
	guild_name.text = GUILDS[index]
	tagline.text = LINES[index]
	guild_name.add_theme_color_override("font_color", COLORS[index])
	if first or motion.instant or not is_visible_in_tree():
		finish_motion()
		return
	arrival = 0.0
	tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "arrival", 1.0, motion.duration(0.26))

func finish_motion() -> void:
	if tween: tween.kill()
	arrival = 1.0

func is_animating() -> bool:
	return tween != null and tween.is_running()

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	if not motion.reduced and not motion.instant: idle_ticks += delta * 60.0
	queue_redraw()

func apply_idle(sprite: Sprite2D, index: int, factor: float, facing: int) -> void:
	var phase := InkMenu.idle_phase(index)
	FighterArt.apply(sprite, index, phase, FighterArt.idle_pose(index, int(idle_ticks)) if phase == "idle" else 0, factor, facing)

func _draw() -> void:
	if character < 0: return
	var w := size.x
	var h := size.y
	var accent: Color = COLORS[character]
	var direction := 1 if player == 0 else -1
	var guild_origin := Vector2(w * (0.20 if player == 0 else 0.80), h * 0.44)
	draw_guild_mark(guild_origin, minf(w * 0.52, 180.0), Color(InkMenu.INK, 0.22))
	var number := "0" + str(player + 1)
	var number_size := mini(170, int(w * 0.44))
	var width := GuildTheme.SEMIBOLD.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size).x
	draw_string_outline(GuildTheme.SEMIBOLD, Vector2(0 if player == 0 else w - width, h * 0.88), number, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size, 2, Color(InkMenu.PAPER, 0.35))
	if arrival < 1.0 and not motion.reduced:
		var tip := w * arrival
		draw_colored_polygon(PackedVector2Array([Vector2(0, h * 0.28), Vector2(tip, h * 0.19), Vector2(w, h * 0.38), Vector2(tip * 0.5, h * 0.52)]), Color(accent, (1.0 - arrival) * 0.27))
	var anchor := Vector2(w * 0.5, h - 20)
	apply_idle(portrait, character, h * 1.05 / 150.0, direction)
	portrait.position = anchor + Vector2(motion.distance(32) * (1.0 - arrival) * -direction, 0)
	portrait.modulate.a = arrival
	ghost.visible = arrival < 1.0
	if ghost.visible:
		apply_idle(ghost, previous, h * 1.05 / 150.0, direction)
		ghost.position = anchor + Vector2(motion.distance(16) * arrival * direction, 0)
		ghost.modulate.a = (1.0 - arrival) * previous_alpha

func draw_guild_mark(origin: Vector2, radius: float, color: Color) -> void:
	# Original geometric motifs, shared weight/angles; presentation, not official guild crests.
	draw_set_transform(origin, 0.0, Vector2(radius, radius))
	match character:
		0:
			draw_colored_polygon(PackedVector2Array([Vector2(-1,-0.5), Vector2(1,-0.5), Vector2(0.55,0), Vector2(0.25,0), Vector2(0.25,0.45), Vector2(0.65,0.65), Vector2(-0.65,0.65), Vector2(-0.25,0.45), Vector2(-0.25,0), Vector2(-0.7,0)]), color)
		1:
			draw_colored_polygon(PackedVector2Array([Vector2(-0.8,0.7), Vector2(-0.8,-0.6), Vector2(-0.4,-0.6), Vector2(-0.4,-0.2), Vector2(0,-0.65), Vector2(0.4,-0.2), Vector2(0.4,-0.6), Vector2(0.8,-0.6), Vector2(0.8,0.7)]), color)
		2:
			draw_polyline(PackedVector2Array([Vector2(-0.2,-0.8), Vector2(-0.2,-0.2), Vector2(-0.7,0.7), Vector2(0.7,0.7), Vector2(0.2,-0.2), Vector2(0.2,-0.8)]), color, 0.08, true)
			draw_line(Vector2(-0.5,0.35), Vector2(0.5,0.35), color, 0.08, true)
		3:
			draw_arc(Vector2.ZERO, 0.76, 0, TAU, 32, color, 0.12, true)
			for y in [-0.35, 0.35]: draw_line(Vector2(-0.65,y), Vector2(0.65,y), color, 0.12, true)
			draw_line(Vector2.ZERO - Vector2(0,0.74), Vector2(0,0.74), color, 0.08, true)
		4:
			draw_colored_polygon(PackedVector2Array([Vector2(-0.9,0.65), Vector2(0.5,-0.85), Vector2(0.3,0.3), Vector2(0.9,0.65)]), color)
			draw_polyline(PackedVector2Array([Vector2(-1,0.9), Vector2(-0.35,0.78), Vector2(0.35,0.95), Vector2(1,0.78)]), color, 0.08, true)
		5:
			for x in [-0.42, 0.15, 0.72]:
				draw_colored_polygon(PackedVector2Array([Vector2(x-0.28,0.85), Vector2(x-0.15,-0.5), Vector2(x+0.23,-0.85)]), color)
	draw_set_transform(Vector2.ZERO)
