extends SceneTree

# Visual fixture: shows the supplied surfaces at once, including transient states.
# Run with a rendering display and -- --screenshot /absolute/path.png.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var canvas := Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.theme = GuildTheme.stock()
	root.add_child(canvas)
	canvas.add_child(preload("res://scripts/guild_backdrop.gd").new())
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 28)
	canvas.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	label(content, "FIGHT GUILD / SHARED MENU SURFACES", 30)
	label(content, "Guild Ball reference kit · native text and controls · fixed artwork corners", 18)
	var stock := PanelContainer.new()
	content.add_child(stock)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 12)
	stock.add_child(grid)
	for title in ["STOCK", "NORMAL", "HOVER", "PRESSED", "FOCUS", "DISABLED"]: label(grid, title, 18)
	for family in ["primary", "secondary", "essential", "danger"]:
		label(grid, family.to_upper(), 18)
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			var button := Button.new()
			button.text = {"primary":"Local versus", "secondary":"Back", "essential":"Start match", "danger":"Restore defaults"}[family]
			GuildTheme.apply(button, family)
			button.custom_minimum_size = Vector2(190, 40)
			button.disabled = state == "disabled"
			if state in ["hover", "pressed"]: button.add_theme_stylebox_override("normal", GuildTheme.surface(family + "-" + state))
			if state == "focus": button.draw.connect(func(): button.draw_style_box(GuildTheme.surface(family + "-focus"), Rect2(Vector2.ZERO, button.size)))
			grid.add_child(button)
	var warm := PanelContainer.new()
	warm.theme = GuildTheme.settings()
	content.add_child(warm)
	var settings := VBoxContainer.new()
	warm.add_child(settings)
	label(settings, "CONTROLS / WARM SETTINGS SKIN", 24)
	var row := HBoxContainer.new()
	settings.add_child(row)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var button := Button.new()
		button.text = state.capitalize()
		button.custom_minimum_size = Vector2(190, 40)
		button.disabled = state == "disabled"
		if state in ["hover", "pressed"]: button.add_theme_stylebox_override("normal", GuildTheme.warm_surface("secondary-" + state))
		if state == "focus": button.draw.connect(func(): button.draw_style_box(GuildTheme.warm_surface("focus"), Rect2(Vector2.ZERO, button.size)))
		row.add_child(button)
	label(content, "Focus is an independent outline. Disabled actions keep readable, muted labels.\nNormal menus keep the blue / brass palette; Controls owns its warm theme.", 18)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var args := OS.get_cmdline_user_args()
	if args.has("--screenshot"):
		var result := root.get_texture().get_image().save_png(args[args.find("--screenshot") + 1])
		if result != OK: quit(1); return
	print("Menu surface review rendered at ", root.size)
	quit()

func label(parent: Node, value: String, font_size: int) -> void:
	var node := Label.new()
	node.text = value
	node.add_theme_font_size_override("font_size", font_size)
	parent.add_child(node)
