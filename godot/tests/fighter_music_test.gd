extends SceneTree

var failures := 0
var checks := 0

func _initialize() -> void: call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("Fighter music: " + message)

func current_voice(music: FighterMusic) -> AudioStreamPlayer:
	return music.voices[music.characters.find(music.current_character)]

func run() -> void:
	var music := FighterMusic.new()
	root.add_child(music)
	music.set_process(false)
	var titles := ["Better Than Me", "Space Between the Names", "The Air Is Mine", "Hit Me", "No Safe Harbour", "Thumb on the Scale"]
	check(music.catalog.tracks.size() == 6, "A fighter theme is missing")
	for character in 6:
		var record := music.track(character)
		check(record.character == character and record.fighter == CombatModel.CHARACTERS[character] and record.title == titles[character], "Wrong song assignment for " + CombatModel.CHARACTERS[character])
		var stream := music.stream_for(character)
		check(stream != null and stream.loop and stream.loop_offset == 0.0, "Song does not loop")
		check(absf(stream.get_length() - float(record.duration)) < 0.15, "Song was truncated during import")

	music.update_context(true, [5, 4], false, true)
	music._process(1.0)
	check(music.current_character == 5, "Default theme does not follow P1")
	var voice := current_voice(music)
	voice.seek(10.0)
	await create_timer(0.15).timeout
	var before := voice.get_playback_position()
	music.update_context(true, [5, 4], true, true)
	music._process(1.0)
	await create_timer(0.15).timeout
	check(current_voice(music) == voice and voice.get_playback_position() > before, "Pause stopped or restarted the song")
	check(is_equal_approx(music.duck, 0.5), "Pause did not soften music")
	music.update_context(true, [5, 4], false, true)
	music._process(1.0)
	check(is_equal_approx(music.duck, 1.0), "Resume did not restore music level")

	# Verify decoded music reaches the mixer, not just the player's playing flag.
	var capture := AudioEffectCapture.new()
	var bus := AudioServer.get_bus_index("Music")
	AudioServer.add_bus_effect(bus, capture)
	await create_timer(0.2).timeout
	var samples := capture.get_buffer(capture.get_frames_available())
	var peak := 0.0
	for sample in samples: peak = maxf(peak, maxf(absf(sample.x), absf(sample.y)))
	check(peak > 0.0001, "Playing theme produced no audio samples")
	AudioServer.remove_bus_effect(bus, AudioServer.get_bus_effect_count(bus) - 1)

	# Full-song looping should wrap without leaving a stopped voice.
	voice.seek(voice.stream.get_length() - 0.06)
	await create_timer(0.3).timeout
	check(voice.playing and voice.get_playback_position() < 1.0, "End of song did not loop")
	for mode in ["disabled", "zero volume", "unfocused"]:
		voice.seek(15.0)
		if mode == "disabled": music.set_enabled(false)
		elif mode == "zero volume": music.set_volume(0.0)
		else: music.update_context(true, [5, 4], false, false)
		await create_timer(0.08).timeout
		before = voice.get_playback_position()
		await create_timer(0.1).timeout
		check(voice.stream_paused and absf(voice.get_playback_position() - before) < 0.06, mode + " lost the playback position")
		music.set_enabled(true)
		music.set_volume(0.55)
		music.update_context(true, [5, 4], false, true)
		await create_timer(0.15).timeout
		check(not voice.stream_paused and voice.get_playback_position() > before, mode + " failed to resume")

	music.set_source(1)
	music._process(0.2)
	check(music.current_character == 4 and music.voices.all(func(v: AudioStreamPlayer) -> bool: return v.playing), "P2 theme did not crossfade")
	music.set_source(0)
	check(current_voice(music) == voice, "Interrupted crossfade restarted the old song")
	for choice in [2, 6, 3, 4, 5, 7]:
		music.set_source(choice)
		music._process(0.1)
		check(music.current_character == choice - 2, "Fixed fighter selection failed")
	music._process(1.0)
	check(music.voices.filter(func(v: AudioStreamPlayer) -> bool: return v.playing).size() == 1, "Rapid theme changes left overlapping songs")
	music.update_context(false, [3, 2], false, true)
	music._process(1.0)
	check(music.voices.all(func(v: AudioStreamPlayer) -> bool: return not v.playing), "Leaving match did not stop music")
	music.preview_theme()
	music._process(1.0)
	check(music.current_character == 5 and current_voice(music).playing, "Menu audition did not start")
	music.end_preview()
	music._process(1.0)
	check(music.current_character == -1 and music.voices.all(func(v: AudioStreamPlayer) -> bool: return not v.playing), "Menu audition did not stop")

	var prefs := ConfigFile.new()
	prefs.set_value("audio", "volume", 0.23)
	music.set_enabled(false)
	music.set_volume(0.37)
	music.set_source(3)
	music.write_preferences(prefs)
	var restored := FighterMusic.new()
	restored.read_preferences(prefs)
	check(not restored.enabled and is_equal_approx(restored.volume, 0.37) and restored.source == 3, "Music preferences lost a setting")
	check(is_equal_approx(float(prefs.get_value("audio", "volume")), 0.23), "Music overwrote effects preferences")
	restored.free()
	music.queue_free()
	await process_frame
	await check_native_flow()
	print("Fighter themes: %d failures across %d checks" % [failures, checks])
	call_deferred("quit", 1 if failures else 0)

