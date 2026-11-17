extends SceneTree
var failures := 0
func check(value: bool, message: String) -> void:
	if not value: failures += 1; push_error(message)
func _initialize() -> void:
	var model := CombatModel.new()
	var data := model.data()
	var legacy := data.duplicate(true)
	legacy.schema = 14
	legacy.coreVersion = 14
	for c in legacy.characters:
		for key in CombatModel.MOVEMENT_FIELDS.slice(9): c.movement.erase(key)
		for m in c.moves:
			for key in CombatModel.FIELDS.slice(69): m.erase(key)
	legacy.characters[5].movement.walkSpeed = 321
	check(model.load_data(legacy).is_empty(), "Legacy movement import failed")
	check(model.movement(5).walkSpeed == 321 and model.movement(5).airDashEnabled == 0, "Legacy edits/defaults lost")
	data.characters[5].movement.forwardStyle = 3
	data.characters[5].movement.airDashEnabled = 1
	data.characters[5].moves[0].projectileKind = 1
	data.characters[5].moves[0].projectilePersist = 1
	check(model.load_data(data).is_empty(), "New profile import failed")
	check(model.data().characters[5].moves[0].projectileKind == 1, "Projectile lost on export")
	model.reset()
	model.step(512, 0)
	for i in 5: model.step(0, 0)
	check(model.state().players[0].x > model.state().players[1].x, "Teleport failed to switch sides")
	model.reset()
	model.step(16, 0)
	for i in 5: model.step(0, 0)
	check(model.state().projectiles.size() > 0, "Projectile not exposed to Godot")
	var snapshot: PackedByteArray = model.core.snapshot()
	for i in 50: model.step(0, 0)
	var expected := model.state_hash()
	check(model.core.restore(snapshot), "Snapshot with live projectile rejected")
	for i in 50: model.step(0, 0)
	check(model.state_hash() == expected, "Projectile replay desynchronized")
	check(model.state().players[1].health < 1000, "Projectile did not hit")
	print("Godot movement, projectiles and schema migration: %d failures" % failures)
	quit(1 if failures else 0)
