extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; printerr(message)
func _initialize() -> void:
	var model := LegacyFixture.create()
	var original := model.data()
	check(original.schema == 25, "Current schema version missing")
	var legacy := original.duplicate(true)
	legacy.schema = 9
	legacy.coreVersion = 9
	LegacyFixture.strip_extensions(legacy)
	for character in legacy.characters:
		character.moves.resize(32)
		for move in character.moves:
			move.erase("counterFreezeFrames")
			move.erase("counterSlowFrames")
	legacy.characters[5].moves[3].counterHitstun = 17
	check(model.load_data(legacy).is_empty(), "Schema-9 migration rejected")
	check(model.move(5, 3).counterHitstun == 17 and model.move(5, 3).counterFreezeFrames == -1 and model.move(5, 3).counterSlowFrames == 0, "Migration changed authored counter timing")
	check(model.load_data(original).is_empty(), "Counter defaults rejected")
	for field in ["counterFreezeFrames", "counterSlowFrames"]:
		var bad := original.duplicate(true)
		bad.characters[5].moves[3][field] = 999
		check(not model.load_data(bad).is_empty() and model.data() == original, "Invalid counter edit changed live data")
	var data := original.duplicate(true)
	var move: Dictionary = data.characters[5].moves[0]
	move.counterTier = 3
	move.counterFreezeFrames = 31
	move.counterSlowFrames = 35
	move.counterHitstun = 0
	move.hitstun = 60
	move.reach = 50000
	move.pushback = 0
	check(model.load_data(data).is_empty(), "Counter fixture rejected")
	model.reset([5, 4])
	for tick in 5: model.step(16, 128)
	var state := model.state()
	check(state.players[0].event == 3 and state.hitstop == 31 and state.players[1].counterSlowTime == 35 and state.impactTier == 3, "Heavy counter did not create freeze/slowdown")
	var feedback := CombatFeedback.new()
	feedback.refresh(state, Vector2(1280, 720))
	check(feedback.zoom() > 1 and feedback.cards[0].tier == 3, "Counter camera/text classification missing")
	feedback.reduced_motion = true
	check(feedback.zoom() == 1, "Reduced motion still zoomed the camera")
	var display := state.duplicate(true)
	display.players[0].comboTime = 90
	for reduced in [false, true]:
		feedback.reduced_motion = reduced
		for age in [0, 15]:
			display.players[0].comboAge = age
			var previous := 0
			var at_two := 0
			var at_ten := 0
			for count in [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 20, 100]:
				display.players[0].comboDisplay = count
				feedback.refresh(display, Vector2(1248, 642))
				var size: int = feedback.cards[0].font_size
				if count == 2: at_two = size
				if count == 10: at_ten = size
				check(size > previous if count <= 10 else size == at_ten, "Combo size does not grow toward and stop at ten hits")
				check(feedback.cards[0].center_y < 642 * 0.55, "Combo counter fell back to the bottom of the screen")
				previous = size
			check(at_two < at_ten * 0.5, "A short combo starts too large")
	for tick in 32: model.step(0, 0)
	state = model.state()
	check(state.players[1].counterSlowHeld == 1 and state.players[1].counterSlowTime == 34 and state.players[1].stun == 60, "First slowed frame did not hold defender")
	var snapshot := model.core.snapshot()
	for tick in 90: model.step(0, 0)
	var expected := model.state_hash()
	check(model.core.restore(snapshot), "Counter snapshot restore rejected legal state")
	for tick in 90: model.step(0, 0)
	check(model.state_hash() == expected, "Counter snapshot replay diverged")
	for delay in [1, 8, 12]:
		check(RollbackSession.trial(data, delay, 4, 1200).get("pass", false), "Counter clocks diverged under delayed input")
	print("Godot counter freeze, slowdown, migration and presentation: ", failures, " failures")
	quit(int(failures != 0))
