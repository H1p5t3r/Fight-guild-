class_name InkMenu
extends RefCounted

# Native front-end art direction. The combat lab and browser Workshop keep their themes.
const INK := Color("09090c")
const PAPER := Color("fff7e9")
const MUTED := Color("d4caca")
const FONT = CombatTypography.FONT
const SHADER = preload("res://assets/ui/menu-ink.gdshader")

static func panel(fill: Color = INK, border: Color = INK, width: int = 0, padding: int = 14) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_content_margin_all(padding)
	return style

static func theme(accent: Color) -> Theme:
	var result := GuildTheme.stock()
	result.default_font = GuildTheme.REGULAR
	result.default_font_size = 20
	for type in ["Button", "OptionButton", "StockPrimaryButton", "StockSecondaryButton", "StockEssentialButton", "SettingsPrimary", "SettingsTab"]:
		if type.begins_with("Settings"): result.set_type_variation(type, "Button")
		result.set_font("font", type, GuildTheme.SEMIBOLD)
		for state in GuildTheme.STATES:
			var selected: bool = state in ["hover", "pressed", "hover_pressed"]
			var style := panel(PAPER if selected else INK, PAPER if state == "focus" else INK, 2 if state == "focus" else 0, 9)
			if state == "focus": style.bg_color = Color.TRANSPARENT
			if state == "disabled": style.bg_color = Color("262125")
			result.set_stylebox(state, type, style)
		for state in ["font_color", "font_focus_color"]: result.set_color(state, type, PAPER)
		for state in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color"]: result.set_color(state, type, INK)
		result.set_color("font_disabled_color", type, Color("8c8185"))
	for type in ["PanelContainer", "PopupPanel", "PopupMenu", "AcceptDialog"]: result.set_stylebox("panel", type, panel())
	result.set_stylebox("hover", "PopupMenu", panel(accent.darkened(0.55)))
	for type in ["Label", "LineEdit", "CheckBox", "PopupMenu"]: result.set_color("font_color", type, PAPER)
	result.set_stylebox("normal", "LineEdit", panel(accent.darkened(0.83), PAPER, 1, 10))
	result.set_stylebox("read_only", "LineEdit", panel(accent.darkened(0.83)))
	result.set_stylebox("focus", "LineEdit", panel(Color.TRANSPARENT, accent, 3, 10))
	result.set_color("caret_color", "LineEdit", PAPER)
	var divider := StyleBoxLine.new()
	divider.color = accent
	divider.thickness = 2
	result.set_stylebox("separator", "HSeparator", divider)
	result.set_stylebox("panel", "TooltipPanel", panel(INK, PAPER, 1))
	result.set_color("font_color", "TooltipLabel", PAPER)
	var border := panel(INK, accent, 3, 0)
	border.border_width_top = 30
	border.expand_margin_top = 30
	for state in ["embedded_border", "embedded_unfocused_border"]: result.set_stylebox(state, "Window", border)
	result.set_font("title_font", "Window", GuildTheme.SEMIBOLD)
	result.set_color("title_color", "Window", PAPER)
	return result

static func material(accent: Color, silhouette: bool = false) -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = SHADER
	result.set_shader_parameter("silhouette", silhouette)
	result.set_shader_parameter("accent", accent)
	return result

static func idle_phase(character: int) -> String:
	var fighter: Dictionary = FighterArt.catalog().fighters[character]
	return "idle" if fighter.has("idle") else "ready" if fighter.has("ready") else "windup"

static func slash(rect: Rect2, lean: float = 16.0) -> PackedVector2Array:
	return PackedVector2Array([rect.position + Vector2(lean, 0), Vector2(rect.end.x, rect.position.y), rect.end - Vector2(lean, 0), Vector2(rect.position.x, rect.end.y)])

static func word(canvas: CanvasItem, value: String, origin: Vector2, font_size: int, color: Color = PAPER, angle: float = -0.045, max_width: float = 1000.0) -> void:
	var width := FONT.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	canvas.draw_set_transform(origin, angle, Vector2(minf(1.0, max_width / maxf(width, 1.0)), 1.0))
	canvas.draw_string(FONT, Vector2.ZERO, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	canvas.draw_set_transform(Vector2.ZERO)
