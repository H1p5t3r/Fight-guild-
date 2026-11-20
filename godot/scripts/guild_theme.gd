class_name GuildTheme
extends RefCounted

# The shared owner for the supplied Guild Ball kit. Resource textures stay immutable.
const REGULAR = preload("res://Content/Fonts/BarlowCondensed.woff2")
const SEMIBOLD = preload("res://Content/Fonts/BarlowCondensedSemibold.woff2")
const IVORY := Color("f3ecdb")
const BRASS := Color("dfb36c")
const MUTED := Color("a8b8c4")
const CREAM := Color("f0e5ce")
const ORANGE := Color("e28c54")
const WARM_MUTED := Color("b9afa0")
const STATES := ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]

static func surface(name: String) -> StyleBoxTexture:
	return load("res://Content/UI/Stock/" + name + ".tres")

static func stock() -> Theme:
	var result: Theme = preload("res://Content/UI/Stock/stock-theme.tres").duplicate(true)
	result.default_font = REGULAR
	result.default_font_size = 20
	for type in ["Button", "OptionButton"]:
		result.set_font("font", type, SEMIBOLD)
		for state in STATES: result.set_stylebox(state, type, surface("secondary-" + state))
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			result.set_color(state, type, IVORY)
		result.set_color("font_disabled_color", type, Color("829094"))
	result.set_stylebox("panel", "PanelContainer", surface("panel-compact"))
	result.set_stylebox("panel", "PopupPanel", surface("panel-tooltip"))
	result.set_stylebox("panel", "PopupMenu", surface("panel-tooltip"))
	result.set_stylebox("hover", "PopupMenu", surface("primary-hover"))
	result.set_stylebox("panel", "AcceptDialog", surface("panel-broadcast"))
	result.set_stylebox("separator", "HSeparator", surface("divider-horizontal"))
	for type in ["Label", "LineEdit", "CheckBox", "PopupMenu"]: result.set_color("font_color", type, IVORY)
	result.set_stylebox("normal", "LineEdit", surface("secondary-normal"))
	result.set_stylebox("read_only", "LineEdit", surface("secondary-disabled"))
	result.set_stylebox("focus", "LineEdit", surface("secondary-focus"))
	result.set_color("caret_color", "LineEdit", IVORY)
	for state in STATES:
		result.set_stylebox(state, "CheckBox", surface("secondary-focus") if state == "focus" else StyleBoxEmpty.new())
	for icon in ["checked", "unchecked", "checked_disabled", "unchecked_disabled"]:
		result.set_icon(icon, "CheckBox", load("res://assets/ui/icons/" + icon + ".svg"))
	result.set_constant("separation", "VBoxContainer", 8)
	result.set_constant("separation", "HBoxContainer", 8)
	window_chrome(result, false)
	return result

static func apply(button: Button, family: String = "primary") -> void:
	button.theme_type_variation = "Stock" + family.capitalize() + "Button"
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 38)

static func warm_surface(name: String) -> StyleBoxTexture:
	var result := StyleBoxTexture.new()
	result.texture = load("res://Content/UI/Settings/" + name + ".svg")
	for edge in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		result.set_texture_margin(edge, 12)
		result.set_content_margin(edge, 6 if edge in [SIDE_LEFT, SIDE_RIGHT] else 3)
	return result

static func warm_panel(fill: Color = Color("292624")) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = fill
	result.border_color = Color("706356")
	result.set_border_width_all(1)
	for edge in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]: result.set_content_margin(edge, 10 if edge in [SIDE_LEFT, SIDE_RIGHT] else 8)
	return result

static func settings() -> Theme:
	var result := Theme.new()
	result.default_font = REGULAR
	result.default_font_size = 20
	for type in ["Button", "OptionButton", "SettingsPrimary", "SettingsTab"]:
		if type.begins_with("Settings"): result.set_type_variation(type, "Button")
		result.set_font("font", type, SEMIBOLD)
		for state in STATES:
			var family := "primary" if type == "SettingsPrimary" or (type == "SettingsTab" and state in ["pressed", "hover_pressed"]) else "secondary"
			result.set_stylebox(state, type, warm_surface("focus" if state == "focus" else family + "-" + ("pressed" if state == "hover_pressed" else state)))
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			result.set_color(state, type, CREAM)
		result.set_color("font_disabled_color", type, WARM_MUTED)
	for type in ["PanelContainer", "PopupPanel", "PopupMenu", "AcceptDialog"]: result.set_stylebox("panel", type, warm_panel())
	for type in ["Label", "LineEdit", "CheckBox", "PopupMenu"]: result.set_color("font_color", type, CREAM)
	result.set_stylebox("normal", "LineEdit", warm_panel(Color("37322e")))
	result.set_stylebox("focus", "LineEdit", warm_surface("focus"))
	result.set_constant("separation", "VBoxContainer", 12)
	result.set_constant("separation", "HBoxContainer", 8)
	var divider := StyleBoxLine.new()
	divider.color = Color("736454")
	divider.thickness = 1
	result.set_stylebox("separator", "HSeparator", divider)
	window_chrome(result, true)
	return result

static func window_chrome(target: Theme, warm: bool) -> void:
	var border := StyleBoxFlat.new()
	border.bg_color = Color("292624") if warm else Color("101c26")
	border.border_color = Color("57514c") if warm else Color("243440")
	border.set_border_width_all(2)
	border.border_width_top = 30
	border.expand_margin_top = 30
	border.expand_margin_left = 2
	border.expand_margin_right = 2
	border.expand_margin_bottom = 2
	for state in ["embedded_border", "embedded_unfocused_border"]: target.set_stylebox(state, "Window", border)
	target.set_color("title_color", "Window", WARM_MUTED if warm else MUTED)
	target.set_font("title_font", "Window", REGULAR)
	target.set_font_size("title_font_size", "Window", 18)
