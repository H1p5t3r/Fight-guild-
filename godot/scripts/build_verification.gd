extends RefCounted

var failures := 0
var game: Control
var tree: SceneTree

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("UI check: " + description)

func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func ticks(count: int) -> void:
	for _i in count: game.advance_one()
	game._process(0.0)

func release_hitstop() -> void:
	while game.model.state().hitstop > 0: ticks(1)

func verify_recovery_art() -> void:
	# Also runs in the exported PCK, where source PNGs cannot hide missing imports.
	for character in CombatModel.CHARACTERS.size():
		for phase in ["knockdown_back", "knockdown"]:
			for pose in 6:
				var texture := FighterArt.texture(character, phase, pose)
				check(texture.atlas != null and texture.get_width() > 0, "Missing packaged recovery sprite: %d/%s/%d" % [character, phase, pose])
	for clip in [13, 14]:
		game.show_sprite_review(clip)
		var count := 0
		for child in game.get_children():
			if not child is AcceptDialog or child == game.file_dialog: continue
			for control in child.find_children("*", "Control", true, false):
				if control is FighterPreview:
					check(control.phase == ("knockdown_back" if clip == 13 else "knockdown") and control.pose == count, "Recovery review selected the wrong sequence")
					count += 1
			child.queue_free()
		check(count == 2, "Recovery review must show the current and following poses")
		await tree.process_frame

func verify_foreground_draw() -> void:
	var state: Dictionary = game.model.state()
	for attacker in [-1, 0, 1, 0]:
		state.foregroundPlayer = attacker
		game.arena.refresh(game.model, state, true, false)
		var front: int = 0 if attacker == 0 else 1
		check(game.arena.sprites[front].get_index() > game.arena.weapons[1-front].get_index(), "Latest attacker is not in the foreground")
		for p in 2:
			check(game.arena.weapons[p].get_index() == game.arena.sprites[p].get_index() + 1, "Detached weapon left its owner's layer")
		check(game.arena.collision_layer.get_index() > game.arena.weapons[front].get_index() and game.arena.hud_layer.get_index() > game.arena.collision_layer.get_index(), "Foreground fighter covers the HUD or collision overlay")
	game.arena.refresh(game.model, game.model.state(), true, false)

func verify_smoke_idles() -> void:
	var previous: int = game.edit_character.selected
	game.edit_character.select(2)
	for clip in [4, 8, 5, 11, 15]:
		game.show_sprite_review(clip)
		var count := 0
		for child in game.get_children():
			if not child is AcceptDialog or child == game.file_dialog: continue
			for control in child.find_children("*", "Control", true, false):
				if control is FighterPreview:
					check(control.phase == {4: "idle", 8: "crouch_idle", 5: "walk", 11: "run", 15: "back_walk"}[clip] and control.pose == count, "Smoke review missed the approved A/H/G3/R4 clip")
					FighterArt.apply(control.sprite, 2, control.phase, count, 1, -1, 15)
					check(control.sprite.get_node("IdleSmoke0").show_behind_parent, "Smoke vapor covers the body")
					check(control.sprite.get_node("IdleSmoke0").texture.atlas != null, "Missing packaged rear-vapor texture")
					count += 1
			child.queue_free()
		check(count == 2, "Smoke review must show the current and following animation key")
		await tree.process_frame
	game.edit_character.select(previous)

func timing_fixture() -> Dictionary:
	var data: Dictionary = game.model.data().duplicate(true)
	for character in data.characters:
		for definition in character.moves:
			definition.damage = 0
			definition.pushback = 0
		for slot in [0, 4]:
			character.moves[slot].startup = 5
			character.moves[slot].reach = 50000
			character.moves[slot].hitstun = 24
	data.characters[1].moves[3].reach = 100 # Dummy Hs whiffs so its recovery can be punished.
	data.characters[1].moves[14].reversalEligible = 1 # Exercise timing with Hammer's current 236S mapping.
	return data

