extends SceneTree

var failures := 0
func check(value: bool, message: String) -> void:
	if not value: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var model := CombatModel.new()
	var data := model.data()
	check(data.schema == 27, "Pull schema missing")
	# The retired Chase slot is now No Safe Harbour. It must remain a super,
	# never regain Chase's pull mechanic; legacy migration below still retires it.
	check(data.characters[4].moves[12].enabled and data.characters[4].moves[12].actionType == 13 and data.characters[4].moves[12].mechanic == 0, "Retired Chase replaced the current super")
	var old := data.duplicate(true)
	old.schema = 24; old.coreVersion = 24
	old.characters[4].moves[12].enabled = 1; old.characters[4].moves[12].mechanic = 5
	old.characters[4].moves[12].tetherSpeed = 1789
	check(model.load_data(old).is_empty(), "Schema-24 import failed")
	check(not model.move(4,12).enabled and model.move(4,12).mechanic == 0 and model.move(4,12).tetherSpeed == 1789, "Retired Chase migration lost tuning")
	model.reset([4,0])
	model.core.preview_place(0, 40000, 0, 10000)
	model.core.preview_place(1, 65000, 0, 10000)
	check(model.core.preview_status(1, 2, 14), "Preview mark failed")
	model.step(4 | 256, 0)
	for tick in range(1, 11): model.step(0, 0)
	model.step(0, 16)
	var target: Dictionary = model.state().players[1]
	check(target.linePullTime == 9 and target.linePullHeld == 0, "Pull state adapter differs from core")
	check(target.move == 0 and target.stun == 0 and target.health == 1000, "Pull interrupted the opponent's punch")
	check(model.state().players[0].contactCount == 0 and model.state().hitstop == 0, "Pull registered as a hit")
	print("Shark actionable pull and schema migration: %d failures" % failures)
	quit(1 if failures else 0)