func check_native_flow() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	game.motion.instant = true
	game.finish_menu_motion()
	game.choose_activity("training")
	game.confirm_selection()
	await game.wait_for_match_entry()
	await process_frame
	var music: FighterMusic = game.fighter_music
	check(music.match_active and music.current_character == 5, "Match entry did not start P1's theme")
	var voice := current_voice(music)
	voice.seek(20.0)
	game.reset_round()
	await process_frame
	check(current_voice(music) == voice and voice.get_playback_position() >= 19.9, "Training reset restarted music")
	check(game.preview_super_freeze(0), "Could not open super-freeze fixture")
	var frozen: int = game.model.state_hash()
	for tick in 8:
		game.tick_super_freeze_preview()
		await process_frame
	check(game.model.state_hash() == frozen and current_voice(music) == voice and voice.get_playback_position() >= 19.9, "Super freeze interrupted music or changed combat")
	game.open_pause()
	await process_frame
	check(music.match_active and music.dimmed and current_voice(music) == voice, "Pause lost the match theme")
	game.show_sound_settings()
	await process_frame
	var dialog: Window
	for child in game.get_children():
		if child is Window and child.has_meta("music_settings"): dialog = child
	check(dialog != null, "Sound & music dialog is missing")
	var theme: OptionButton = dialog.find_child("MusicTheme", true, false)
	check(theme.item_count == 8, "Theme picker is incomplete")
	theme.select(4)
	theme.item_selected.emit(4)
	check(music.current_character == 2, "Theme picker did not select Smoke")
	var slider: HSlider = dialog.find_child("MusicVolume", true, false)
	slider.value = 30
	check(is_equal_approx(music.volume, 0.3), "Music volume slider is not connected")
	var toggle: CheckBox = dialog.find_child("MusicEnabled", true, false)
	toggle.button_pressed = false
	check(not music.enabled, "Music toggle is not connected")
	toggle.button_pressed = true
	var preview: Button = dialog.find_child("MusicPreview", true, false)
	preview.button_pressed = true
	check(music.previewing, "Music preview is not connected")
	for tick in 8: await process_frame
	check(Rect2i(Vector2i.ZERO, Vector2i(game.get_viewport_rect().size)).encloses(Rect2i(dialog.position, dialog.size)), "Sound dialog does not fit the viewport: %s at %s in %s" % [dialog.size, dialog.position, game.get_viewport_rect().size])
	check_dialog_controls(dialog, dialog)
	var args := OS.get_cmdline_user_args()
	if args.has("--output"):
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(args[args.find("--output") + 1]) == OK, "Could not save sound menu review")
	game.close_dialog(dialog)
	await process_frame
	check(not music.previewing and music.current_character == 2, "Closing audition lost the live match theme")
	game.menu_action("change_fighters")
	game.menus.selection.choose_fighter(0, 3)
	music.set_source(0)
	await process_frame
	check(music.current_character == 5, "Unconfirmed fighter change replaced the live theme")
	game.menu_back()
	game.next_scrum()
	await game.wait_for_match_entry()
	await process_frame
	check(music.match_active and music.current_character == 5, "Next Scrum lost the theme")
	game.show_screen("results")
	await process_frame
	check(music.match_active and music.current_character == 5, "Results stopped the theme")
	game.go_home()
	await process_frame
	music._process(1.0)
	check(music.current_character == -1, "Returning home retained match music")
	game.queue_free()
	await process_frame
	# Allow the audio mixer to release its last playback before the test exits.
	await create_timer(0.1).timeout

func check_dialog_controls(node: Node, dialog: Window) -> void:
	for child in node.get_children():
		if child is Window: continue
		if child is Control and child.is_visible_in_tree() and (child is BaseButton or child is Slider):
			check(Rect2(Vector2.ZERO, Vector2(dialog.size)).encloses(child.get_global_rect()), "Control outside sound dialog: " + str(child.name))
		check_dialog_controls(child, dialog)