func verify_shark_movement() -> void:
	var previous: int = game.edit_character.selected
	game.edit_character.select(4)
	for clip in [4, 5, 15, 17, 11]:
		game.show_sprite_review(clip)
		var count := 0
		for child in game.get_children():
			if not child is AcceptDialog or child == game.file_dialog: continue
			for control in child.find_children("*", "Control", true, false):
				if control is FighterPreview:
					check(control.phase == {4: "idle", 5: "walk", 15: "back_walk", 17: "backdash", 11: "run"}[clip] and control.pose == count, "Shark review missed a selected movement")
					for pose in FighterArt.sheet(4, control.phase).frames.size():
						check(FighterArt.texture(4, control.phase, pose).atlas != null, "Missing packaged Shark movement texture")
					count += 1
			child.queue_free()
		check(count == 2, "Shark movement review needs consecutive keys")
		await tree.process_frame
	game.edit_character.select(previous)

func verify_smoke_attacks() -> void:
	for phase in ["attack_animation", "backdraft_fx", "sword_fx"]:
		for pose in FighterArt.sheet(2, phase).frames.size():
			check(FighterArt.texture(2, phase, pose).atlas != null, "Missing packaged Smoke attack sprite")
	for pose in range(20, 24):
		for phase in ["signature_windup", "signature_active"]:
			check(FighterArt.texture(2, phase, pose).atlas != null, "Missing packaged Smoke special")
	var previous: int = game.edit_character.selected
	game.edit_character.select(2)
	game.show_sprite_review(16)
	var count := 0
	for child in game.get_children():
		if not child is AcceptDialog or child == game.file_dialog: continue
		for control in child.find_children("*", "Control", true, false):
			if control is FighterPreview:
				check(control.phase == "attack_animation" and control.pose == count, "Backdraft review selected the wrong key")
				count += 1
		child.queue_free()
	check(count == 2, "Backdraft review must show consecutive keys")
	game.edit_character.select(previous)
	await tree.process_frame

func combo_inputs(hits: int = 2) -> void:
	for hit in hits:
		if hit > 0: release_hitstop()
		key(KEY_S, hit % 2 == 1)
		key(KEY_J, true)
		ticks(5)
		key(KEY_J, false)
		key(KEY_S, false)

func verify_timing_feedback() -> void:
	var original: Dictionary = game.model.data()
	game.fields.counterHitstun.control.value = 9
	game.fields.counterHitstop.control.value = 5
	game.fields.reversalEligible.control.button_pressed = true
	game.apply_move()
	check(game.model.move(0, 0).counterHitstun == 9 and game.model.move(0, 0).counterHitstop == 5 and game.model.move(0, 0).reversalEligible == 1, "Timing editor fields did not apply")
	game.lock_online(true)
	check(not game.fields.counterHitstun.control.editable and game.fields.reversalEligible.control.disabled, "Timing editor remains editable online")
	game.lock_online(false)
	game.model.load_data(original)
	check(game.model.load_data(timing_fixture()).is_empty(), "Timing fixture rejected")
	game.populate_editor()
	game.dummy.select(5)
	game.reset_round()
	combo_inputs()
	var cards: Array = game.arena.feedback.cards.duplicate(true)
	check(game.model.state().players[0].combo == 2 and cards[0].number == 2 and cards[1].number == 0, "Background counter is not owned by the combo attacker")
	check(cards[0].left and cards[0].hit == 3 and cards[0].font_size >= 40 and cards[0].font_size < 125, "Counter hit / small opening combo feedback missing")
	check(cards[0].center_y < game.arena.size.y * 0.55, "Combo feedback is not raised above the lower stage")
	var snapshot: PackedByteArray = game.model.core.snapshot()
	ticks(90)
	check(game.model.core.restore(snapshot), "Feedback snapshot rejected")
	game._process(0.0)
	check(game.arena.feedback.cards == cards, "Rollback did not restore visible feedback clocks/layout")
	release_hitstop()
	combo_inputs(8)
	var capped_size: int = game.arena.feedback.cards[0].font_size
	check(game.model.state().players[0].combo == 10 and capped_size > cards[0].font_size * 2, "Ten-hit combo did not grow to full size")
	release_hitstop()
	combo_inputs(2)
	check(game.model.state().players[0].combo == 12 and game.arena.feedback.cards[0].font_size == capped_size, "Combo kept growing beyond ten hits")
	game.reset_round()
	var dummy_hs: Dictionary = game.model.move(1, 3)
	ticks(dummy_hs.startup + dummy_hs.active - 1)
	key(KEY_J, true)
	ticks(5)
	key(KEY_J, false)
	check(game.model.state().players[0].event == 4 and game.arena.feedback.cards[0].hit == 4, "Recovery contact did not show PUNISH")
	game.dummy.select(6)
	game.reset_round()
	key(KEY_J, true)
	ticks(5)
	key(KEY_J, false)
	check(game.model.state().players[1].guarding == 1, "Reversal dummy did not begin by guarding")
	ticks(game.model.state().hitstop + game.model.state().players[1].stun + 1)
	check(game.model.state().players[1].move == 14 and game.arena.feedback.cards[1].reversal and game.arena.feedback.cards[1].input_age == 1, "Guard dummy did not execute/display a buffered reversal")
	# Jump over an approaching opponent; ground advances now respect pushboxes.
	game.dummy.select(0)
	game.reset_round()
	for _tick in 32: game.model.step(2, 1)
	game.model.step(8 | 2, 1)
	for _tick in 36 + int(game.model.data().jumpRules.prejumpFrames): game.model.step(2, 1)
	game._process(0.0)
	check(game.model.state().players[0].x > game.model.state().players[1].x, "Jump-over fixture did not cross")
	check(game.model.state().players[0].move == -1 and game.model.state().players[0].y == 0, "Jump-over did not land")
	combo_inputs()
	check(game.arena.feedback.cards[0].number == 2 and not game.arena.feedback.cards[0].left, "Combo stayed on a fixed player side after crossing")
	ticks(120)
	check(game.arena.feedback.cards[0].number == 0, "Completed combo did not expire")
	game.model.load_data(original)
	game.populate_editor()
	game.dummy.select(0)
	game.reset_round()

