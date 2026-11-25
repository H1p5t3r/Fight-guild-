extends SceneTree

# Reproducible native captures and the guild/state/viewport contract behind the new style.
# --output DIR saves stills; --tour records real UI motion with Godot's Movie Maker.
var game: Control
var output := ""
var failures := 0
var checks := 0

func _initialize() -> void: call_deferred("run")

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("Ink menu: " + description)

func capture(file: String) -> void:
	for tick in 8: await process_frame
	var rect: Rect2 = game.get_viewport_rect().grow(1)
	for id in game.menus.buttons:
		var button: Button = game.menus.buttons[id]
		if not button.is_visible_in_tree() or not game.menus.active: continue
		# Utilities fade out on inner pages, but remain in the layout intentionally.
		if button.get_parent() == game.menus.home_utilities and game.screen != "home": continue
		check(rect.encloses(button.get_global_rect()), file + ": action outside viewport: " + id)
	if output.is_empty(): return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output.path_join(file + ".png")) == OK, "Could not save " + file)

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.has("--output"): output = args[args.find("--output") + 1]
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	game.load_workshop_draft()
	if args.has("--tour"):
		await tour()
		print("Native ink menu tour complete")
		quit()
		return
	game.motion.instant = true
	game.finish_menu_motion()
	game.go_home()
	var initial_hash: int = game.model.state_hash()
	for index in CombatModel.CHARACTERS.size():
		game.menus.set_featured(index)
		check(game.menus.palette.accent == FighterSelectPortrait.COLORS[index], "Home uses wrong guild palette")
		check(game.menus.home_poster.character == index, "Home shows wrong fighter")
		await capture("guild-" + CombatModel.CHARACTERS[index].to_lower())
	check(game.model.state_hash() == initial_hash, "Changing featured guild changed combat")
	game.menus.set_featured(5)
	await capture("01-home")
	game.menu_action("matches")
	await capture("02-versus")
	game.menu_action("local")
	await capture("03-sides")
	game.confirm_sides()
	game.menus.selection.choose_fighter(0, 5)
	game.menus.selection.choose_fighter(1, 4)
	game.menus.selection.set_active_player(1)
	check(game.menus.palette.character == 4, "P2 selection did not change dominant guild")
	check(game.menus.backdrop.dominant_player == 1 and game.menus.backdrop.contest < 0.0, "P2 guild did not claim more of the shared field")
	game.menus.selection.set_active_player(0)
	check(game.menus.palette.character == 5, "P1 selection did not restore its guild")
	check(game.menus.backdrop.contest > 0.0, "P1 guild did not reclaim the shared field")
	check(not game.menus.selection.portraits[0].clip_contents and not game.menus.selection.portraits[1].clip_contents, "Fighters are clipped into portrait cards")
	await capture("04-fighters")
	game.menus.selection.choose_fighter(1, 5)
	await capture("12-mirror-select")
	game.menus.selection.choose_fighter(1, 4)
	game.confirm_selection()
	await game.wait_for_match_entry()
	await capture("05-combat")
	game.open_pause()
	check(game.pause_tableau.captured_characters == [5, 4], "Pause lost actual matchup")
	check(game.pause_tableau.copies.size() >= 2, "Pause did not preserve the actual fighters")
	for copy in game.pause_tableau.copies:
		check(copy.get_global_transform_with_canvas().is_equal_approx(copy.get_meta("source_transform")), "Pause changed a fighter's displayed transform")
	await capture("06-pause")
	await check_pause_pixels()
	check_pause_composition()
	var pair_focus: Vector2 = game.menus.pause_commands.focus_local
	check((pair_focus + game.menus.pause_commands.get_global_position()).is_equal_approx(game.pause_tableau.focal_point * game.pause_tableau.size), "Radial commands did not anchor to the combined fighter silhouette")
	game.menu_action("change_fighters")
	game.menus.selection.choose_fighter(0, 2)
	game.menu_back()
	check(game.menus.palette.character == 5 and game.characters[0] == 5, "Canceling selection changed the paused matchup palette")
	check(game.menus.pause_commands.focus_local.is_equal_approx(pair_focus), "Returning from selection moved the pair-centered commands")
	var state: Dictionary = game.model.state().duplicate(true)
	state.winner = 1
	game.menus.configure_results(state, false, "FINAL DOWN", [1, 2])
	game.show_screen("results")
	check(game.menus.result_poster.character == 4 and game.menus.palette.character == 4, "Winner's guild missing from results")
	await capture("07-results")
	game.go_home()
	game.choose_activity("online")
	game.menus.selection.choose_fighter(0, 2)
	game.confirm_selection()
	check(game.menus.palette.character == 2 and game.menus.online_poster.character == 2, "Online lost local fighter's guild")
	await capture("08-online")
	game.go_home()
	game.show_controls()
	await capture("09-controls")
	var dialog: Window
	for child in game.get_children():
		if child.has_method("begin_binding"): dialog = child
	if dialog != null:
		check(dialog.theme.get_stylebox("embedded_border", "Window").border_color == game.menus.palette.accent, "Controls ignored current guild")
		game.close_dialog(dialog)
	await process_frame
	game.show_sound_settings()
	await capture("10-sound")
	for child in game.get_children():
		if child is Window and child.visible: game.close_dialog(child)
	await process_frame
	game.motion.instant = false
	game.motion.reduced = true
	game.menu_action("matches")
	check(game.menus.camera == game.menus.LOCATIONS.matches, "Reduced motion still travels the shared camera")
	await game.wait_for_menu_motion()
	await capture("11-reduced")
	game.go_home()
	await game.wait_for_menu_motion()
	game.motion.reduced = false
	game.choose_activity("training")
	await game.wait_for_menu_motion()
	game.menus.selection.set_active_player(1)
	check(game.menus.backdrop.is_animating(), "Guild dominance did not animate")
	game.menus.selection.set_active_player(0)
	await game.wait_for_menu_motion()
	check(game.menus.backdrop.contest > 0.0 and game.menus.backdrop.surge == 0.0, "Interrupted guild surge finished on the wrong player")
	game.go_home()
	await game.wait_for_menu_motion()
	game.menu_action("matches")
	check(game.menus.camera_tween.is_running(), "Full motion did not start shared-space travel")
	game.menus.camera_tween.pause()
	game.menus.camera_tween.custom_step(0.4)
	var uninterrupted: Vector2 = game.menus.camera
	game.menu_back()
	check(game.menus.camera == uninterrupted, "Rapid navigation snapped the persistent camera")
	await game.wait_for_menu_motion()
	check(game.screen == "home" and game.menus.camera == Vector2.ZERO, "Interrupted camera finished at the wrong location")
	game.menu_action("matches")
	await game.wait_for_menu_motion()
	game.menu_back()
	check(game.menus.camera == game.menus.LOCATIONS.matches, "Back navigation jumped before retracing its path")
	await game.wait_for_menu_motion()
	game.motion.instant = true
	for pair in [[1, 2], [3, 0]]:
		game.model.reset(pair)
		game.show_screen("play")
		for tick in 8: await process_frame
		game.open_pause()
		await capture("pause-%d-%d" % pair)
	game.model.reset([5, 4])
	game.show_screen("play")
	game.model.core.preview_begin(0, 3)
	for tick in int(game.model.move(5, 3).startup): game.model.step(0, 0)
	for tick in 8: await process_frame
	game.open_pause()
	await capture("13-pause-active")
	print("Native ink menus: ", failures, " failures / ", checks, " checks")
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout # Retire the final theme decoder before exit.
	quit(1 if failures else 0)

