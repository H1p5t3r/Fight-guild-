extends SceneTree

var failures := 0
var checks := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr(message)
func _initialize() -> void: call_deferred("run")

func fixture(character: int, facing: int, offset: int = 0) -> CombatModel:
	var model := CombatModel.new()
	var batch: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	check(model.load_file("res://data/workshop/" + str(batch.file)).is_empty(), "Current batch rejected")
	model.reset([character, 0])
	model.core.preview_place(0, (28000 if facing == 1 else 72000) + offset, 0, 0)
	model.core.preview_place(1, (87000 if facing == 1 else 13000) + offset, 0, 0)
	if character == 3:
		model.core.preview_begin(0, 35)
		for tick in 35: model.step(0, 0)
	model.step(0, 0)
	return model

func choice(model: CombatModel) -> Dictionary:
	var f: Dictionary = model.state().players[0]
	return CombatMovement.selection(f, model.movement(f.character), model.locomotion.at(model.frame(), 0), model.move(f.character, f.move) if f.move >= 0 else {})

func run() -> void:
	for field in CombatLocomotion.SAMPLE_FIELDS:
		check(CombatModel.STATE_FIELDS[field] == CombatLocomotion.SAMPLE_FIELDS[field], "Native movement field mapping drifted")
	var arena = load("res://scripts/arena.gd").new()
	root.add_child(arena); arena.size = Vector2(1440, 810)
	var exercised := {}
	for character in [1, 3]:
		for facing in [-1, 1]:
			for operation in ["walk", "back", "dash", "backdash"]:
				var model := fixture(character, facing)
				var reverse: bool = operation in ["back", "backdash"]
				var input := (1 if facing == 1 else 2) if reverse else (2 if facing == 1 else 1)
				var snapshot: PackedByteArray
				var expected := []
				for tick in 80:
					if tick == 12: snapshot = model.core.snapshot()
					var pressed := input if tick < 65 else 0
					if tick == 0 and operation in ["dash", "backdash"]: pressed |= 512
					if tick == 67: pressed = 16 # A stop/settle must never lock out P.
					model.step(pressed, 0)
					var state := model.state()
					var f: Dictionary = state.players[0]
					var selected := choice(model)
					if tick >= 12 and tick < 32: expected.append({"hash": model.state_hash(), "choice": selected, "gait": model.locomotion.at(model.frame(), 0).duplicate(true)})
					if not selected.is_empty():
						exercised["%s/%d" % [selected.get("sheet", selected.get("source_phase", "")), selected.key]] = true
					var before: PackedByteArray = model.core.snapshot()
					var boxes: PackedInt32Array = model.core.boxes(0, 0)
					arena.refresh(model, state, false, false)
					check(before == model.core.snapshot() and boxes == model.core.boxes(0, 0), "Movement rendering changed physics or boxes")
					check(signf(arena.sprites[0].scale.x) == facing, "Locomotion changed facing")
					if tick == 67: check(f.move >= 0 and selected.is_empty(), "Stop settle delayed or masked the punch")
				check(model.core.restore(snapshot), "Locomotion snapshot restore failed")
				for record in expected:
					model.step(input, 0)
					check(model.state_hash() == record.hash, "Locomotion replay gameplay changed")
					check(choice(model) == record.choice and model.locomotion.at(model.frame(), 0) == record.gait, "Locomotion replay left predicted visual history")
			# Starting at another stage position must not change gait entry/key.
			var a := fixture(character, facing)
			var b := fixture(character, facing, 4000)
			for tick in 45:
				a.step(2 if facing == 1 else 1, 0); b.step(2 if facing == 1 else 1, 0)
				check(choice(a) == choice(b), "Absolute stage position affected gait")
	for key in range(8):
		check(exercised.has("hammer_walk/%d" % key), "Hammer walk missing opposite-leg key")
		check(exercised.has("hammer_back/%d" % key), "Hammer retreat missing key")
		check(exercised.has("hammer_run/%d" % key), "Hammer run missing opposite-leg key")
		check(exercised.has("tapper_travel/%d" % key), "Tapper shuffle direction missing key")
		check(exercised.has("tapper_dash/%d" % key), "Tapper guarded step dash missing key")
	# All four stance normals retain their active/load poses and withdraw only
	# inside existing recovery. Legal interruptions still belong to the core.
	for facing in [-1, 1]:
		for slot in [35, 36, 37, 38]:
			var model := fixture(3, facing)
			model.core.preview_begin(0, slot)
			var move := model.move(3, slot)
			var seen := {}
			for tick in int(move.startup) + int(move.active) + int(move.recovery) + 3:
				model.step(0, 0)
				var f: Dictionary = model.state().players[0]
				var selected := choice(model)
				if f.move == slot and f.age < int(move.startup) + int(move.active): check(selected.is_empty(), "Withdrawal replaced a load/active frame")
				if f.move == slot and f.age == int(move.startup) + int(move.active):
					check(selected.get("source_phase", "") == "signature_active", "First recovery tick flashed idle before withdrawal")
				if selected.get("sheet", "") == "tapper_return":
					seen[selected.key] = true
					check(f.move == slot and f.age >= int(move.startup) + int(move.active), "Withdrawal escaped authored recovery")
				arena.refresh(model, model.state(), false, false)
			check(seen.size() == 2, "Stance normal lacks withdrawal and settle")
	# A requested run stopped by a corner must plant, not treadmill/freeze aloft.
	var stopped := fixture(1, 1)
	stopped.core.preview_place(0, 80000, 0, 0); stopped.core.preview_place(1, 98000, 0, 0)
	var stationary := 0
	for tick in 180:
		var x := stopped.core.read_value(0, 0)
		stopped.step(2 | (512 if tick == 0 else 0), 0)
		if stopped.core.read_value(0, 0) == x and tick > 10:
			stationary += 1
			check(int(stopped.locomotion.at(stopped.frame(), 0).key) in [0, 4], "Obstruction froze airborne run pose")
	check(stationary > 10, "Obstruction fixture never stopped travel")
	var frame := stopped.frame()
	var prior := stopped.locomotion.at(frame, 0).duplicate(true)
	for tick in 9:
		stopped.locomotion.capture(frame + tick, true, stopped.core, [0, 0], [stopped.movement(1), stopped.movement(0)])
		check(stopped.locomotion.at(frame + tick + 1, 0) == prior, "Hitstop advanced a distance gait")
	stopped.reset([1, 0])
	check(stopped.locomotion.frames.is_empty(), "Reset leaked previous gait")
	# A late remote direction change must replace predicted walk/retreat art.
	var reference := CombatModel.new()
	var predicted := CombatModel.new()
	check(reference.load_data(stopped.data()).is_empty() and predicted.load_data(stopped.data()).is_empty(), "Rollback art fixture rejected")
	reference.reset([0, 1]); predicted.reset([0, 1])
	var session := RollbackSession.new(predicted)
	session.max_prediction = 20
	for tick in 12:
		reference.step(0, 2 if tick == 0 else 1)
		check(session.submit(0, tick, 0), "Local input rejected")
		if tick == 0: check(session.submit(1, tick, 2), "Initial remote direction rejected")
		check(session.advance(), "Prediction stopped early")
	for tick in range(1, 12): check(session.submit(1, tick, 1), "Late remote direction rejected")
	check(session.rollbacks > 0 and session.error.is_empty(), "Delayed input never exercised rollback")
	check(predicted.state_hash() == reference.state_hash(), "Delayed-input physics diverged")
	check(predicted.locomotion.at(predicted.frame(), 1) == reference.locomotion.at(reference.frame(), 1), "Late input retained a predicted retreat gait")
	arena.queue_free(); await process_frame
	print("Locomotion presentation: %d failures; %d checks; travel, stops, stance returns, both facings and rollback" % [failures, checks])
	quit(1 if failures else 0)
