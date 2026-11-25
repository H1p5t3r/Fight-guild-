class_name InkMenuButton
extends Button

var motion := MenuMotion.new()
var palette := MenuPalette.new()
var compact := false
var serial := ""
var emphasis := 0.0:
	set(value):
		emphasis = value
		queue_redraw()
var tween: Tween

func fit_caption() -> void:
	var font_size := get_theme_font_size("font_size")
	var width := InkMenu.FONT.get_string_size(text.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	# Button's native sizing ignores a Control script's minimum-size override.
	# Include the cut edges explicitly, including when a dynamic caption changes.
	custom_minimum_size.x = ceilf(width + (36 if compact else 70))

func _ready() -> void:
	for state in GuildTheme.STATES: add_theme_stylebox_override(state, StyleBoxEmpty.new())
	# Keep real Button semantics, accessible text and focus neighbours; draw the lettering once.
	for state in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_disabled_color"]:
		add_theme_color_override(state, Color.TRANSPARENT)
	add_theme_font_override("font", InkMenu.FONT)
	resized.connect(queue_redraw)
	palette.changed.connect(queue_redraw)
	for event in [focus_entered, focus_exited, mouse_entered, mouse_exited]: event.connect(react)
	pressed.connect(queue_redraw)
	toggled.connect(func(_pressed: bool): queue_redraw())

func react() -> void:
	if tween: tween.kill()
	var target := 1.0 if has_focus() or is_hovered() else 0.0
	if motion.reduced or motion.instant:
		emphasis = target
		return
	tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "emphasis", target, motion.duration(0.075))

func _draw() -> void:
	fit_caption()
	var focused := (has_focus() or is_hovered() or (toggle_mode and button_pressed)) and not disabled
	var shift := emphasis * (3.0 if compact else 9.0) if not motion.reduced else 0.0
	var rect := Rect2(3 + shift, 3, size.x - 7 - shift, size.y - 7)
	var lean := 9.0 if compact else 18.0
	if focused:
		draw_colored_polygon(InkMenu.slash(Rect2(rect.position + Vector2(-3, 4), rect.size + Vector2(1, 1)), lean), InkMenu.INK)
		draw_colored_polygon(InkMenu.slash(rect, lean), InkMenu.PAPER)
		if not compact:
			draw_colored_polygon(PackedVector2Array([Vector2(1, size.y * 0.3), Vector2(20, size.y * 0.5), Vector2(0, size.y * 0.76), Vector2(6, size.y * 0.49)]), palette.accent)
	else:
		draw_colored_polygon(InkMenu.slash(rect, lean), Color("251c22") if disabled else InkMenu.INK)
	var ink := InkMenu.INK if focused else InkMenu.PAPER
	if disabled: ink = Color("807478")
	var font_size := get_theme_font_size("font_size")
	var inset := 14.0 if compact else 34.0
	var label_width := size.x - inset - 18.0 - (27.0 if not serial.is_empty() else 0.0)
	InkMenu.word(self, text.to_upper(), Vector2(inset + shift, size.y * 0.5 + font_size * 0.33), font_size, ink, -0.018 if compact else -0.035, label_width)
	if not serial.is_empty():
		draw_string(GuildTheme.REGULAR, Vector2(size.x - 32, size.y - 14), serial, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, InkMenu.INK if focused else palette.accent)
	if focused and compact:
		draw_line(Vector2(14, size.y - 5), Vector2(size.x - 15, size.y - 5), palette.accent.darkened(0.3), 3)
