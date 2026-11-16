class_name TrainingLab
extends RefCounted

const MAX_RECORDING := 1800
const TRACE_LENGTH := 180
var trace: Array[Dictionary] = []
var recording: Array[Vector2i] = []
var initial := PackedByteArray()
var fingerprint := ""
var recording_now := false
var playback := 0 # 0: stopped, 1: both players, 2: player-two dummy only.
var cursor := 0
var message := "Record up to 30 seconds. Replay restores the starting position and resources."
var final_hash := 0
var gaps := [0, 0]
var chains := [false, false]

func clear_trace() -> void:
	trace.clear()
	gaps = [0, 0]
	chains = [false, false]

func start_recording(model: CombatModel) -> void:
	stop()
	initial = model.core.snapshot()
	fingerprint = model.fingerprint()
	recording.clear()
	clear_trace()
	recording_now = true
	message = "RECORDING · both players · 30-second maximum"

func stop() -> void:
	if recording_now: message = "Saved %d frames in this session." % recording.size()
	elif playback: message = "Replay stopped."
	recording_now = false
	playback = 0
	cursor = 0

func start_replay(model: CombatModel, dummy_only: bool = false) -> bool:
	stop()
	if recording.is_empty(): message = "Record an exchange first."; return false
	if fingerprint != model.fingerprint(): message = "Move settings changed. Record a new exchange."; return false
	if not model.core.restore(initial): message = "The recording's starting state could not be restored."; return false
	clear_trace()
	playback = 2 if dummy_only else 1
	message = "REPLAY · P2 dummy; P1 is live" if dummy_only else "REPLAY · both players"
	return true

func inputs(a: int, b: int) -> Vector2i:
	if playback and cursor < recording.size():
		return Vector2i(a if playback == 2 else recording[cursor].x, recording[cursor].y)
	return Vector2i(a, b)

static func phase(model: CombatModel, fighter: Dictionary) -> String:
	if fighter.get("prejumpTime", 0): return "PREJUMP"
	if fighter.get("landingTime", 0): return "LAND"
	if fighter.reaction != 0: return "DOWN" if fighter.reaction in [2, 3] else "REEL"
	if fighter.stun: return "GUARD" if fighter.guarding else "HIT"
	if fighter.move >= 0:
		var move := model.move(fighter.character, fighter.move)
		if fighter.age < move.startup: return "START"
		if fighter.age < move.startup + move.active: return "ACTIVE"
		return "RECOVER"
	return "READY"

static func notation(raw: int, facing: int) -> String:
	var x := (int(bool(raw & 2)) - int(bool(raw & 1))) * facing
	var y := int(bool(raw & 8)) - int(bool(raw & 4))
	var value := str(5 + x + 3*y)
	for button in 5:
		if raw & (16 << button): value += CombatModel.BUTTONS[button]
	if raw & 512: value += " Dash"
	if raw & 1024: value += " Simple"
	if raw & 2048: value += " FD"
	return value

func observe(model: CombatModel, before: Dictionary, raw: Vector2i) -> void:
	var after := model.state()
	if after.frame == before.frame: return
	var tick := {"frame": before.frame, "freeze": before.hitstop > 0 or before.wallBreakTime > 0 or before.winner >= 0, "players": []}
	for p in 2:
		var old: Dictionary = before.players[p]
		var fighter: Dictionary = after.players[p]
		var contact: bool = fighter.contact != 0 and (old.contact == 0 or old.move != fighter.move)
		var incoming: bool = after.players[1-p].contact != 0 and (before.players[1-p].contact == 0 or before.players[1-p].move != after.players[1-p].move)
		if old.guarding and old.stun > 0: chains[p] = true
		if chains[p] and not tick.freeze and old.stun == 0 and old.reaction == 0 and old.get("landingTime", 0) == 0 and old.get("prejumpTime", 0) == 0: gaps[p] += 1
		var gap: int = gaps[p] if incoming and chains[p] else -1
		if incoming: gaps[p] = 0; chains[p] = bool(fighter.guarding)
		if gaps[p] > TRACE_LENGTH: gaps[p] = 0; chains[p] = false
		var label := phase(model, fighter)
		if old.get("landingTime", 0) > 0: label = "LAND"
		# The final recovery tick has just cleared the move in the core.
		if fighter.move < 0 and old.move >= 0 and not incoming: label = "RECOVER"
		tick.players.append({"phase": label, "move": fighter.move, "age": fighter.age,
			"input": raw.x if p == 0 else raw.y, "contact": contact, "gap": gap,
			"notation": notation(raw.x if p == 0 else raw.y, old.facing),
			"stun": fighter.stun, "advantage": fighter.blockAdvantage if fighter.guarding else null,
			"spacing": abs(after.players[0].x - after.players[1].x) / 100.0,
			"cancelMask": fighter.get("cancelMask", 0), "inputAge": fighter.get("inputAge", -1),
			"damage": fighter.get("lastDamage", 0), "baseDamage": fighter.get("lastBaseDamage", 0), "scaling": fighter.get("damageScale", 100),
			"gravity": fighter.gravityPercent, "slowHeld": fighter.get("counterSlowHeld", 0), "slowTime": fighter.get("counterSlowTime", 0)})
	trace.append(tick)
	if trace.size() > TRACE_LENGTH: trace.pop_front()
	if recording_now:
		recording.append(raw)
		final_hash = model.state_hash()
		if recording.size() >= MAX_RECORDING: stop()
	elif playback:
		cursor += 1
		if cursor >= recording.size():
			var verified := playback == 1 and model.state_hash() == final_hash
			message = "Replay complete · identical combat state." if verified else "Dummy replay complete." if playback == 2 else "Replay mismatch — record a new exchange."
			playback = 0
