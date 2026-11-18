extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; push_error(message)
func _initialize() -> void:
	var model := CombatModel.new()
	var data := model.data()
	check(data.schema == 19 and data.characters[3].moves.size() == 45, "Tapper schema/slots missing")
	check(model.movement(3).forwardStyle == 1, "Tapper must step dash")
	check(model.core.can_cancel(3, 37, 37, true) and model.core.can_cancel(3, 38, 39, true), "Stance routes missing")
	model.reset([3, 4])
	for tick in 24: model.step(2, 0)
	model.step(256, 0)
	var captured := false
	for tick in 80:
		model.step(0, 0)
		if model.state().players[0].grabTime > 0:
			captured = true
			break
	check(captured and model.state().players[1].reaction == 6, "Collar capture did not start")
	var snapshot: PackedByteArray = model.core.snapshot()
	for tick in 80: model.step(0, 0)
	var expected := model.state_hash()
	check(model.state().players[0].stance == 1 and model.state().players[1].health == 935, "Headbutt/stance finish failed")
	check(model.core.restore(snapshot), "Native capture snapshot rejected")
	for tick in 80: model.step(0, 0)
	check(model.state_hash() == expected, "Capture replay diverged")
	check(model.state().players[0].posePhase == 8, "Rolling idle missing")
	model.step(4, 0)
	model.step(6, 0)
	model.step(258, 0)
	check(model.state().players[0].move == 40, "236D did not choose running tackle")
	var copy := model.data()
	copy.characters[3].moves[40].grabFrames = 30
	check(model.load_data(copy).is_empty() and model.move(3, 40).grabFrames == 30, "New editor field failed round trip")
	print("Godot Tapper inputs, capture, stance and rollback: %d failures" % failures)
	quit(1 if failures else 0)
