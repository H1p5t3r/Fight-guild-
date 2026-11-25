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
	check(game.menus.pause_poster.character == 5 and game.menus.pause_poster.opponent == 4, "Pause lost actual matchup")
	await capture("06-pause")
	game.menu_action("change_fighters")
	game.menus.selection.choose_fighter(0, 2)
	game.menu_back()
	check(game.menus.palette.character == 5 and game.characters[0] == 5, "Canceling selection changed the paused matchup palette")
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
	check(not game.menus.wipe.is_animating() and game.menus.wipe.progress == 1.0, "Reduced motion still plays the ink wipe")
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
	check(game.menus.wipe.is_animating(), "Full motion did not start ink wipe")
	var uninterrupted: Tween = game.menus.wipe.tween
	game.menu_back()
	check(game.menus.wipe.tween == uninterrupted, "Rapid navigation restarted ink coverage")
	await game.wait_for_menu_motion()
	check(game.screen == "home" and game.menus.wipe.progress == 1.0, "Interrupted ink wipe left stale coverage")
	game.menu_action("matches")
	await game.wait_for_menu_motion()
	game.menu_back()
	check(game.menus.wipe.direction == -1.0, "Back navigation did not reverse the settled ink cut")
	await game.wait_for_menu_motion()
	print("Native ink menus: ", failures, " failures / ", checks, " checks")
	quit(1 if failures else 0)

func hold(seconds: float) -> void:
	await create_timer(seconds).timeout

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
	var state: Dictionary = game.model.state().duplicate(true)
	state.winner = 1
	game.menus.configure_results(state, false, "FINAL DOWN", [1, 2])
	game.show_screen("results")
	await game.wait_for_menu_motion()
	await hold(1.4)
