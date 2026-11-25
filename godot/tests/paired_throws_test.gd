extends SceneTree

var failures := 0
var cases := 0
var arena: Control
var model: CombatModel

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		if failures < 25: printerr(message)

func _initialize() -> void: call_deferred("run")

func render_checked() -> void:
	var state := model.state()
	var snapshot: PackedByteArray = model.core.snapshot()
	var boxes := [model.core.boxes(0, 0), model.core.boxes(1, 0)]
	arena.refresh(model, state, false, false)
	check(model.core.snapshot() == snapshot, "Throw presentation changed the simulation snapshot")
	for p in 2:
		check(model.core.boxes(p, 0) == boxes[p], "Throw presentation changed hurtboxes")
	var grip := CombatGrabs.capture(model, state)
	if not grip.is_empty():
		for p in 2:
			var sprite := arena.sprites[p] as Sprite2D
			check(sprite.get_meta("grab_role") == ("owner" if p == int(grip.owner) else "receiver"), "Paired drawing lost its role")
			var offset: Vector2 = sprite.get_meta("grab_offset")
			var world_scale: float = arena.size.x / 1000.0 * arena.camera_zoom
			check(is_zero_approx(offset.y) and absf(offset.x) <= 18.0 * world_scale + 0.01, "Grip registration moved feet vertically or too far from physics")
			if sprite.texture is AtlasTexture and "/grabs-v1/" in sprite.texture.atlas.resource_path:
				var clip: Dictionary = CombatGrabs.catalog().fighters[str(state.players[p].character)]
				check(is_equal_approx(sprite.scale.y, 150.0 / float(clip.body_height) * world_scale) and is_equal_approx(absf(sprite.scale.x), sprite.scale.y), "Grip pose changed anatomy scale")
		check(arena.sprites[1-int(grip.owner)].get_meta("reaction_family") == "", "Hit recoil replaced a paired hold")
	var foreground: int = arena.foreground_player(state)
	if foreground in [0, 1]:
		check(arena.sprites[foreground].get_index() > arena.sprites[1 - foreground].get_index(), "Capture owner hidden behind defender")
		check(arena.weapons[foreground].get_index() > arena.sprites[foreground].get_index(), "Capture weapon layer separated from owner")

