extends SceneTree

var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; printerr(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var model := LegacyFixture.create()
	model.reset()
	var lab := TrainingLab.new()
	lab.start_recording(model)
	for i in 300:
		var raw := Vector2i(RollbackSession.scripted_input(i, 0), RollbackSession.scripted_input(i, 1))
		var before := model.state()
		model.step(raw.x, raw.y)
		lab.observe(model, before, raw)
	var expected := model.state_hash()
	lab.stop()
	check(lab.recording.size() == 300 and lab.trace.size() == 180, "Recording or bounded timeline lost frames")
	model.reset([0, 1])
	check(lab.start_replay(model), "Replay rejected a valid recording")
	for i in 300:
		var before := model.state()
		var raw := lab.inputs(4095, 4095)
		check(raw == lab.recording[i], "Full replay accepted live inputs")
		model.step(raw.x, raw.y)
		lab.observe(model, before, raw)
	check(model.state_hash() == expected and lab.playback == 0 and lab.message.contains("identical"), "Replay did not reproduce state")
	check(lab.start_replay(model, true), "Dummy playback rejected")
	check(lab.inputs(64, 0) == Vector2i(64, lab.recording[0].y), "Dummy playback replaced P1 input")
	var edited := model.data()
	edited.characters[0].moves[0].damage += 1
	model.load_data(edited)
	check(not lab.start_replay(model), "Recording accepted changed move data")
	check(lab.playback == 0 and lab.message.contains("changed"), "Invalid recording did not explain mismatch")
	var app = load("res://scripts/main.gd").new()
	root.add_child(app)
	await process_frame
	check(not app.has_open_dialog(), "Frame lab opened on startup and intercepted gameplay inputs")
	app.activity = "training"
	app.screen = "play"
	app.configure_activity()
	app.paused = true
	app.lab = lab
	app.timeline.lab = lab
	app.open_frame_lab()
	await process_frame
	await process_frame
	check(app.paused and app.lab_window.visible, "Frame lab did not pause and open")
	app.lab_window.hide()
	app.record_exchange()
	check(app.lab.recording_now and not app.paused, "Record control did not start capture")
	app.simulate_local()
	app.lab.stop()
	app.replay_exchange(false)
	check(app.lab.playback == 1, "Replay control did not restore capture")
	app.simulate_local()
	check(app.lab.message.contains("identical"), "UI replay changed the combat result")
	app.queue_free()
	await process_frame
	print("Training recording, timeline and replay: ", failures, " failures")
	quit(int(failures != 0))
