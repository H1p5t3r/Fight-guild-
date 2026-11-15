extends RefCounted

var failures := 0

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("Transition check: " + description)

func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func run(tree: SceneTree, game: Control) -> int:
	# Exercise real running tweens, including reversal before the first fade finishes.
	key(KEY_ENTER, true)
	key(KEY_ENTER, false)
	await tree.create_timer(0.06).timeout
	check(game.screen == "matches" and game.menus.buttons.local.has_focus(), "Incoming menu was not immediately navigable")
	check(game.menus.pages.matches.modulate.a > 0.0 and game.menus.pages.matches.modulate.a < 1.0, "Page transition did not animate")
	var visible_alpha: float = game.menus.pages.home.modulate.a
	key(KEY_ESCAPE, true)
	key(KEY_ESCAPE, false)
	check(is_equal_approx(game.menus.pages.home.modulate.a, visible_alpha), "Interrupted fade snapped instead of continuing from its current appearance")
	game.menu_action("training")
	game.menu_back()
	await game.wait_for_menu_motion()
	check(game.screen == "home" and game.menus.buttons.matches.has_focus(), "Rapid navigation left stale focus or the wrong page")
	for id in game.menus.pages:
		check(game.menus.pages[id].visible == (id == "home"), "Outgoing page survived transition: " + id)
	game.menu_action("training")
	await game.wait_for_menu_motion()
	key(KEY_J, true)
	game.confirm_selection()
	var frame: int = game.model.frame()
	game._physics_process(1.0 / 60.0)
	check(game.changing_layers() and game.model.frame() == frame and game.read_input(0) == 0, "Entering match advanced combat or accepted held input during fade")
	game.open_pause()
	await game.wait_for_menu_motion()
	check(game.screen == "pause" and game.model.frame() == frame and not game.play_root.visible, "Reversing match entry lost the paused round")
	game.menu_action("resume")
	await game.wait_for_menu_motion()
	check(game.input_release_required and game.read_input(0) == 0, "Held key leaked after transition completed")
	key(KEY_J, false)
	game._physics_process(1.0 / 60.0)
	check(game.model.state().players[0].move == -1, "Menu key became a delayed attack")
	game.go_home()
	await game.wait_for_menu_motion()
	game.menu_action("motion")
	check(game.motion.reduced and game.menus.buttons.motion.text == "Motion: Reduced", "Reduced motion setting did not apply")
	game.menu_action("matches")
	await tree.create_timer(0.02).timeout
	check(is_zero_approx(game.menus.pages.matches.position.x), "Reduced motion still slides pages")
	await game.wait_for_menu_motion()
	game.go_home()
	await game.wait_for_menu_motion()
	game.menu_action("motion")
	game.motion.instant = true
	game.finish_menu_motion()
	await tree.process_frame
	print("Godot menu transitions: ", failures, " failures; animated navigation, interruption, combat/input isolation, reduced motion")
	return failures
