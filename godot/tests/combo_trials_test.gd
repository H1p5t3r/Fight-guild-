extends SceneTree

var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr(message)
func countdown(session: ComboTrialSession, raw: int = 0) -> void:
	while session.clock < 0: session.advance(raw)
func play(session: ComboTrialSession, trace: Array) -> void:
	for raw in trace:
		session.advance(int(raw))
		if not session.running(): break
	for _tick in 110: session.advance(0)

func run() -> void:
	var session := ComboTrialSession.new()
	check(session.load_catalog().is_empty(), "Trial catalog does not match the current kit")
	check(session.catalog.trials.size() == 10, "Missing certified trial")
	for item in session.catalog.trials:
		for side in [false, true]:
			session.select(item, side)
			session.begin(false)
			countdown(session)
			play(session, session.inputs)
			check(session.state == "success", "%s side %s: %s" % [item.id, side, session.failure])
			check(session.damage == int(item.damage) and session.hits == int(item.hits), "Trial damage/hits drifted: " + str(item.id))
			check(session.matched_notes == session.notes.size() and session.total_error == 0, "Wrong input tick chart: " + str(item.id))
			check(session.start_index == item.starts.size(), "Clear missed a required move: " + str(item.id))
		# Demo runs the same validator, but is explicitly marked as a demo.
		session.select(item)
		session.begin(true)
		countdown(session)
		play(session, session.inputs.map(func(_raw): return 0))
		check(session.state == "success" and session.demonstration, "Demo diverged: " + str(item.id))
	var tapper: Dictionary = session.catalog.trials.filter(func(t): return t.id == "tapper-midscreen")[0]
	session.select(tapper)
	session.begin(false)
	countdown(session)
	play(session, session.inputs.map(func(_raw): return 0))
	check(session.state == "failed" and session.hits == 0, "Doing nothing can clear a trial")
	session.begin(false)
	countdown(session)
	session.advance(64 | 4)
	check(session.notes[0].judge == "ON TIME" and session.state == "failed", "Perfect button timing with the wrong direction passed")
	check(session.actual_notes[-1].judge == "WRONG INPUT" and session.actual_notes[-1].direction_error, "Wrong direction received correct-input feedback")
	check(not session.actual_notes[-1].accepted and session.notes[0].result == "WRONG INPUT", "Wrong-direction note was painted as accepted")
	session.begin(false)
	countdown(session)
	session.advance(16)
	check(session.actual_notes[-1].judge == "WRONG INPUT" and session.actual_notes[-1].lane == 0 and session.actual_notes[-1].expected_lane == 2, "Wrong-button feedback lost the pressed/expected lanes")
	check(not session.actual_notes[-1].direction_error, "Wrong button incorrectly blamed the direction")
	session.begin(false)
	countdown(session)
	for _tick in 39: session.advance(0)
	session.advance(16)
	check(session.actual_notes[-1].expected_lane == 2, "Wrong input pointed at a later chart note instead of the required move")
	session.begin(false)
	countdown(session)
	session.advance(64)
	check(session.actual_notes[-1].accepted and session.actual_notes[-1].judge == "ON TIME", "Correct native move was not confirmed on the track")
	session.begin(false)
	countdown(session)
	for _tick in 3: session.advance(0)
	session.advance(64)
	check(session.actual_notes[-1].judge == "LATE" and session.actual_notes[-1].delta == 3 and session.actual_notes[-1].accepted, "Late input was not measured at the actual press tick")
	session.begin(false)
	countdown(session)
	for _tick in 12: session.advance(0)
	check(session.actual_notes[-1].judge == "MISSED" and session.actual_notes[-1].lane == 2, "Unpressed note has no track indicator")
	session.advance(64)
	check(session.actual_notes[-1].judge == "LATE" and session.actual_notes[-1].delta == 12 and session.actual_notes[-1].note == 0 and session.feedback == "LATE 12f", "Late repeated-button input was incorrectly attached to the next note")
	check(session.notes[1].judge.is_empty(), "Late opener consumed the next S note")
	session.begin(false)
	check(session.actual_notes.is_empty() and session.notes[0].result.is_empty(), "Retry retained track feedback")
	countdown(session, 64)
	for _tick in 20: session.advance(64)
	check(session.model.state().players[0].move == -1 and session.start_index == 0, "A pre-countdown held button leaked into gameplay")
	session.begin(false)
	countdown(session)
	var delayed := session.inputs.duplicate()
	delayed[17] = 0
	delayed.insert(38, 64)
	play(session, delayed)
	check(session.state == "failed", "A dropped/changed combo passed")
	# A legal one-frame-late link still clears, with a separate timing grade.
	session.begin(false)
	countdown(session)
	var shifted: Array = [0]
	shifted.append_array(session.inputs)
	play(session, shifted)
	check(session.state == "success" and session.total_error > 0, "Valid offset timing was rejected instead of graded")
	var fillet: Dictionary = session.catalog.trials.filter(func(t): return t.id == "fillet-midscreen")[0]
	session.select(fillet)
	session.begin(false)
	countdown(session)
	for tick in 15:
		session.advance(64 if tick == 0 else 130 if tick == 12 else 0)
	check(session.actual_notes[-1].judge == "EARLY" and session.actual_notes[-1].delta == -3, "Early buffered input has the wrong signed error")
	check(not session.actual_notes[-1].accepted, "Buffered input claimed a move before it started")
	session.advance(0)
	check(session.actual_notes[-1].accepted and session.actual_notes[-1].judge == "EARLY", "Buffer acceptance lost the early timing feedback")
	session.select(fillet)
	session.begin(false)
	countdown(session)
	var motion_buffered := session.inputs.duplicate()
	# A human can begin a motion before the recorded direction ticks, with the
	# button still landing at the line; the chart must not demand 1f directions.
	for i in range(39, 43): motion_buffered[i] = 4
	for i in range(43, 46): motion_buffered[i] = 6
	play(session, motion_buffered)
	check(session.state == "success", "An earlier, slower quarter-circle motion was rejected")
	var smoke: Dictionary = session.catalog.trials.filter(func(t): return t.id == "smoke-midscreen")[0]
	session.select(smoke)
	check(int(session.notes[0].end) - int(session.notes[0].frame) >= 20, "Charged Drive lost its hold trail")
	session.begin(false)
	countdown(session)
	var released := session.inputs.duplicate()
	for i in range(1, 27): released[i] = 0
	play(session, released)
	check(session.state == "failed", "Early release of charged Drive passed")
	check(session.actual_notes.any(func(event): return event.judge == "RELEASED EARLY" and event.delta == -27), "Early charge release did not mark the hold trail")
	var anvil: Dictionary = session.catalog.trials.filter(func(t): return t.id == "anvil-midscreen")[0]
	session.select(anvil)
	check(session.directions[0].value == 4 and session.directions[0].end >= 30, "Back-charge cue missing")
	session.select(anvil, true)
	check(session.directions[0].value == 6, "Facing-left charge guidance was not mirrored")
	# Integration: opening trials isolates saved edits/round state and halts the
	# parent game. Exercise real menu callbacks, focus, retry and slow clock.
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.fighter_music.enabled = false
	await process_frame
	game.motion.instant = true
	game.finish_menu_motion()
	game.set_physics_process(false)
	game.model.step(64, 0)
	var snapshot: PackedByteArray = game.model.core.snapshot()
	var config: PackedInt32Array = game.model.config.duplicate()
	game.menu_action("combo_trials")
	await process_frame
	var window: ComboTrialsWindow = game.combo_trials
	window.set_physics_process(false)
	window.combat_audio.enabled = false
	check(window.visible and game.has_open_dialog(), "Main menu did not open modal trials")
	check(window.controls == game.fighter_inputs, "Trials ignored player remaps/controller assignment")
	window.choose_fighter(3)
	window.begin(false)
	window.focused = true
	while window.session.clock < 0: window._physics_process(1.0 / 60)
	var last := 0
	for raw_value in window.session.inputs:
		for bit in 9:
			if bool(last & (1 << bit)) == bool(raw_value & (1 << bit)): continue
			var event := InputEventKey.new()
			event.physical_keycode = window.controls.profiles[0].keys[bit]
			event.keycode = event.physical_keycode
			event.pressed = bool(raw_value & (1 << bit))
			window._input(event)
		last = raw_value
		window._physics_process(1.0 / 60)
	check(window.session.state == "success", "Live keyboard input did not clear the native trial")
	check(window.gui_get_focus_owner() == window.try_button, "Controller focus did not return to Retry")
	window.choose_fighter(5)
	window.speed = 0.5
	window.begin(true)
	window.focused = true
	for _tick in 240: window._physics_process(1.0 / 60)
	check(window.session.clock == 0 and window.session.model.frame() == 0, "Half speed does not share the input/simulation clock")
	window.set_paused(true)
	for _tick in 30: window._physics_process(1.0 / 60)
	check(window.session.clock == 0, "Paused chart advanced")
	window.set_paused(false)
	window._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(window.paused and not window.focused, "Focus loss did not pause trials")
	window._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	check(window.paused and window.release_required, "Focus return resumed with stale input")
	window.close()
	await process_frame
	check(game.model.core.snapshot() == snapshot and game.model.config == config, "Trials modified the original match or custom moves")
	check(game.input_release_required, "Closing trials did not gate held gameplay input")
	game.queue_free()
	await process_frame
	# The audio mixer retires its last decoder on a separate thread.
	await create_timer(0.1).timeout
	print("Native rhythm trials: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
