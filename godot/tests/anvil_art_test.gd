extends SceneTree

var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("Anvil art: " + message)
func _initialize() -> void: call_deferred("run")

func run() -> void:
	var model := PairedThrowFixtures.create()
	var fighter: Dictionary = FighterArt.catalog().fighters[0]
	var arena = load("res://scripts/arena.gd").new()
	root.add_child(arena)
	arena.size = Vector2(1280, 720)
	check(fighter.attack_animations.size() == 26, "Incomplete enabled kit")
	for phase in FighterArt.phase_names(0):
		for frame in FighterArt.sheet(0, phase).frames:
			check(str(frame.file).begins_with("anvil-bull-v2/"), "Old hammer art in " + phase)
			check(not str(frame.get("name", "")).is_empty(), "Sprite review caption missing in " + phase)
	for facing in [-1, 1]:
		for slot_text in fighter.attack_animations:
			var slot := int(slot_text)
			var move := model.move(0, slot)
			var clip: Dictionary = fighter.attack_animations[slot_text]
			var timing: Array = clip.exposureTiming.authoredTiming
			check([int(timing[0]), int(timing[1]), int(timing[2])] == [int(move.startup), int(move.active), int(move.recovery)], "Timing differs from data")
			model.reset([0, 2])
			model.core.preview_place(0, 50000-facing*22000, 30000 if move.air else 0, 10000)
			model.core.preview_place(1, 50000+facing*22000, 0, 0)
			model.step(0, 0)
			check(model.core.preview_begin(0, slot) == 1, "Action failed to begin")
			var active_seen := false
			for tick in 190:
				var state := model.state()
				var p: Dictionary = state.players[0]
				if int(p.move) == slot and int(p.age) == int(move.startup) and slot != 13:
					active_seen = true
					check(int(p.posePhase) == 14 and int(p.poseIndex) == int(clip.active[0].pose), "First active drawing drifted: " + slot_text)
				var before: PackedByteArray = model.core.snapshot()
				arena.refresh(model, state, false, false)
				check(model.core.snapshot() == before, "Rendering mutated combat")
				check("anvil-bull-v2/" in arena.sprites[0].texture.atlas.resource_path, "Legacy sprite appeared")
				model.step(0, 0)
			check(active_seen or slot in [13, 21], "Never reached active: " + slot_text)
		# The stance's held age must still show a walking guard from saved travel.
		model.reset([0, 2])
		model.core.preview_place(0, 50000-facing*20000, 0, 0)
		model.core.preview_place(1, 50000+facing*20000, 0, 0)
		model.step(0, 0)
		model.core.preview_begin(0, 13)
		var keys := {}
		for tick in 35:
			model.step(256 + (2 if facing == 1 else 1), 0)
			var p: Dictionary = model.state().players[0]
			if p.age >= 4:
				check(p.posePhase == 8, "Shield advance lost stance art")
				keys[p.poseIndex] = true
		check(keys.size() == 4, "Held guard did not shuffle: " + str(keys))
		var snapshot: PackedByteArray = model.core.snapshot()
		for tick in 20: model.step(256, 0)
		var expected := model.state_hash()
		check(model.core.restore(snapshot), "Restore failed")
		for tick in 20: model.step(256, 0)
		check(model.state_hash() == expected, "Guard pose diverged on rollback")
		for slot in [14, 15, 16]:
			PairedThrowFixtures.prepare(model, 0, 4, slot, 0, facing)
			if slot == 16:
				model.core.preview_place(0, 50000-facing*3000, 0, 10000)
				model.core.preview_place(1, 50000+facing*3000, 16000, 0)
			model.core.preview_begin(0, slot)
			var poses := {}
			var released := false
			for tick in 240:
				model.step(0, 0)
				var state := model.state()
				if state.pairKind == 0:
					if not poses.is_empty() and not released and int(state.players[0].pairRecovery) > 0:
						released = true
						var finish: Dictionary = fighter.paired_animations[str(slot)].keys[-1]
						check(state.players[0].posePhase == 14 and state.players[0].poseIndex == int(finish.pose), "Slam vanished at release impact")
					continue
				var before: PackedByteArray = model.core.snapshot()
				arena.refresh(model, state, false, false)
				poses[state.players[0].poseIndex] = true
				check("anvil-bull-v2/" in arena.sprites[0].texture.atlas.resource_path, "Generic grab replaced authored choreography")
				check(arena.sprites[0].get_meta("grab_role") == "owner", "Capture role lost")
				check(model.core.snapshot() == before, "Paired presentation changed simulation")
			check(poses.size() == 3, "Capture did not show catch/lift/slam")
			check(released, "Capture release was not checked")
	arena.queue_free()
	await process_frame
	print("Anvil art: %d failures; native kit, first-active timing, guard travel, paired clips and rollback" % failures)
	quit(1 if failures else 0)
