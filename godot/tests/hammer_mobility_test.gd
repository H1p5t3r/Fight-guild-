extends SceneTree

const BEFORE := "res://data/workshop/2026-11-24-collar-fold/FightGuild-Collar-Fold.json"
const AFTER := "res://data/workshop/2026-11-24-hammer-movement/FightGuild-Hammer-Movement.json"
var failures := 0
var checks := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr(message)
func _initialize() -> void: call_deferred("run")

func probe(data: Dictionary, character: int, facing: int, mode: String, warmup: int = 0) -> Dictionary:
	var model := CombatModel.new()
	check(model.load_data(data).is_empty(), "Mobility data rejected")
	model.reset([character, 0])
	var start := (40000 if facing == 1 else 60000) if mode == "back" else (12000 if facing == 1 else 88000)
	model.core.preview_place(0, start, 0, 0)
	model.core.preview_place(1, 95000 if facing == 1 else 5000, 0, 0)
	var forward := 2 if facing == 1 else 1
	var direction := (1 if facing == 1 else 2) if mode == "back" else forward
	for tick in warmup: model.step(forward, 0)
	start = model.core.read_value(0, 0)
	var travel := []
	var velocity := []
	var first_key := -1
	var snapshot: PackedByteArray
	var replay := []
	var duration := 60 if mode == "run" else 30
	for tick in duration:
		if tick == 2: snapshot = model.core.snapshot()
		model.step(direction | (512 if mode == "run" and tick == 0 else 0), 0)
		travel.append(absi(model.core.read_value(0, 0) - start))
		velocity.append(absi(model.core.read_value(0, 39)))
		var gait := model.locomotion.at(model.frame(), 0)
		if int(gait.get("key", 0)) > 0 and first_key < 0: first_key = tick
		if tick >= 2: replay.append({"hash": model.state_hash(), "gait": gait.duplicate(true)})
	check(model.core.restore(snapshot), "Mobility snapshot rejected")
	for expected in replay:
		model.step(direction, 0)
		check(model.state_hash() == expected.hash and model.locomotion.at(model.frame(), 0) == expected.gait, "Retuned travel or gait diverged after restore")
	return {"travel": travel, "velocity": velocity, "first_key": first_key}

func run() -> void:
	var before: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BEFORE))
	var after: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(AFTER))
	var untouched := after.duplicate(true)
	for field in ["walkSpeed", "runSpeed", "runAcceleration"]:
		untouched.characters[1].movement[field] = before.characters[1].movement[field]
	check(untouched == before, "Hammer tuning altered another fighter, attack, rule or art brief")
	for facing in [-1, 1]:
		var old_walk := probe(before, 1, facing, "walk")
		var walk := probe(after, 1, facing, "walk")
		var smoke_walk := probe(after, 2, facing, "walk")
		check(walk.travel[-1] < old_walk.travel[-1] and walk.travel[-1] < smoke_walk.travel[-1], "Hammer walk was not reduced below Smoke")
		check(walk.first_key > old_walk.first_key, "Slower walk kept the same footfall cadence")
		var back := probe(after, 1, facing, "back")
		var old_back := probe(before, 1, facing, "back")
		var smoke_back := probe(after, 2, facing, "back")
		check(back.travel == old_back.travel and back.travel[-1] < smoke_back.travel[-1], "Retreat lost its existing speed hierarchy")
		for warmup in [0, 5]:
			var old_run := probe(before, 1, facing, "run", warmup)
			var run_data := probe(after, 1, facing, "run", warmup)
			var smoke := probe(after, 2, facing, "run", warmup)
			for tick in 60:
				check(run_data.velocity[tick] < smoke.velocity[tick], "Hammer accelerated/runs faster than Smoke")
				check(run_data.travel[tick] < smoke.travel[tick], "Hammer outran Smoke over sampled startup/travel")
			for tick in [11, 29, 59]: check(run_data.travel[tick] > old_run.travel[tick], "Run did not improve at short/medium/long distance")
			check(run_data.velocity[-1] == 1020 and smoke.velocity[-1] == 1050, "Run caps did not reach authored values")
			if warmup == 0:
				check(run_data.velocity.find(1020) == 3 and smoke.velocity.find(1050) == 2, "Run acceleration hierarchy changed")
				if facing == 1: print("Run distance after 12 / 30 / 60 ticks: previous Hammer %s / new Hammer %s / Smoke %s" % [[old_run.travel[11], old_run.travel[29], old_run.travel[59]], [run_data.travel[11], run_data.travel[29], run_data.travel[59]], [smoke.travel[11], smoke.travel[29], smoke.travel[59]]])
	print("Hammer mobility: %d failures; %d checks; authored isolation, walk/run hierarchy, footfalls and replay" % [failures, checks])
	quit(1 if failures else 0)
