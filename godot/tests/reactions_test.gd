extends SceneTree

var failures := 0
func check(value: bool, message: String) -> void:
	if not value: failures += 1; printerr(message)
func _initialize() -> void: call_deferred("run")

func cue(kind: int = 1, flags: int = 2, actor: int = 0) -> PackedInt32Array:
	return PackedInt32Array([0, kind, actor, 4, 0, 1, 50000, 3000, 1, 1, flags, 0])

func run() -> void:
	var body := {"reaction": 0, "stun": 20, "guarding": 0, "y": 0}
	for flags in [2, 4, 6]:
		check(CombatReactions.family(body, {"flags": flags}) == {2: "legs", 4: "chest", 6: "head"}[flags], "Wrong anatomical reaction")
		check(CombatReactions.family(body, {"flags": flags | 8}) == "air", "Air contact did not override body zone")
		var launched := body.duplicate(); launched.y = 100
		check(CombatReactions.family(launched, {"flags": flags}) == "air", "Ground launcher did not transition to air art")
	check(CombatReactions.family(body, {"flags": 0}) == "chest", "Legacy cue needs a chest fallback")
	check(CombatReactions.family(body, {}) == "", "Missing contact manufactured a reaction")
	for reaction in [2, 3, 4, 6]:
		var special := body.duplicate(); special.reaction = reaction
		check(CombatReactions.family(special, {"flags": 2}) == "", "Reaction replaced knockdown/wake/splat/capture")
	for guarding in [0, 1]:
		check(not CombatReactions.receiving({"stun": 0, "guarding": guarding}), "Neutral created a hurt animation")
	check(not CombatReactions.receiving({"stun": 20, "guarding": 1}), "Block played a hit reaction")
	var history := CombatCues.new()
	history.capture(0, false, cue())
	check(history.reaction_at(1, 1).age == 0 and history.reaction_at(1, 0).is_empty(), "Hit selected the wrong receiver")
	for frame in range(1, 9): history.capture(frame, true, PackedInt32Array())
	check(history.reaction_at(9, 1).age == 0, "Hitstop advanced the contact pose")
	for frame in range(9, 19): history.capture(frame, false, PackedInt32Array(), [false, frame % 2 == 1])
	check(history.reaction_at(19, 1).age == 5, "Defender-only slowdown clock was ignored")
	for frame in range(19, 40): history.capture(frame, false, PackedInt32Array())
	check(history.visible_at(40).is_empty() and history.reaction_at(40, 1).age == 26, "Reaction expired with short-lived impact FX")
	check(CombatReactions.key(0) == 0 and CombatReactions.key(1) == 0 and CombatReactions.key(2) == 1 and CombatReactions.key(4) == 1 and CombatReactions.key(5) == 2 and CombatReactions.key(150) == 2, "Contact/recoil/hold timing drifted")
	history.capture(40, false, cue(1, 6))
	check(history.reaction_at(41, 1).age == 0 and history.reaction_at(41, 1).flags == 6, "Follow-up failed to replace the reaction")
	check(history.reaction_at(40, 1).flags == 2, "Follow-up mutated prior rollback history")
	history.capture(41, false, PackedInt32Array(), [false, false], [false, false])
	check(history.reaction_at(42, 1).is_empty(), "Recovered fighter kept a stale reaction")
	# Replay the original predicted hit as a block; remove the entire future.
	history.capture(0, false, cue(2, 2))
	check(history.reaction_at(1, 1).is_empty() and history.reaction_at(41, 1).is_empty(), "Rollback retained a false receiver animation")
	for kind in [2, 5, 6, 7, 8, 9, 10, 11, 12]:
		history.reset(); history.capture(0, false, cue(kind))
		check(history.reaction_at(1, 1).is_empty(), "Non-hit cue manufactured hitstun art")
	for kind in [1, 3, 4]:
		history.reset(); history.capture(0, false, cue(kind))
		check(not history.reaction_at(1, 1).is_empty(), "Hit/counter/punish lacks receiver art")
	history.reset(); history.capture(0, false, cue(1, 2) + cue(1, 6, 1))
	check(history.reaction_at(1, 0).flags == 6 and history.reaction_at(1, 1).flags == 2, "Trade reactions contaminated one another")
	history.reset(); check(history.reaction_at(1, 1).is_empty(), "Round reset leaked a reaction")

	var model := LegacyFixture.create()
	var data := model.data()
	data.characters[5].moves[0].reach = 40000
	data.characters[5].moves[0].hitstop = 8
	check(model.load_data(data).is_empty(), "Reaction fixture rejected")
	model.reset([5, 4])
	var sprite := Sprite2D.new()
	var hit := false
	for frame in 12:
		model.step(16 if frame == 0 else 0, 0)
		var state := model.state()
		var reaction: Dictionary = model.cues.reaction_at(model.frame(), 1)
		if reaction.is_empty(): continue
		hit = true
		var fighter: Dictionary = state.players[1]
		FighterArt.apply(sprite, 4, FighterArt.PHASES[fighter.posePhase], fighter.poseIndex, 1, fighter.facing)
		var before := model.state_hash()
		CombatReactions.apply(sprite, fighter, reaction, 1)
		check(not str(sprite.get_meta("reaction_family")).is_empty(), "Native contact never reached the render selector")
		check(before == model.state_hash(), "Reaction rendering changed gameplay")
	check(hit, "Fixture never exercised an actual hit")
	# Exercise atlas registration without installing an unapproved drawing.
	# The test-only clip reuses the approved ready image; runtime manifest stays intact.
	var saved_catalog: Dictionary = CombatReactions.catalog()
	var ready: Dictionary = FighterArt.sheet(5, "ready")
	var registered: Dictionary = ready.frames[0].duplicate(true)
	CombatReactions.manifest = {"fighters": {"5": {"legs": {"file": "../" + str(registered.get("file", ready.file)), "body_height": ready.body_height, "frames": [registered, registered, registered]}}}}
	for facing in [-1, 1]:
		FighterArt.apply(sprite, 5, "ready", 0, 1.3, facing)
		var scale_before := sprite.scale
		var offset_before := sprite.offset
		var placed := body.duplicate(); placed.character = 5; placed.facing = facing
		for age in [0, 2, 5, 150]:
			check(CombatReactions.apply(sprite, placed, {"flags": 2, "age": age}, 1.3), "Approved atlas registration failed")
			check(sprite.scale.is_equal_approx(scale_before) and sprite.offset.is_equal_approx(offset_before), "Reaction changed anatomy scale or root registration")
	CombatReactions.manifest = saved_catalog
	CombatReactions.textures.clear()
	sprite.free()
	print("Receiver reactions: %d failures; body zones, air priority, timing, trades, rollback and native rendering" % failures)
	quit(1 if failures else 0)
