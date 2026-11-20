extends AcceptDialog

var tabs: Array[Button] = []
var bindings: VBoxContainer
var headings := ["Player 1", "Player 2", "Gamepad"]
const ACTIONS := ["Move / jump / crouch", "P", "K", "S", "Hs", "D", "Run / dash macro", "Simple modifier", "Faultless Defense", "Match menu"]
const BINDINGS := [
	["W / A / S / D", "J", "K", "L", "I", "O", "Space", "Left Shift", "Hold away + Q", "Esc"],
	["Arrow keys", "Numpad 1", "Numpad 2", "Numpad 3", "Numpad 5", "Numpad 6", "Numpad 0", "Numpad +", "Hold away + Numpad Enter", "Esc"],
	["D-pad / left stick", "Bottom face / A", "Left face / X", "Top face / Y", "Right face / B", "Right shoulder / RB", "Left shoulder / LB", "Left trigger / LT", "Hold away + right trigger / RT", "Start"]
]

func _ready() -> void:
	title = "Fight Guild · Controls"
	theme = GuildTheme.settings()
	ok_button_text = "Close"
	get_ok_button().hide()
	var layout := VBoxContainer.new()
	add_child(layout)
	var heading := label(layout, "CONTROLS", 30, GuildTheme.CREAM)
	heading.add_theme_font_override("font", GuildTheme.SEMIBOLD)
	label(layout, "View the current bindings for each control scheme.", 18, GuildTheme.WARM_MUTED)
	layout.add_child(HSeparator.new())
	var navigation := HBoxContainer.new()
	layout.add_child(navigation)
	var group := ButtonGroup.new()
	for i in headings.size():
		var tab := Button.new()
		tab.text = headings[i]
		tab.theme_type_variation = "SettingsTab"
		tab.toggle_mode = true
		tab.button_group = group
		tab.custom_minimum_size.y = 40
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.pressed.connect(func(): show_bindings(i))
		navigation.add_child(tab)
		tabs.append(tab)
	var scroll := ScrollContainer.new()
	scroll.name = "ControlsBody"
	scroll.custom_minimum_size = Vector2(760, 340)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	layout.add_child(scroll)
	bindings = VBoxContainer.new()
	bindings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(bindings)
	var footer := HBoxContainer.new()
	layout.add_child(footer)
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(space)
	var close := Button.new()
	close.name = "CloseAction"
	close.text = "Close"
	close.custom_minimum_size = Vector2(90, 40)
	close.pressed.connect(func(): confirmed.emit())
	footer.add_child(close)
	show_bindings(0)
	visibility_changed.connect(func(): if visible: tabs[0].grab_focus.call_deferred())

func label(parent: Node, value: String, font_size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = value
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	parent.add_child(result)
	return result

func show_bindings(scheme: int) -> void:
	tabs[scheme].set_pressed_no_signal(true)
	for child in bindings.get_children():
		bindings.remove_child(child)
		child.queue_free()
	label(bindings, headings[scheme].to_upper() + " / BINDINGS", 18, GuildTheme.ORANGE)
	for i in ACTIONS.size():
		var row := HBoxContainer.new()
		bindings.add_child(row)
		var action := label(row, ACTIONS[i], 20, GuildTheme.CREAM)
		action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var keycap := PanelContainer.new()
		keycap.add_theme_stylebox_override("panel", GuildTheme.warm_panel(Color("57514c")))
		keycap.custom_minimum_size.x = 340
		row.add_child(keycap)
		label(keycap, BINDINGS[scheme][i], 20, GuildTheme.CREAM)
	bindings.add_child(HSeparator.new())
	label(bindings, "MOTIONS & DEFENSE", 18, GuildTheme.ORANGE)
	var note := label(bindings, "Enable simplified inputs at fighter select; hold the modifier for shortcuts.
Fillet: 236K spiral; 236S > 6S > 2S, or 236S > 2S. Simple: 6K / 6S.
Shark: 214S / j.214P hook; P after a successful hit to stab. Simple: 4S / j.4P.
66 or Dash starts a run (Anvil uses a step). Hold forward or Dash to run; 4 + Dash goes back. Run/step velocity carries into attacks.\nNumpad directions follow facing: 5 neutral, 2 down, 4 back, 6 forward; j. means airborne.\n2D: sweep. 4P+K / 6P+K: back / forward throw (+ means simultaneous).\nTraditional 236P, 236S and 623Hs remain available.\nHold away to block. Away + two of P / K / S / Hs activates FD, except grounded 4P+K (back throw).\nFD spends Momentum to prevent chip and add pushback. Guard break removes backdash and blockstun grab protection.\nOnline: both players use Player 1 controls locally. Click the arena after editing to resume gameplay input.", 18, GuildTheme.WARM_MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