func exercise(attacker: int, victim: int, slot: int, owner: int, facing: int, middle: int, tech: bool = false) -> void:
	cases += 1
	var label := "%d/%d vs %d owner %d facing %d at %d%s" % [attacker, slot, victim, owner, facing, middle, " TECH" if tech else ""]
	PairedThrowFixtures.prepare(model, attacker, victim, slot, owner, facing, middle)
	check(model.core.preview_begin(owner, slot), "Move cannot start: " + label)
	var captured := false
	var released := false
	var damage_events := 0
	var tech_sent := false
	var held_frames := 0
	var keys := {}
	var replay_snapshot := PackedByteArray()
	var replay_frames := 0
	var replay_cues := {}
	for tick in 150:
		var before := model.state()
		var input := 0
		if tech and not tech_sent and int(before.pairKind) > 0 and int(before.hitstop) == 0:
			input = 48 # Fresh P+K during the ordinary throw's tech window.
			tech_sent = true
		model.step(input if owner == 1 else 0, input if owner == 0 else 0)
		var state := model.state()
		var receiver: Dictionary = state.players[1 - owner]
		var cue := model.cues.reaction_at(model.frame(), 1 - owner)
		if int(state.pairKind) > 0 or int(receiver.grabOwner) == owner:
			captured = true
			var remaining := int(state.pairTicks)-int(state.pairClock) if int(state.pairKind) > 0 else int(state.players[owner].grabTime)
			var expected_foreground := 1-owner if attacker == 0 and remaining <= 8 else owner
			check(arena.foreground_player(state) == expected_foreground, "Wrong foreground during capture: " + label)
			check(CombatReactions.family(receiver, cue).is_empty(), "Strike art replaced capture: " + label)
			# Previous hit priority must not obscure either kind of current grip.
			var prior_contact := state.duplicate(true)
			prior_contact.foregroundPlayer = 1 - owner
			check(arena.foreground_player(prior_contact) == expected_foreground, "Previous attacker overrides capture: " + label)
		elif captured:
			released = true
		for event in model.cues.events_at(model.frame() - 1):
			if int(event.kind) == 1 and int(event.actor) == owner: damage_events += 1
		var damaging_pair := attacker == 5 and slot in [23, 24, 45, 46] and not tech
		if damaging_pair and released and int(receiver.pairRecovery) > 0:
			check(not cue.is_empty(), "Damaging release snapped to idle: " + label)
			check(CombatReactions.family(receiver, cue) == "chest", "Release has wrong reaction family: " + label)
			check(model.cues.reaction_at(model.frame(), owner).is_empty(), "Attacker received the throw recoil: " + label)
			if not cue.is_empty():
				keys[CombatReactions.key(int(cue.age))] = true
				if int(state.hitstop) > 0:
					held_frames += 1
					check(int(cue.age) == 0, "Throw release pose advanced during hitstop: " + label)
				if replay_snapshot.is_empty(): replay_snapshot = model.core.snapshot()
		if tech or (attacker == 5 and slot == 13):
			check(cue.is_empty(), "Tech or Wound manufactured a damaging reaction: " + label)
		render_checked()
		if damaging_pair and released and int(receiver.pairRecovery) > 0:
			var sprite := arena.sprites[1 - owner] as Sprite2D
			var expected_frame := CombatReactions.frame_for(victim, "chest", int(cue.age))
			var expected_path: String = (CombatReactions.DIRECTORY + str(expected_frame.file)).simplify_path()
			check(sprite.get_meta("reaction_family") == "chest" and sprite.texture is AtlasTexture and sprite.texture.atlas.resource_path == expected_path, "Arena failed to show approved release art: " + label)
		if not replay_snapshot.is_empty():
			replay_frames += 1
			replay_cues[model.frame()] = cue.duplicate(true)
	check(captured and released, "Capture/release never occurred: " + label)
	var no_damage := tech or (attacker == 5 and slot == 13)
	check(damage_events == (0 if no_damage else 1), "Throw must resolve exactly once: " + label)
	check(model.cues.reaction_at(model.frame(), 1 - owner).is_empty(), "Reaction leaked past recovery: " + label)
	if attacker == 5 and not no_damage:
		check(keys.size() == 3 and held_frames > 0, "Release did not show contact/recoil/hold: " + label)
	if tech:
		check(tech_sent and model.state().players[1 - owner].health == 1000, "Throw tech caused damage: " + label)
	# Rewind to the damaging release and replace the predicted future. Both core
	# state and the independent cosmetic clock must land on exactly the same keys.
	if not replay_snapshot.is_empty():
		var checksum := model.state_hash()
		check(model.core.restore(replay_snapshot), "Release snapshot rejected")
		for tick in replay_frames - 1:
			model.step(0, 0)
			check(model.cues.reaction_at(model.frame(), 1 - owner) == replay_cues[model.frame()], "Release reaction diverged on rollback: " + label)
		check(model.state_hash() == checksum, "Throw replay changed gameplay: " + label)

func run() -> void:
	model = PairedThrowFixtures.create()
	arena = load("res://scripts/arena.gd").new()
	root.add_child(arena); arena.size = Vector2(1440, 810)
	var positions := [11000, 50000, 89000]
	# Every receiver, all four authored damaging throws, both facings; alternate
	# player slot and left/center/right placement to cover actual production data.
	for victim in 6:
		for slot in [23, 24, 45, 46]:
			for facing in [-1, 1]:
				exercise(5, victim, slot, (victim + slot) % 2, facing, positions[(victim + slot) % 3])
	# Tech recovery and Wound also use pairRecovery, but must never look struck.
	for owner in 2:
		for facing in [-1, 1]:
			for slot in [23, 24]: exercise(5, 4, slot, owner, facing, 50000, true)
			exercise(5, 4, 13, owner, facing, 50000)
	# Legacy six-tick captures and Tapper's longer grips keep their existing
	# knockdown presentation; only their capture layering changes.
	for attacker in [0, 1, 2, 3, 4]:
		for owner in 2:
			for facing in [-1, 1]:
				exercise(attacker, 5, 23 if facing < 0 else 24, owner, facing, positions[attacker % 3])
	for owner in 2:
		for slot in [13, 40]: exercise(3, 4, slot, owner, 1 if owner == 0 else -1, 50000)
	# After a capture ends, return to the actual last-contact priority. Neither
	# stale pairOwner nor stale grabOwner may leave a fighter in front forever.
	for owner in 2:
		var stale := {"pairKind": 0, "pairOwner": owner, "foregroundPlayer": 1 - owner, "players": [{"reaction": 0, "grabOwner": owner}]}
		check(arena.foreground_player(stale) == 1 - owner, "Stale capture changed normal contact priority")
	arena.queue_free()
	await process_frame
	print("Paired throw presentation: %d failures across %d actual captures; release hold, layering, tech, Wound, corners and replay" % [failures, cases])
	quit(1 if failures else 0)
