extends SceneTree
var failures := 0
func check(value: bool, message: String) -> void:
	if not value: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var model := LegacyFixture.create()
	var data := model.data()
	check(data.schema == 24 and data.characters[2].moves.size() == 47, "Smoke schema missing")
	check(model.move(2,43).guardBreak == 1 and model.move(2,43).blockstun == 39, "Charged guard crush missing")
	for dust in [false,true]:
		model.reset([2,3])
		var input := 256 if dust else 2 | 128
		var frames := 28 if dust else 36
		for tick in range(1,frames):
			model.step(input,0)
			check(model.core.boxes(0,2).is_empty(), "Charge dealt damage before release")
		model.step(input,0)
		check(model.state().players[0].move == (44 if dust else 43), "Hold did not select charged slot")
		check(not model.core.boxes(0,2).is_empty(), "Charged active boxes missing")
	var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/2026-11-18-tapper/FightGuild-Tapper.json"))
	check(model.load_data(old).is_empty(), "Schema18 import failed")
	var upgraded := model.data()
	for c in 6:
		check(model.move(c,43).enabled == 0 and model.move(c,44).enabled == 0, "Legacy import enabled new charge slots")
		for m in 43:
			for field in CombatModel.FIELDS:
				var before: Dictionary = old.characters[c].moves[m]
				if not before.has(field): continue
				var expected: int = 2 if field == "startup" and before.category == 4 and before.motion == 0 else int(before[field])
				check(upgraded.characters[c].moves[m][field] == expected, "Legacy move was overwritten")
	print("Smoke normals / charge / legacy imports: %d failures" % failures)
	quit(1 if failures else 0)
