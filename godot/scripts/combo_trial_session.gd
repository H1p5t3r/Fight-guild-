class_name ComboTrialSession
extends RefCounted

# Coaching follows input ticks (including hitstop), not animation frames or BPM.
# Only FightCore can award a clear. Matching chart notes is feedback, never proof.
const CATALOG := "res://data/combo_trials.json"
const COUNT_IN := 120
const NOTE_WINDOW := 10
var model := CombatModel.new()
var catalog: Dictionary = {}
var trial: Dictionary = {}
var inputs: Array[int] = []
var notes: Array[Dictionary] = []
var directions: Array[Dictionary] = []
var state := "ready"
var clock := -COUNT_IN
var demonstration := false
var mirrored := false
var start_index := 0
var contact_index := 0
var completed_step := -1
var serial := 0
var base_health := 1000
var damage := 0
var hits := 0
var previous_raw := 0
var blocked_buttons := 0
var feedback := "WATCH THE DEMO, THEN TAKE YOUR TURN"
var feedback_until := -10000
var failure := ""
var actual_notes: Array[Dictionary] = []
var matched_notes := 0
var total_error := 0

func load_catalog() -> String:
	catalog = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
	var current: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	var error := model.load_file("res://data/workshop/" + str(current.file))
	if not error.is_empty(): return error
	if model.fingerprint() != str(catalog.fingerprint):
		return "The fighter kits changed. These trials need to be re-verified before play."
	return ""

static func reflect(raw: int) -> int:
	return (raw & ~3) | ((raw & 1) << 1) | ((raw & 2) >> 1)

static func direction(raw: int) -> int:
	return 5 + int(bool(raw & 2)) - int(bool(raw & 1)) + 3 * (int(bool(raw & 8)) - int(bool(raw & 4)))

func select(item: Dictionary, right_side: bool = false) -> void:
	trial = item
	mirrored = right_side
	inputs.clear()
	for run in trial.runs:
		for _tick in int(run[0]): inputs.append(reflect(int(run[1])) if mirrored else int(run[1]))
	build_chart()
	reset()
	state = "ready"
	feedback = "WATCH THE DEMO, THEN TAKE YOUR TURN"

func build_chart() -> void:
	notes.clear()
	directions.clear()
	for lane in 5:
		var start := -1
		for i in inputs.size() + 1:
			var down := i < inputs.size() and bool(inputs[i] & (16 << lane))
			if down and start < 0: start = i + 1
			if not down and start >= 0:
				# The tail reaches the line on the first RELEASED input tick.
				notes.append({"frame": start, "end": i + 1, "lane": lane, "judge": "", "delta": 0})
				start = -1
	notes.sort_custom(func(a, b): return int(a.frame) < int(b.frame))
	var prior := 5
	for i in inputs.size():
		var value := direction(inputs[i])
		if value == prior: continue
		if not directions.is_empty(): directions[-1].end = i + 1
		directions.append({"frame": i + 1, "end": inputs.size(), "value": value})
		prior = value

func reset() -> void:
	model.reset(trial.initial.characters)
	for p in 2:
		var x := int(trial.initial.positions[p])
		model.core.preview_place(p, 100000 - x if mirrored else x, 0, int(trial.initial.momentum))
	for pair in trial.initial.get("setupInputs", []):
		model.step(reflect(int(pair[0])) if mirrored else int(pair[0]), reflect(int(pair[1])) if mirrored else int(pair[1]))
	# Discard prelude sound/particles. The stance itself remains an earned state.
	model.cues.reset()
	clock = -COUNT_IN
	start_index = 0
	contact_index = 0
	completed_step = -1
	serial = int(model.state().players[0].attackSerial)
	base_health = int(model.state().players[1].health)
	damage = 0
	hits = 0
	previous_raw = 0
	blocked_buttons = 0
	failure = ""
	actual_notes.clear()
	matched_notes = 0
	total_error = 0
	for note in notes: note.judge = ""; note.delta = 0

func begin(demo: bool) -> void:
	reset()
	demonstration = demo
	state = "countdown"
	feedback = "WATCH" if demo else "GET READY"

func running() -> bool:
	return state in ["countdown", "play"]