func hold(seconds: float) -> void:
	await create_timer(seconds).timeout

func check_pause_composition() -> void:
	var wheel: PauseCommands = game.menus.pause_commands
	var original := wheel.focal_point
	var rect := game.get_viewport_rect().grow(1)
	var hash_before: int = game.model.state_hash()
	for focus in [Vector2(0.2, 0.32), Vector2(0.8, 0.75)]:
		wheel.focal_point = focus
		for button in wheel.buttons.values():
			for corner in [Vector2.ZERO, Vector2(button.size.x, 0), button.size, Vector2(0, button.size.y)]:
				check(rect.has_point(button.get_global_transform_with_canvas() * corner), "Radial command leaves viewport near a corner")
	wheel.focal_point = original
	game.motion.instant = false
	wheel.enter()
	for i in wheel.ORDER.size():
		var button: Button = wheel.buttons[wheel.ORDER[i]]
		var center := button.get_global_transform_with_canvas() * (button.size * 0.5)
		check(not rect.has_point(center), "Radial command did not enter from beyond the screen edge")
	wheel.finish()
	game.motion.reduced = true
	wheel.enter()
	for button in wheel.buttons.values():
		check(rect.has_point(button.get_global_transform_with_canvas() * (button.size * 0.5)), "Reduced Motion moved a command outside its final location")
	wheel.finish()
	game.motion.reduced = false
	game.motion.instant = true
	check(game.model.state_hash() == hash_before, "Pause layout or motion changed gameplay state")

