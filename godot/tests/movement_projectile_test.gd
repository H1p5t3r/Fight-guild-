extends SceneTree
var failures := 0
func check(value: bool, message: String) -> void:
	if not value: failures += 1; push_error(message)
func _initialize() -> void:
	var model := LegacyFixture.create()
	var data := model.data()
	var legacy := data.duplicate(true)
	legacy.schema = 14
	legacy.coreVersion = 14
	LegacyFixture.strip_extensions(legacy)
	for c in legacy.characters:
		c.moves.resize(32)
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
	var previous := data.duplicate(true)
	previous.schema = 21
	previous.coreVersion = 21
	LegacyFixture.strip_extensions(previous)
	for character in previous.characters:
		character.movement.erase("airDashPauseFrames")
		character.movement.erase("airBackdashPauseFrames")
	previous.characters[5].movement.jumpSpeed = 1875
	previous.characters[5].moves[24].startup = 7
	check(model.load_data(previous).is_empty(), "Version-21 movement import failed")
	check(model.movement(5).airDashPauseFrames == 4 and model.movement(5).airBackdashPauseFrames == 4 and model.movement(5).jumpSpeed == 1875 and model.move(5, 24).startup == 7, "Air pause migration changed existing edits")
	var airborne := model.data()
	airborne.characters[5].movement.airDashStyle = 1
	airborne.characters[5].movement.airDashPauseFrames = 6
	check(model.load_data(airborne).is_empty(), "Authored air pause rejected")
	model.reset()
	model.step(8, 0)
	for i in 8: model.step(0, 0)
	model.step(512, 0)
	var held: Dictionary = model.state().players[0]
	check(held.dashPause == 5 and held.vx == 0 and held.vy == 0, "Air dash did not clear jump velocity")
	snapshot = model.core.snapshot()
	for i in 5:
		model.step(0, 0)
		var frame: Dictionary = model.state().players[0]
		check(frame.x == held.x and frame.y == held.y and frame.vx == 0 and frame.vy == 0, "Air dash drifted during its pause")
	model.step(0, 0)
	check(model.state().players[0].x > held.x and model.state().players[0].dashAge == 1, "Air dash burst did not start after pause")
	expected = model.state_hash()
	check(model.core.restore(snapshot), "Air pause snapshot rejected")
	for i in 6: model.step(0, 0)
	check(model.state_hash() == expected, "Air pause rollback changed burst timing")
	print("Godot movement, projectiles and schema migration: %d failures" % failures)
	quit(1 if failures else 0)
