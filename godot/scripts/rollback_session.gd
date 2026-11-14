class_name RollbackSession
extends RefCounted

var model: CombatModel
var actual := {}
var records := {}
var confirmed := [-1, -1]
var base_inputs := [0, 0]
var max_prediction := 12
var history_size := 240
var rollbacks := 0
var replayed := 0
var largest := 0
var error := ""

func _init(simulation: CombatModel) -> void:
	model = simulation
	if model.frame() != 0:
		error = "Rollback must start at frame zero."

func submit(player: int, frame: int, input: int) -> bool:
	if not error.is_empty():
		return false
	if player < 0 or player > 1 or frame < 0 or frame > model.frame() + 120 or input < 0 or input > 2047:
		error = "Invalid remote input."
		return false
	if frame < maxi(0, model.frame() - history_size):
		error = "Input arrived outside rollback history. Restart the match."
		return false
	var values: Array = actual.get(frame, [-1, -1])
	if values[player] != -1 and values[player] != input:
		error = "A peer changed an already submitted input."
		return false
	values[player] = input
	actual[frame] = values
	while actual.get(confirmed[player] + 1, [-1, -1])[player] != -1:
		confirmed[player] += 1
	if records.has(frame) and records[frame].inputs[player] != input:
		var end := model.frame()
		if not model.core.restore(records[frame].before):
			error = "Invalid rollback snapshot."
			return false
		for _frame in range(frame, end):
			simulate()
		rollbacks += 1
		replayed += end - frame
		largest = maxi(largest, end - frame)
	return true

func simulate() -> void:
	var frame := model.frame()
	var previous: Array = records.get(frame - 1, {"inputs": base_inputs}).inputs
	var values: Array = actual.get(frame, [-1, -1])
	var inputs := [values[0] if values[0] >= 0 else previous[0], values[1] if values[1] >= 0 else previous[1]]
	var before := model.core.snapshot()
	model.step(inputs[0], inputs[1])
	records[frame] = {"before": before, "inputs": inputs, "hash": model.state_hash()}

func advance() -> bool:
	if not error.is_empty() or model.frame() - mini(confirmed[0], confirmed[1]) > max_prediction:
		return false
	simulate()
	var expired := model.frame() - history_size - 1
	if expired >= 0:
		base_inputs = records.get(expired, {"inputs": base_inputs}).inputs
		records.erase(expired)
		actual.erase(expired)
	return true

func confirmed_hash(frame: int) -> int:
	if frame <= mini(confirmed[0], confirmed[1]) and records.has(frame):
		return records[frame].hash
	return -1

static func scripted_input(frame: int, player: int) -> int:
	var cycle := (frame + player * 37) % 120
	var toward := 1 if player else 2
	var away := 2 if player else 1
	if cycle < 16: return toward
	if cycle == 20: return 16
	if cycle == 30: return 32
	if cycle == 41: return 4
	if cycle == 42: return 4 | toward
	if cycle == 43: return toward | 64
	if cycle == 75: return 8
	if cycle == 80: return 128
	return away if cycle > 92 else 0

static func trial(data: Dictionary, latency: int = 6, jitter: int = 3, frame_count: int = 600) -> Dictionary:
	var reference := CombatModel.new()
	var predicted := CombatModel.new()
	if not reference.load_data(data).is_empty() or not predicted.load_data(data).is_empty():
		return {"pass": false, "error": "Invalid trial data."}
	var session := RollbackSession.new(predicted)
	session.max_prediction = 20
	var pending: Array[Dictionary] = []
	for frame in frame_count:
		var inputs := [scripted_input(frame, 0), scripted_input(frame, 1)]
		reference.step(inputs[0], inputs[1])
		session.submit(0, frame, inputs[0])
		pending.append({"at": frame + latency + (frame * 7 % (jitter + 1)), "frame": frame, "input": inputs[1]})
		for i in range(pending.size() - 1, -1, -1):
			if pending[i].at <= frame:
				var packet := pending[i]
				pending.remove_at(i)
				session.submit(1, packet.frame, packet.input)
		if not session.advance():
			return {"pass": false, "error": "Trial stalled: " + session.error}
	for packet in pending:
		session.submit(1, packet.frame, packet.input)
	return {"pass": session.error.is_empty() and reference.state_hash() == predicted.state_hash(), "hash": predicted.state_hash(), "rollbacks": session.rollbacks, "replayed": session.replayed, "largest": session.largest}
