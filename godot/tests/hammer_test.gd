extends SceneTree

var failures := 0
func check(value: bool, message: String) -> void:
	if not value: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var model := CombatModel.new()
	check(model.data().schema == 27, "Hammer schema missing")
	check(model.move(1,13).mechanic == 5, "Break Step kit missing")
	model.reset([1,5])
	model.core.preview_place(0, 30000, 0, 10000)
	model.core.preview_place(1, 70000, 0, 10000)
	model.step(256, 0)
	for tick in range(3): model.step(0, 0)
	check(model.state().players[0].x == 30000, "Drive moved during load")
	model.step(0, 0)
	check(model.state().players[0].driveUsed == 1, "Drive resource was not consumed")
	model.step(16, 0)
	check(model.state().players[0].move == 0 and model.state().players[0].driveBonus == 4, "Normal did not receive Drive boost")
	var snapshot: PackedByteArray = model.core.snapshot()
	for tick in range(90): model.step(0, 0)
	var expected: PackedByteArray = model.core.snapshot()
	check(model.core.restore(snapshot), "Drive snapshot rejected")
	for tick in range(90): model.step(0, 0)
	check(model.core.snapshot() == expected, "Drive replay diverged")
	check(model.state().players[0].driveUsed == 0, "Neutral did not restore Drive")
	var old := model.data()
	old.schema = 26; old.coreVersion = 26
	for c in old.characters:
		for m in c.moves:
			for key in ["driveDistance", "drivePlus", "driveNeutralFrames"]: m.erase(key)
	check(model.load_data(old).is_empty(), "Older JSON failed to migrate")
	check(model.move(1,13).drivePlus == 4, "Drive field default missing")
	print("Hammer Drive / native adapter / replay: %d failures" % failures)
	quit(1 if failures else 0)
