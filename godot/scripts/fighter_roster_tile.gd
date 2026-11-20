class_name FighterRosterTile
extends Button

var motion := MenuMotion.new()
var character := 0
var player := 0
var markers := [false, false]
var selecting := false
var bust: AtlasTexture
var emphasis := 0.0:
	set(value):
		emphasis = value
		queue_redraw()
var hover_tween: Tween

func _ready() -> void:
	custom_minimum_size = Vector2(148, 92)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for state in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	tooltip_text = CombatModel.CHARACTERS[character] + " · " + FighterSelectPortrait.GUILDS[character].capitalize()
	var source := FighterArt.texture(character, "windup", 0)
	var bounds: Array = FighterArt.sheet(character, "windup").frames[0].bounds
	bust = AtlasTexture.new()
	bust.atlas = source.atlas
	bust.region = Rect2(source.region.position + Vector2(bounds[0], bounds[1]), Vector2(bounds[2] - bounds[0], (bounds[3] - bounds[1]) * 0.60))
	bust.filter_clip = true
	resized.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(func(): animate_hover(1.0))
	mouse_exited.connect(func(): animate_hover(0.0))

func animate_hover(value: float) -> void:
	if hover_tween: hover_tween.kill()
	if motion.instant:
		emphasis = value
		return
	hover_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(self, "emphasis", value, motion.duration(0.12))

func _draw() -> void:
	if bust == null: return
	var w := size.x
	var h := size.y
	var accent: Color = FighterSelectPortrait.COLORS[character]
	var outline := PackedVector2Array([Vector2(10, 2), Vector2(w - 2, 2), Vector2(w - 10, h - 2), Vector2(2, h - 2), Vector2(10, 2)])
	draw_colored_polygon(outline, Color("17252e").lerp(accent.darkened(0.56), 0.30 + emphasis * 0.22))
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.56, 2), Vector2(w - 2, 2), Vector2(w - 10, h - 2), Vector2(w * 0.24, h - 2)]), Color(accent, 0.20))
	var factor := minf(106.0 / bust.get_width(), 71.0 / bust.get_height())
	var image_size := bust.get_size() * factor
	draw_texture_rect(bust, Rect2(Vector2(w * 0.5, 38) - image_size * 0.5, image_size), false)
	draw_colored_polygon(PackedVector2Array([Vector2(5, h - 27), Vector2(w - 7, h - 31), Vector2(w - 10, h - 2), Vector2(2, h - 2)]), Color("0b151e"))
	var fighter: String = CombatModel.CHARACTERS[character].to_upper()
	var text_width := GuildTheme.SEMIBOLD.get_string_size(fighter, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	draw_string(GuildTheme.SEMIBOLD, Vector2((w - text_width) * 0.5, h - 8), fighter, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, GuildTheme.IVORY)
	draw_polyline(outline, FighterSelectPortrait.PLAYER_COLORS[player] if selecting else Color(accent, 0.5), 3.0 if selecting else 1.0, true)
	if has_focus():
		draw_polyline(PackedVector2Array([Vector2(0, 18), Vector2(2, 0), Vector2(28, 0)]), GuildTheme.IVORY, 3.0)
		draw_polyline(PackedVector2Array([Vector2(w - 28, h), Vector2(w - 2, h), Vector2(w, h - 18)]), GuildTheme.IVORY, 3.0)
	for p in 2:
		if not markers[p]: continue
		var x := 13.0 if p == 0 else w - 38.0
		draw_rect(Rect2(x, 7, 24, 18), FighterSelectPortrait.PLAYER_COLORS[p])
		draw_string(GuildTheme.SEMIBOLD, Vector2(x + 4, 21), "P" + str(p + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("0b151e"))
