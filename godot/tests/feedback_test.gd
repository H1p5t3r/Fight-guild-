extends SceneTree

class Recorder extends CombatAudio:
	var heard: Array = []
	func play_cue(cue: Dictionary) -> void: heard.append(cue.duplicate(true))

var failures := 0
func check(value: bool, message: String) -> void:
	if not value: failures += 1; printerr(message)

func _initialize() -> void:
	call_deferred("run")

func fixture() -> CombatModel:
	var model := LegacyFixture.create()
	var data := model.data()
	data.characters[5].moves[0].reach = 40000
	data.characters[5].moves[0].hitstop = 8
	data.characters[5].moves[0].pushback = 0
	check(model.load_data(data).is_empty(), "Feedback fixture rejected")
	model.reset([5, 4])
	return model

func run() -> void:
	var model := fixture()
	var audio := Recorder.new()
	root.add_child(audio)
	var session := RollbackSession.new(model)
	for frame in 8:
		session.submit(0, frame, 16 if frame == 0 else 0)
		session.advance()
	check(model.cues.frames.values().any(func(f: Dictionary) -> bool: return f.events.any(func(c: Dictionary) -> bool: return c.kind == 1)), "Predicted contact was not recorded")
	audio.consume(model, -1, true)
	check(audio.heard.is_empty(), "Predicted hit played before confirmation")
	for frame in 8: session.submit(1, frame, 2)
	check(session.rollbacks > 0 and session.error.is_empty(), "Late guard did not replay")
	audio.consume(model, 7, true)
	check(not audio.heard.any(func(c: Dictionary) -> bool: return c.kind == 1), "Corrected false hit still played")
	check(audio.heard.any(func(c: Dictionary) -> bool: return c.kind == 2), "Confirmed guard sound missing")
	var count := audio.heard.size()
	for _tick in 10: audio.consume(model, 7, true)
	check(audio.heard.size() == count, "Repeated render/confirmation replayed sound")
	var live := model.cues.visible_at(model.frame())
	check(live.size() == 1 and live[0].kind == 2 and live[0].age == 0, "Rollback kept a false hit or hitstop aged the flash")
	for frame in range(8, 15):
		session.submit(0, frame, 0); session.submit(1, frame, 2); session.advance()
	audio.consume(model, 14, false)
	count = audio.heard.size()
	audio.consume(model, 14, true)
	check(audio.heard.size() == count, "Menu/pause resume replayed muted events")
	model.reset([5, 4])
	for frame in 6: model.step(16 if frame == 0 else 0, 0)
	audio.consume(model, model.frame() - 1, true)
	check(audio.heard.size() > count and audio.heard[-1].kind == 1, "New round lost its first contact")
	var sounds := {}
	for character in 6:
		for move in CombatModel.MOVE_IDS.size():
			for kind in range(1, 13):
				var sound := CombatAudio.sound_for({"character": character, "move": move, "kind": kind})
				sounds[sound] = true
	for sound in sounds:
		check(ResourceLoader.exists(CombatAudio.DIRECTORY + sound + ".wav"), "Missing sound: " + sound)
	var game = load("res://scripts/main.gd").new()
	root.add_child(game)
	await process_frame
	game.motion.instant = true
	game.show_sound_settings()
	await process_frame
	check(game.has_open_dialog(), "Sound menu did not open")
	check(game.menus.buttons.has("sound"), "Home sound button missing")
	game.queue_free()
	audio.queue_free()
	await process_frame
	print("Feedback history, confirmation, hitstop, sound assets and menu: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