func run(runtime: SceneTree, existing: Control = null) -> void:
	tree = runtime
	game = existing
	if game == null:
		var scene := load("res://main.tscn") as PackedScene
		game = scene.instantiate()
		tree.root.add_child(game)
	if not game.has_method("advance_one"):
		printerr("Playable scene did not load its script")
		tree.quit(1)
		return
	game.set_physics_process(false)
	for path in ArenaStage.asset_paths():
		var stage_texture := load(path) as Texture2D
		check(stage_texture != null and stage_texture.get_width() == 1536, "Packaged stage art missing: " + path)
	check(game.characters == [5, 4] and game.menus.selection.chosen == [5, 4], "First matchup must be Fillet / Shark")
	check(game.edit_character.selected == 5, "Move editor should open on Fillet")
	await tree.process_frame
	var transitions = load("res://scripts/transition_verification.gd").new()
	failures += await transitions.run(tree, game)
	var entry = load("res://scripts/match_entry_verification.gd").new()
	failures += await entry.run(tree, game)
	var menus = load("res://scripts/menu_verification.gd").new()
	failures += await menus.run(tree, game)
	# Existing timing fixtures deliberately use Anvil/Hammer; keep that independent of defaults.
	game.edit_character.select(0)
	game.populate_editor()
	verify_recovery_editor()
	check(game.fields.startup.control.min_value == 3 and game.fields.has("hitboxBack"), "Editor is missing the startup floor or strike origin")
	game.release_focus_from_ui()
	key(KEY_D, true)
	ticks(20)
	key(KEY_D, false)
	key(KEY_J, true)
	var opening_move: Dictionary = game.model.move(0, 0)
	ticks(opening_move.startup - 1)
	check(game.model.state().players[1].health == 1000, "Attack hit before startup")
	ticks(1)
	key(KEY_J, false)
	check(game.model.state().players[1].health == 1000 - opening_move.damage, "Native keyboard attack did not hit")
	game.fields.damage.control.value = 177
	game.apply_move()
	check(game.model.move(0, 0).damage == 177, "Editor did not apply move")
	key(KEY_D, true)
	ticks(20)
	key(KEY_D, false)
	key(KEY_J, true)
	ticks(game.model.move(0, 0).startup)
	key(KEY_J, false)
	check(game.model.state().players[1].health == 823, "Edited damage did not affect combat")
	game.reset_round()
	game.fields.damage.control.get_line_edit().grab_focus()
	key(KEY_J, true)
	game.release_focus_from_ui()
	ticks(1)
	key(KEY_J, false)
	check(game.model.state().players[0].move == -1, "Typing in editor leaked into game input")
	game.selection_simple[0].button_pressed = true
	game.selection_simple[1].button_pressed = false
	game.confirm_selection()
	key(KEY_SHIFT, true)
	key(KEY_W, true)
	key(KEY_I, true)
	ticks(1)
	for code in [KEY_SHIFT, KEY_W, KEY_I]: key(code, false)
	var state: Dictionary = game.model.state()
	check(state.players[0].move == 16 and state.players[0].y == 0, "Simple up+Hs should invoke special, not jump")
	check(state.players[0].simple == 1 and state.players[1].simple == 0, "Simple controls are not independent")
	game.reset_round()
	key(KEY_S, true)
	ticks(1)
	key(KEY_D, true)
	ticks(1)
	key(KEY_S, false)
	key(KEY_J, true)
	ticks(1)
	key(KEY_J, false)
	key(KEY_D, false)
	check(game.model.state().players[0].move == 14, "Traditional motions no longer work in simple mode")
	game.run_trial()
	check(game.trial_status.text.begins_with("PASS"), "Rollback workbench failed")
	game.lock_online(true)
	check(not game.fields.damage.control.editable, "Editor remains editable during network play")
	game.lock_online(false)
	game.training_momentum.select(1)
	game.reset_round()
	check(game.model.state().players[0].momentum == 5000, "Training Momentum did not reset to 50%")
	key(KEY_A, true)
	key(KEY_Q, true)
	ticks(1)
	for code in [KEY_A, KEY_Q]: key(code, false)
	check(game.model.state().players[0].faultless == 1 and game.model.state().players[0].momentum == 5000 - game.model.data().momentumRules.fdDrain, "Keyboard FD macro failed")
	check(game.arena.sprites[0].get_meta("phase") == "block", "FD has no guard pose")
	game.mode.select(1)
	game.reset_round()
	check(game.model.state().players[0].momentum == 0, "Training meter leaked into local versus")
	game.mode.select(0)
	game.lock_online(true)
	check(game.training_momentum.disabled and not game.momentum_fields.fdDrain.control.editable and game.fields.guardBreak.control.disabled, "Defense settings remain editable online")
	game.lock_online(false)
	game.momentum_fields.fdDrain.control.value = 0.2
	game.apply_momentum()
	check(game.model.data().momentumRules.fdDrain == 20, "Momentum editor failed to apply rate")
	game.momentum_fields.fdDrain.control.value = 0.1
	game.apply_momentum()
	# Real contacts drive both poses of all three reaction clips for every defender.
	game.fields.reach.control.value = 500
	game.dummy.select(2)
	for character in CombatModel.CHARACTERS.size():
		game.menus.selection.choose_fighter(1, character)
		game.confirm_selection()
		for reaction in range(1, 4):
			var jab: Dictionary = game.model.move(0, 0)
			game.fields.blockstun.control.value = 10 if reaction == 1 else jab.active - 1 + jab.recovery + 4
			game.fields.guardBreak.control.button_pressed = reaction == 3
			game.apply_move()
			key(KEY_J, true)
			ticks(game.model.move(0, 0).startup)
			key(KEY_J, false)
			var defender: Dictionary = game.model.state().players[1]
			check(defender.blockReaction == reaction and defender.throwInvulnerable == int(reaction != 3), "Incorrect block reaction / throw eligibility")
			var block_visual: Sprite2D = game.arena.sprites[1]
			check(block_visual.get_meta("phase") == "block" and block_visual.get_meta("pose") == (reaction - 1) * 2, "Missing block contact frame")
			ticks(10)
			check(block_visual.get_meta("pose") == (reaction - 1) * 2 + 1, "Block clip did not settle after hitstop")
	game.fields.chipDamage.control.value = 12
	game.apply_move()
	game.dummy.select(4)
	key(KEY_J, true)
	ticks(game.model.move(0, 0).startup)
	key(KEY_J, false)
	check(game.model.state().players[1].health == 1000 and game.model.state().players[1].faultless == 1, "FD dummy did not prevent chip")
	game.model.restore_defaults()
	game.populate_editor()
	game.training_momentum.select(0)
	game.dummy.select(0)
	game.menus.selection.choose_fighter(1, 1)
	game.confirm_selection()
	# Exercise actual keyboard -> selected fighter -> windup/active artwork for all 30 basic buttons.
	var button_keys := [KEY_J, KEY_K, KEY_L, KEY_I, KEY_O]
	var slots := [0, 1, 2, 3, 13]
	for character in CombatModel.CHARACTERS.size():
		game.menus.selection.choose_fighter(0, character)
		game.selection_simple[0].button_pressed = false
		game.confirm_selection()
		for b in button_keys.size():
			game.reset_round()
			key(button_keys[b], true)
			ticks(1)
			key(button_keys[b], false)
			var fighter: Dictionary = game.model.state().players[0]
			check(fighter.character == character and fighter.move == slots[b], "Missing basic button for " + CombatModel.CHARACTERS[character])
			var visual: Sprite2D = game.arena.sprites[0]
			# Timed clips can use ready/idle/attack-animation keys rather than
			# the retired two-pose signature sheets. Verify core -> renderer sync.
			check(fighter.age < game.model.move(character, slots[b]).startup and visual.get_meta("phase") == FighterArt.PHASES[int(fighter.posePhase)] and visual.get_meta("pose") == fighter.poseIndex, "Attack has no synchronized entry/windup pose")
			var anticipation: Texture2D = visual.texture
			ticks(game.model.move(character, slots[b]).startup - 1)
			fighter = game.model.state().players[0]
			check(fighter.age >= game.model.move(character, slots[b]).startup and visual.get_meta("phase") == FighterArt.PHASES[int(fighter.posePhase)] and visual.get_meta("pose") == fighter.poseIndex and visual.texture != anticipation, "Attack did not change to its timed active image")
	game.menus.selection.choose_fighter(0, 0)
	game.confirm_selection()
	game.reset_round()
	verify_timing_feedback()
	await verify_signatures()
	await verify_recovery_art()
	await verify_smoke_idles()
	await verify_shark_movement()
	await verify_smoke_attacks()
	verify_foreground_draw()
	game.show_controls()
	check(game.has_open_dialog(), "Controls dialog did not open")
	for child in game.get_children():
		if child is AcceptDialog and child != game.file_dialog: child.queue_free()
	await tree.process_frame
	var args := OS.get_cmdline_user_args()
	if args.has("--combo"):
		game.model.load_data(timing_fixture())
		game.populate_editor()
		game.dummy.select(5)
		game.reset_round()
		game.show_boxes = false
		combo_inputs(6)
	if args.has("--defense"):
		game.training_momentum.select(1)
		game.dummy.select(4)
		game.fields.reach.control.value = 500
		game.fields.blockstun.control.value = 16
		game.fields.guardBreak.control.button_pressed = true
		game.apply_move()
		key(KEY_J, true)
		ticks(game.model.move(0, 0).startup)
		key(KEY_J, false)
	if args.has("--review"):
		game.show_sprite_review(3 if args.has("--block-review") else 0)
		check(game.has_open_dialog(), "Sprite review did not open")
	game.motion.instant = false
	if args.has("--home"): game.go_home()
	if args.has("--fighters"): game.go_home(); game.choose_activity("local")
	if args.has("--training"): game.go_home(); game.choose_activity("training"); game.confirm_selection()
	if args.has("--match"): game.go_home(); game.choose_activity("local"); game.confirm_selection()
	if args.has("--matches"): game.go_home(); game.show_screen("matches")
	if args.has("--connection"): game.go_home(); game.choose_activity("online"); game.confirm_selection()
	if args.has("--controls"): game.go_home(); game.show_controls()
	if args.has("--screenshot"):
		await game.wait_for_match_entry()
		await tree.process_frame
		await RenderingServer.frame_post_draw
		var path: String = args[args.find("--screenshot") + 1]
		check(tree.root.get_texture().get_image().save_png(path) == OK, "Could not save native screenshot")
	print("Godot playable scene: ", failures, " failures; combat, counter/punish/reversal, combo display/side-switch, editing, FD, block clips, rollback")
	tree.quit(1 if failures else 0)

