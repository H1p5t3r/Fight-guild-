extends SceneTree

# Re-certify ordinary inputs against the shipped kit. Never patch positions,
# damage or stun during a route. This does not build or publish the Workshop.
const SOURCE := "res://../exports/FightGuild-Combo-Routes-2026-11-25.json"
func _initialize() -> void: call_deferred("run")
func reject(message: String) -> void:
	printerr("Trial certification failed: " + message)
	quit(1)

func run() -> void:
	var film: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	var current: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	var model := CombatModel.new()
	var error := model.load_file("res://data/workshop/" + str(current.file))
	if not error.is_empty(): reject(error); return
	var catalog := {"version": 1, "fps": 60, "kit": current.file, "fingerprint": model.fingerprint(), "source": "FightGuild-Combo-Routes-2026-11-25.json", "trials": []}
	for original in film.clips:
		# The old grounded hook route and 50% super route are no longer legal.
		if original.id in ["shark-corner", "anvil-corner"]: continue
		var clip: Dictionary = original.duplicate(true)
		clip.comboEnd = int(clip.events[-1].frame)
		if clip.id == "shark-midscreen":
			clip.route = clip.route.slice(0, 3)
			clip.comboEnd = 73
			clip.title = "Shoulder snap links"
			clip.condition = "6S > c.S > 6S. Wait through recovery before linking the next Slash."
		model.reset(clip.initial.characters)
		for p in 2: model.core.preview_place(p, int(clip.initial.positions[p]), 0, int(clip.initial.momentum))
		for pair in clip.initial.get("setupInputs", []): model.step(int(pair[0]), int(pair[1]))
		var base_health: int = model.state().players[1].health
		var last_serial: int = model.state().players[0].attackSerial
		var starts := []
		var contacts := []
		var runs := []
		var max_hits := 0
		for index in int(clip.comboEnd):
			var raw := int(clip.inputs[index][0])
			var before := model.state()
			var guarding := max_hits > 0
			var away := 1 if int(before.players[1].facing) == 1 else 2
			model.step(raw, away | 4 if guarding else 0)
			var state := model.state()
			if runs.is_empty() or int(runs[-1][1]) != raw: runs.append([1, raw])
			else: runs[-1][0] += 1
			if int(state.players[0].attackSerial) != last_serial:
				var step := 0
				for i in clip.route.size():
					if index + 1 >= int(clip.route[i].inputFrame): step = i
				starts.append({"frame": index + 1, "slot": state.players[0].move, "step": step})
				last_serial = int(state.players[0].attackSerial)
			for cue in model.cues.events_at(model.frame() - 1):
				if cue.actor != 0 or not cue.kind in [1, 2, 3, 4, 5, 6, 7]: continue
				if cue.kind not in [1, 3, 4]: reject("Blocked trial: " + str(clip.id)); return
				contacts.append({"frame": index + 1, "slot": cue.move})
				if int(state.players[0].combo) != contacts.size(): reject("Combo dropped: " + str(clip.id)); return
				max_hits = int(state.players[0].combo)
			if max_hits > 0 and int(state.players[0].combo) < max_hits: reject("Combo ended too early: " + str(clip.id)); return
		if contacts.is_empty() or starts.size() < clip.route.size(): reject("Missing move/contact: " + str(clip.id)); return
		var title: String = clip.title
		var hint: String = clip.condition
		if int(clip.character) == 0: hint = "Hold back through 5Hs, then forward + Hs to cancel into the armored charge."
		elif int(clip.character) == 1: hint = "Cancel the special into Drive, then 6Hs during the step. The second strike carries dash momentum."
		elif int(clip.character) == 2: hint = "Hold D through the long note to charge the opener. Buffer each quarter-circle before its button."
		elif int(clip.character) == 5: hint = "Press at the line, not on impact. 6Hs launches; buffer 236S, then pick up with 2K."
		elif clip.id == "tapper-stance": hint = "Starts in Dempsey stance, earned by a recorded 5D setup. Release S between the repeated hooks."
		elif clip.id == "tapper-midscreen": hint = "A short starter: close Slash into far Slash, then crouching Heavy Slash."
		var item := {"id": clip.id, "character": clip.character, "title": title, "hint": hint, "initial": clip.initial,
			"steps": clip.route, "runs": runs, "starts": starts, "contacts": contacts, "duration": int(clip.comboEnd),
			"hits": max_hits, "damage": base_health - int(model.state().players[1].health), "corner": bool(clip.wallBreak) or str(clip.id).ends_with("corner")}
		catalog.trials.append(item)
		print("Certified ", item.id, " / ", item.hits, " hits / ", item.damage, " damage")
	var file := FileAccess.open("res://data/combo_trials.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(catalog, "\t") + "\n")
	print("Certified ", catalog.trials.size(), " native rhythm trials.")
	quit()