func expected_step() -> int:
	if start_index >= trial.starts.size(): return trial.steps.size() - 1
	return int(trial.starts[start_index].step)

func fail_attempt(reason: String) -> void:
	failure = reason
	state = "failed"
	feedback = "TRY AGAIN"

func judge_input(raw: int) -> void:
	var pressed := raw & ~previous_raw
	for lane in 5:
		if not pressed & (16 << lane): continue
		var best := -1
		var nearest := NOTE_WINDOW + 1
		for i in notes.size():
			var note := notes[i]
			if int(note.lane) != lane or not str(note.judge).is_empty(): continue
			var distance := absi(clock - int(note.frame))
			if distance < nearest: nearest = distance; best = i
		var judgement := "EXTRA"
		if best >= 0:
			var delta := clock - int(notes[best].frame)
			judgement = "ON TIME" if delta == 0 else "EARLY" if delta < 0 else "LATE"
			notes[best].judge = judgement
			notes[best].delta = delta
			matched_notes += 1
			total_error += absi(delta)
			feedback = judgement if delta == 0 else "%s %df" % [judgement, absi(delta)]
		else: feedback = "EXTRA " + CombatModel.BUTTONS[lane]
		actual_notes.append({"frame": clock, "lane": lane, "judge": judgement})
		feedback_until = clock + 28
	for note in notes:
		if str(note.judge).is_empty() and clock > int(note.frame) + NOTE_WINDOW:
			note.judge = "MISSED"
			feedback = "MISSED " + CombatModel.BUTTONS[int(note.lane)]
			feedback_until = clock + 28
	previous_raw = raw

func advance(raw: int = 0) -> void:
	if not running(): return
	clock += 1
	if clock <= 0:
		# A button held before GO cannot become a fresh attack on frame one.
		blocked_buttons = raw & ~15
		return
	state = "play"
	if demonstration: raw = inputs[clock - 1] if clock <= inputs.size() else 0
	else:
		blocked_buttons &= raw
		raw &= ~blocked_buttons
	judge_input(raw)
	var before := model.state()
	var away := 1 if int(before.players[1].facing) == 1 else 2
	# Crouch guard after first hit: a gap blocks lows/mids, and the live combo
	# counter still rejects a gap into an overhead or unblockable.
	model.step(raw, (away | 4) if contact_index > 0 else 0)
	var after := model.state()
	damage = maxi(damage, base_health - int(after.players[1].health))
	hits = maxi(hits, int(after.players[0].combo))
	if int(after.players[0].attackSerial) != serial:
		serial = int(after.players[0].attackSerial)
		if int(after.players[0].move) >= 0:
			if start_index >= trial.starts.size() or int(after.players[0].move) != int(trial.starts[start_index].slot):
				fail_attempt("Expected " + str(trial.steps[expected_step()].notation) + ", got " + model.move_name(int(trial.character), int(after.players[0].move)) + ". Check direction, spacing or cancel timing.")
				return
			completed_step = int(trial.starts[start_index].step)
			start_index += 1
	for cue in model.cues.events_at(model.frame() - 1):
		if cue.actor != 0 or not cue.kind in [1, 2, 3, 4, 5, 6, 7]: continue
		if cue.kind not in [1, 3, 4]: fail_attempt("The defender blocked. The combo had a gap."); return
		if contact_index >= trial.contacts.size() or int(cue.move) != int(trial.contacts[contact_index].slot):
			fail_attempt("The hits landed in a different order. Follow the displayed route."); return
		contact_index += 1
		if int(after.players[0].combo) != contact_index:
			fail_attempt("The combo dropped before that hit. Try the next input sooner."); return
	if contact_index == trial.contacts.size() and start_index == trial.starts.size():
		state = "success"
		feedback = "DEMO COMPLETE" if demonstration else "COMBO CLEAR"
	elif contact_index > 0 and int(after.players[0].combo) < contact_index:
		fail_attempt("Combo dropped before " + str(trial.steps[expected_step()].notation) + ". Watch the timing, then retry.")
	elif clock > int(trial.duration) + 90:
		fail_attempt("No complete combo. Press each button at the line and follow the direction track.")