func verify_recovery_editor() -> void:
	var original: Dictionary = game.model.data()
	game.fields.pushback.control.value = 12
	game.fields.airPushback.control.value = 24
	game.fields.blockPushback.control.value = 18
	game.fields.launch.control.value = 10
	game.fields.airLaunch.control.value = -2
	game.fields.knockdown.control.selected = 1
	game.fields.knockdownFrames.control.value = 7
	game.fields.wakeupFrames.control.value = 9
	game.apply_move()
	var move: Dictionary = game.model.move(0, 0)
	check(move.pushback == 1200 and move.airPushback == 2400 and move.blockPushback == 1800, "Independent hit distance / block displacement controls failed")
	check(move.launch == 1000 and move.airLaunch == -200 and move.knockdown == 1 and move.knockdownFrames == 7 and move.wakeupFrames == 9, "Reaction fields did not apply")
	game.recovery_fields.gravityAfter.control.value = 8
	game.recovery_fields.gravityStep.control.value = 15
	game.recovery_fields.wallThreshold.control.value = 800
	game.apply_recovery()
	check(game.model.data().recoveryRules.gravityAfter == 8 and game.model.data().recoveryRules.gravityStep == 15 and game.model.data().recoveryRules.wallThreshold == 800, "Recovery rules editor did not apply")
	game.lock_online(true)
	check(not game.recovery_fields.gravityAfter.control.editable and game.fields.knockdown.control.disabled, "Recovery editor remains editable online")
	game.lock_online(false)
	game.model.load_data(original)
	game.populate_editor()
	game.reset_round()