func check_pause_pixels() -> void:
	if DisplayServer.get_name() == "headless": return
	# Material probes are independent of the radial command strips crossing a blade.
	game.menus.visible = false
	await process_frame
	await RenderingServer.frame_post_draw
	var rendered := root.get_texture().get_image()
	var scale_value := Vector2(rendered.get_size()) / game.get_viewport_rect().size
	var source: Sprite2D = game.arena.sprites[0]
	for probe in [[Vector2(810, 310), FighterSelectPortrait.COLORS[5], "hair"], [Vector2(735, 520), FighterSelectPortrait.COLORS[5], "pale shirt"], [Vector2(655, 785), Color.WHITE, "knife"]]:
		var point: Vector2 = source.get_global_transform_with_canvas() * (source.offset + probe[0]) * scale_value
		var sampled := rendered.get_pixelv(Vector2i(point))
		var expected: Color = probe[1]
		check(Vector3(sampled.r, sampled.g, sampled.b).distance_to(Vector3(expected.r, expected.g, expected.b)) < 0.12, "Pause material wrong for " + probe[2] + ": " + str(sampled))
	game.menus.visible = true
	await process_frame

func tour() -> void:
	game.motion.reduced = false
	game.go_home()
	await game.wait_for_menu_motion()
	await hold(0.7)
	for index in [4, 2, 1, 3, 0, 5]:
		game.menus.set_featured(index)
		await hold(1.1)
	game.menus.buttons.training.grab_focus()
	await hold(0.6)
	game.menus.buttons.matches.grab_focus()
	await hold(0.6)
	game.menu_action("matches")
	await game.wait_for_menu_motion()
	await hold(0.7)
	game.menu_back()
	await game.wait_for_menu_motion()
	await hold(0.3)
	game.menu_action("matches")
	await game.wait_for_menu_motion()
	game.menu_action("local")
	await game.wait_for_menu_motion()
	await hold(0.8)
	game.confirm_sides()
	await game.wait_for_menu_motion()
	game.menus.selection.choose_fighter(0, 2)
	await game.wait_for_menu_motion()
	await hold(0.8)
	game.menus.selection.choose_fighter(0, 5)
	game.menus.selection.choose_fighter(1, 4)
	await game.wait_for_menu_motion()
	await hold(0.8)
	game.menus.selection.set_active_player(1)
	await game.wait_for_menu_motion()
	await hold(0.8)
	game.menus.selection.set_active_player(0)
	await game.wait_for_menu_motion()
	await hold(0.8)
	# Enter a fixture match instantly; the existing loading/intros aren't part of this UI reel.
	game.motion.instant = true
	game.confirm_selection()
	await game.wait_for_match_entry()
	game.finish_menu_motion()
	game.motion.instant = false
	await hold(0.7)
	game.open_pause()
	await game.wait_for_menu_motion()
	await hold(0.7)
	game.menus.buttons.restart.grab_focus()
	await hold(0.5)
	game.menus.buttons.resume.grab_focus()
	await hold(0.5)
	game.menu_action("resume")
	await game.wait_for_menu_motion()
	await hold(0.7)
	# Freeze at an actual first-active attack pose, then continue that same move.
	game.model.core.preview_begin(0, 3)
	for tick in int(game.model.move(5, 3).startup):
		game.model.step(0, 0)
		await process_frame
	await hold(0.12)
	game.open_pause()
	await game.wait_for_menu_motion()
	await hold(1.5)
	game.menu_action("resume")
	await game.wait_for_menu_motion()
	for tick in 40:
		game.model.step(0, 0)
		await process_frame
	var state: Dictionary = game.model.state().duplicate(true)
	state.winner = 1
	game.menus.configure_results(state, false, "FINAL DOWN", [1, 2])
	game.show_screen("results")
	await game.wait_for_menu_motion()
	await hold(1.4)
