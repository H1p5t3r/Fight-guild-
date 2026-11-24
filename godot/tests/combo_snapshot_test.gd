extends SceneTree

var failures := 0
var restores := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var model := CombatModel.new()
	var data := model.data()
	# Legal authoring limits, with decay amplifying speed beyond voluntary
	# movement's 40 px/tick cap. The test changes no saved move data.
	var move: Dictionary = data.characters[1].moves[0]
	move.groundHitSpeed = 4000
	move.airHitSpeed = 4000
	move.starterDecay = 100
	move.wallBounce = 3000
	data.comboRules.decayPushCap = 600
	check(model.load_data(data).is_empty(), "Valid high-decay physics fixture")
	for side in 2:
		for airborne in [false, true]:
			model.reset([1, 4])
			var ax := 88000 if airborne else 45000
			var bx := 96000 if airborne else 52000
			model.core.preview_place(0, 100000 - ax if side else ax, 0, 0)
			model.core.preview_place(1, 100000 - bx if side else bx, 3000 if airborne else 0, 0)
			model.core.preview_begin(0, 0)
			var fast_hit := false
			var fast_bounce := false
			var pending_bounce := false
			for tick in 140:
				model.step(0, 0)
				var target: Dictionary = model.state().players[1]
				fast_hit = fast_hit or abs(int(target.vx)) == 10000
				fast_bounce = fast_bounce or abs(int(target.vx)) == 18000
				pending_bounce = pending_bounce or int(target.wallBounce) == 18000
				var saved := model.core.snapshot()
				var before := model.state_hash()
				var restored: bool = model.core.restore(saved)
				check(restored, "Core rejected its own combo snapshot / side %d / air %s / tick %d / vx %d / bounce %d" % [side, airborne, tick, target.vx, target.wallBounce])
				if not restored: break
				check(model.state_hash() == before, "Restored contact checksum differs")
				# Exercise actual resimulation, including freeze, collision and landing.
				model.step(0, 0)
				var next := model.state_hash()
				check(model.core.restore(saved), "Second snapshot restore")
				model.step(0, 0)
				check(model.state_hash() == next, "Combo resimulation differs")
				restores += 2
			check(fast_hit, "Fixture reached capped hit velocity")
			if airborne: check(fast_bounce and pending_bounce, "Fixture reached scaled wall-bounce velocity")
	print("Godot amplified combo velocity snapshots: %d restores, %d failures" % [restores, failures])
	quit(1 if failures else 0)
