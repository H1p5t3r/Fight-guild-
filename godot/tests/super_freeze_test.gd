extends SceneTree

var game: Control
var failures := 0
var checks := 0

func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("Super freeze: " + message)

func prepare(pair: Array = [5, 4]) -> void:
	game.cancel_super_freeze_preview()
	game.characters = pair
	game.activity = "training"
	game.configure_activity()
	game.show_screen("play")
	game.reset_round()
	game.dummy.select(0)
	game.input_release_required = false
	game.application_focused = true
	game.arena.refresh(game.model, game.model.state(), false, false)

func verify_freeze(player: int, label: String, ticks: int = 54) -> void:
	var snapshot: PackedByteArray = game.model.core.snapshot()
	var frame: int = game.model.frame()
	var fighter: Dictionary = game.model.state().players[player]
	check(game.preview_super_freeze(player, ticks), label + ": preview did not start")
	check(game.super_freeze.character == fighter.character and game.super_freeze.facing == fighter.facing, label + ": wrong portrait or facing")
	check(not game.preview_super_freeze(1 - player), label + ": repeat trigger restarted the freeze")
	game.held[KEY_J] = true
	check(game.read_input(0) == 0 and game.read_input(1) == 0, label + ": live input escaped the preview gate")
	game.advance_one()
	check(game.model.core.snapshot() == snapshot, label + ": frame-step advanced combat during the freeze")
	for tick in ticks:
		game._physics_process(1.0 / 60)
		check(game.model.core.snapshot() == snapshot, label + ": simulation changed on freeze tick " + str(tick))
	check(game.super_preview_player == -1 and not game.super_freeze.visible, label + ": freeze did not finish on time")
	check(game.held.is_empty() and game.input_release_required, label + ": inputs were not released on completion")
	game._physics_process(1.0 / 60)
	check(game.model.frame() == frame + (0 if game.paused else 1), label + ": wrong simulation resume boundary")

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	game.load_workshop_draft()
	game.motion.instant = true
	game.finish_menu_motion()
	var config: PackedInt32Array = game.model.config.duplicate()
	for character in 6:
		prepare([character, (character + 1) % 6])
		verify_freeze(0, "P1 " + str(character))
		prepare([(character + 1) % 6, character])
		verify_freeze(1, "P2 " + str(character))
	prepare()
	game.model.core.preview_begin(0, 3)
	for tick in 4: game.model.step(0, 0)
	verify_freeze(0, "attack startup")
	prepare([2, 5])
	# Keep an actual stationary Smoke pillar alive under the freeze.
	game.model.core.preview_place(1, 85000, 0, 0)
	game.model.core.preview_begin(0, 14)
	for tick in int(game.model.move(2, 14).startup) + 2: game.model.step(0, 0)
	check(not game.model.state().projectiles.is_empty(), "Projectile freeze fixture has no projectile")
	verify_freeze(0, "projectile lifetime")
	prepare()
	game.model.core.preview_place(1, 65000, 9000, 0)
	game.model.core.preview_status(1, 0, 30)
	verify_freeze(1, "airborne recovery")
	prepare()
	game.paused = true
	verify_freeze(0, "manual pause survives", 24)
	check(game.paused, "Preview cleared the user's manual pause")
	prepare()
	game.preview_super_freeze(0)
	game.open_pause()
	check(game.screen == "pause" and game.super_preview_player == -1 and not game.super_freeze.visible, "Pause did not clear the cut-in")
	check(not game.preview_super_freeze(0), "Preview ran in a menu")
	prepare()
	game.preview_super_freeze(0)
	game.reset_round()
	check(game.super_preview_player == -1 and not game.super_freeze.visible, "Round reset left a stale cut-in")
	game.preview_super_freeze(0)
	game._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.super_preview_player == -1 and game.screen == "pause", "Focus loss left a live preview")
	prepare()
	game.activity = "local"
	check(not game.preview_super_freeze(0), "Local versus exposed a fake super")
	game.activity = "training"
	game.connection.active = true
	check(not game.preview_super_freeze(0), "Online allowed a client-only freeze")
	game.connection.active = false
	check(not game.preview_super_freeze(-1) and not game.preview_super_freeze(2), "Invalid player accepted")
	game.motion.reduced = true
	check(game.preview_super_freeze(0, 0), "Minimum-duration preview failed")
	check(game.super_preview_duration == 24 and game.super_freeze.reduced_motion, "Reduced motion or duration limits ignored")
	game.super_freeze.present(5, 1, 20, 54)
	var original: Dictionary = game.super_freeze.composition()
	check(game.super_freeze.tear_material.get_shader_parameter("reduced_motion"), "Reduced motion did not disable rip travel")
	var fixed_face: Vector4 = game.super_freeze.tear_material.get_shader_parameter("face_box")
	game.super_freeze.present(5, 1, 40, 54)
	check(game.super_freeze.tear_material.get_shader_parameter("face_box") == fixed_face, "Closing the screen moved or stretched the face")
	game.super_freeze.present(5, 1, 20, 54)
	check(game.super_freeze.composition() == original, "Seeking back changed the same freeze frame")
	game.super_freeze.present(5, 1, 0, 54)
	check(game.super_freeze.composition().opening == 0.0, "First frame did not start with an intact screen")
	game.super_freeze.present(5, 1, 53, 54)
	check(is_equal_approx(game.super_freeze.composition().closing, 1.0), "Screen did not finish knitting before combat resumed")
	check(game.super_freeze.composition().rip_front < -0.10, "Reverse closure left part of the strip missing")
	var prior := -1.0
	for tick in range(14):
		game.super_freeze.present(5, 1, tick, 54)
		var front: float = game.super_freeze.composition().rip_front
		check(front >= prior, "Opening rip changed direction")
		prior = front
	game.super_freeze.present(5, 1, 32, 54)
	prior = game.super_freeze.composition().rip_front
	for tick in range(33, 54):
		game.super_freeze.present(5, 1, tick, 54)
		var front: float = game.super_freeze.composition().rip_front
		check(front <= prior, "Closure did not travel opposite to the opening rip")
		prior = front
	game.super_freeze.present(5, 1, 54, 54)
	check(not game.super_freeze.visible, "Past-end presentation remained on screen")
	game.cancel_super_freeze_preview()
	game.motion.reduced = false
	root.size = Vector2i(1280, 720)
	for activity in ["training", "development"]:
		prepare()
		game.activity = activity
		game.configure_activity()
		for tick in 3: await process_frame
		var viewport: Rect2 = game.get_viewport_rect().grow(1)
		var menu: MenuButton
		for child in game.practice.get_children():
			check(viewport.encloses(child.get_global_rect()), activity + ": training control outside the viewport")
			if child is MenuButton: menu = child
		check(menu != null, activity + ": missing discoverable preview control")
		if menu:
			menu.get_popup().id_pressed.emit(1)
			check(game.super_preview_player == 1, activity + ": P2 menu action failed")
			game.cancel_super_freeze_preview()
	prepare()
	var shortcut := InputEventKey.new()
	shortcut.keycode = KEY_F8
	shortcut.pressed = true
	game._input(shortcut)
	check(game.super_preview_player == 0, "F8 did not select P1")
	game.cancel_super_freeze_preview()
	shortcut.shift_pressed = true
	game._input(shortcut)
	check(game.super_preview_player == 1, "Shift+F8 did not select P2")
	game.cancel_super_freeze_preview()
	check(game.model.config == config, "Presentation changed combat configuration")
	game.queue_free()
	await process_frame
	await process_frame
	# Headless frames can run faster than the audio mixer retires a decoder.
	await create_timer(0.1).timeout
	print("Super freeze presentation: %d failures / %d checks" % [failures, checks])
	quit(1 if failures else 0)
