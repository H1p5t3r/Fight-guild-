extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; push_error(message)
func _initialize() -> void:
	var model := CombatModel.new()
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	var draft: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/2026-11-19-slash-sweeps/FightGuild-Slash-Sweeps.json"))
	check(model.load_data(draft).is_empty(), "Latest Slash/sweep draft must load")
	for c in 6:
		check(model.move_name(c, 2) == "f.S" and model.move_name(c, 32) == "c.S", "Close/far names missing")
		for player in 2:
			model.reset([c, c])
			for tick in 20: model.step(2, 0)
			var spacing: int = absi(model.state().players[0].x - model.state().players[1].x)
			for offset in [-1, 0, 1]:
				var boundary := draft.duplicate(true)
				boundary.characters[c].moves[2].proximityRange = spacing - offset
				check(model.load_data(boundary).is_empty(), "Native threshold edit rejected")
				model.reset([c, c])
				for tick in 20: model.step(2, 0)
				model.step(64 if player == 0 else 0, 64 if player == 1 else 0)
				check(model.state().players[player].move == (32 if offset <= 0 else 2), "Native proximity boundary incorrect")
		check(model.core.can_cancel(c, 32, 2, true) and model.core.can_cancel(c, 32, 6, true), "Close Slash gatlings missing")
		check(not model.core.can_cancel(c, 32, 2, false), "Whiff c.S must not cancel")
		var sweep := model.move(c, 6)
		check(sweep.knockdown == 2 and sweep.hitLevel == 1 and sweep.specialCancel == 1, "Universal sweep rules missing")
		check(sweep.blockstun - (sweep.active - 1 + sweep.recovery) <= -12 and sweep.blockstun - sweep.recovery <= -7, "Sweep is not punishably negative")
	check(model.load_data(draft).is_empty(), "Restore latest draft")
	var exported := model.data()
	check(exported.characters[0].moves[2].id == "5S", "Saved slot IDs must remain compatible")
	print("Godot close/far Slash, gatlings, sweep tuning and stable IDs: %d failures" % failures)
	quit(1 if failures else 0)
