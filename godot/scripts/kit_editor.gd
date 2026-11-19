class_name KitEditor
extends AcceptDialog

signal applied
var model: CombatModel
var character: int
var slot: int
var draft: Dictionary
var values: Array[Dictionary] = []
var tracks: Array[Dictionary] = []
var status: Label

func open_for(source: CombatModel, fighter: int, action: int) -> void:
	model = source
	character = fighter
	slot = action
	draft = model.data()
	title = "%s · %s · Kit controls" % [CombatModel.CHARACTERS[character], model.move_name(character, slot)]
	get_ok_button().text = "Close"
	var layout := VBoxContainer.new()
	add_child(layout)
	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(720, 540)
	layout.add_child(tabs)
	var fighter_data: Dictionary = draft.characters[character]
	for pair in [["Selected move", fighter_data.moves[slot].get("extensions", {})], ["Character", fighter_data.get("extensions", {})]]:
		var scroll := ScrollContainer.new()
		scroll.name = pair[0]
		tabs.add_child(scroll)
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(column)
		var extra: Dictionary = pair[1]
		if extra.is_empty():
			add_label(column, "This slot has no authored kit data.")
			continue
		add_label(column, "Timing uses unfrozen ticks. Distances below use pixels.")
		var grid := GridContainer.new()
		grid.columns = 2
		column.add_child(grid)
		for key in extra.params:
			if key == "policy": continue
			var scale := 100 if key in ["groundLeft","groundBottom","groundRight","groundTop","airLeft","airBottom","airRight","airTop","releaseGap","friction","coastCap","halfWidth","standingHeight","crouchingHeight","walkStride","runStride"] else 1
			add_label(grid, String(key).capitalize() + (" · px" if scale == 100 else ""))
			var spin := SpinBox.new()
			spin.min_value = -1000000.0 / scale
			spin.max_value = 1000000.0 / scale
			spin.step = 1.0 / scale
			spin.value = float(extra.params[key]) / scale
			grid.add_child(spin)
			values.append({"object": extra.params, "key": key, "input": spin, "scale": scale})
		if extra.has("routes"):
			for group in extra.routes:
				add_label(column, String(group).capitalize() + " cancel destinations")
				var routes := HFlowContainer.new()
				column.add_child(routes)
				for target in fighter_data.moves.size():
					if not fighter_data.moves[target].enabled: continue
					var check := CheckBox.new()
					check.text = model.move_name(character, target)
					check.button_pressed = target in extra.routes[group]
					routes.add_child(check)
					check.toggled.connect(func(enabled: bool):
						if enabled and not target in extra.routes[group]: extra.routes[group].append(target)
						elif not enabled: extra.routes[group].erase(target)
						extra.routes[group].sort())
		for key in ["hurtboxes", "pushboxes", "rootTrack", "verticalRootKeys", "profiles", "pairTracks"]:
			if not extra.has(key): continue
			var toggle := Button.new()
			toggle.text = String(key).capitalize() + " · advanced timeline data ▾"
			column.add_child(toggle)
			var text := TextEdit.new()
			text.text = JSON.stringify(extra[key], "  ")
			text.custom_minimum_size.y = 220
			text.visible = false
			column.add_child(text)
			toggle.pressed.connect(func(): text.visible = not text.visible)
			tracks.append({"object": extra, "key": key, "input": text})
		add_label(column, "Timeline coordinates use 100 integer units per pixel. Missing hurtbox regions are disabled; at most four regions. Frame keys start at 1, paired roots at C0. The browser Workshop provides visual key editing.")
	status = add_label(layout, "Changes apply together. Invalid values leave the current move set intact.")
	var apply := Button.new()
	apply.text = "Apply kit settings"
	layout.add_child(apply)
	apply.pressed.connect(apply_changes)
	popup_centered(Vector2i(760, 680))

func add_label(parent: Node, value: String) -> Label:
	var result := Label.new()
	result.text = value
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.custom_minimum_size.x = 260
	parent.add_child(result)
	return result

func apply_changes() -> void:
	for entry in values: entry.object[entry.key] = roundi(entry.input.value * entry.scale)
	for entry in tracks:
		var json := JSON.new()
		if json.parse(entry.input.text) != OK:
			status.text = "%s: %s" % [entry.key, json.get_error_message()]
			return
		entry.object[entry.key] = json.data
	var error := model.load_data(draft)
	status.text = "Kit settings applied. Save or export the move set to keep them." if error.is_empty() else error
	if error.is_empty(): applied.emit()