func verify_signatures() -> void:
	var original: Dictionary = game.model.data()
	game.edit_character.select(5)
	game.edit_move.select(25)
	game.populate_editor()
	game.fields.travelSpeed.control.value = 12
	game.fields.inertiaPercent.control.value = 80
	game.apply_move()
	check(game.model.move(5, 25).travelSpeed == 1200 and game.model.move(5, 25).inertiaPercent == 80, "Attack travel / inertia editor did not apply")
	game.movement_fields.runSpeed.control.value = 13
	game.movement_fields.forwardStyle.control.selected = 1
	game.movement_fields.airDashPauseFrames.control.value = 6
	game.movement_fields.airBackdashPauseFrames.control.value = 3
	game.apply_movement()
	check(game.model.movement(5).runSpeed == 1300 and game.model.movement(5).forwardStyle == 1, "Per-character movement controls did not apply")
	check(game.model.movement(5).airDashPauseFrames == 6 and game.model.movement(5).airBackdashPauseFrames == 3, "Air dash pause controls did not apply")
	game.lock_online(true)
	check(game.movement_fields.forwardStyle.control.disabled and not game.movement_fields.runSpeed.control.editable and game.fields.enabled.control.disabled, "Signature / movement editor remains editable online")
	game.lock_online(false)
	game.model.load_data(original)
	game.model.reset([5, 4])
	game.release_focus_from_ui()
	key(KEY_S, true); ticks(1)
	key(KEY_D, true); ticks(1)
	key(KEY_S, false); key(KEY_K, true); ticks(1)
	key(KEY_K, false); key(KEY_D, false)
	var spiral: Dictionary = game.model.state().players[0]
	var spiral_visual: Sprite2D = game.arena.sprites[0]
	check(spiral.move == 25 and spiral_visual.get_meta("phase") == FighterArt.PHASES[int(spiral.posePhase)] and spiral_visual.get_meta("pose") == spiral.poseIndex, "Keyboard 236K / selected windup failed")
	var spiral_windup: Texture2D = spiral_visual.texture
	ticks(game.model.move(5, 25).startup - 1)
	spiral = game.model.state().players[0]
	check(spiral.age >= game.model.move(5, 25).startup and spiral_visual.get_meta("phase") == FighterArt.PHASES[int(spiral.posePhase)] and spiral_visual.get_meta("pose") == spiral.poseIndex and spiral_visual.texture != spiral_windup, "Selected active art did not follow combat timing")
	game.edit_character.select(5)
	game.edit_move.select(0)
	game.populate_editor()
	game.show_kit_editor()
	await tree.process_frame
	var kit_open := false
	for child in game.get_children():
		if child is KitEditor:
			kit_open = true
			var prior_kit: String = game.model.fingerprint()
			child.apply_changes()
			check(game.model.fingerprint() == prior_kit, "Kit dialog changed unchanged parameters or metadata")
			game.close_dialog(child)
	check(kit_open, "Native kit controls did not open")
	await tree.process_frame
	game.model.reset([4, 5])
	game.model.step(4, 0); game.model.step(5, 0); game.model.step(65, 0)
	for _tick in 20: game.model.step(0, 0)
	game._process(0.0)
	check(game.arena.weapons[0].visible and game.model.core.boxes(0, 2).size() == 32, "Detached spear / narrow diagonal boxes are missing")
	game.show_sprite_review(10)
	await tree.process_frame
	check(game.has_open_dialog(), "Signature sprite review did not open")
	for child in game.get_children():
		if child is AcceptDialog and child != game.file_dialog: child.queue_free()
	await tree.process_frame
	game.edit_character.select(0)
	game.edit_move.select(0)
	game.populate_editor()
	game.reset_round()
