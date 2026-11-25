extends SceneTree
var failures := 0
func check(value: bool, message: String) -> void:
	if not value: failures += 1; printerr(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for family in CombatImpacts.catalog.families.values():
		var texture: Texture2D = load(CombatImpacts.DIRECTORY + str(family.file))
		check(texture != null, "Missing impact atlas")
		for frame in family.frames:
			var r: Array = frame.region
			check(r[0] >= 0 and r[1] >= 0 and r[0] + r[2] <= texture.get_width() and r[1] + r[3] <= texture.get_height(), "Impact region leaves atlas")
	var cue := {"kind":1, "character":5, "move":3, "age":0, "actor":0, "facing":1, "strength":3, "x":50000, "y":8000}
	var old := cue.duplicate(); old.age = 1
	var trade := cue.duplicate(); trade.actor = 1
	var wall := cue.duplicate(); wall.kind = 10
	var history := [old, cue, trade, wall]
	var visible := CombatImpacts.visible(history)
	check(visible == [cue, trade, wall], "Rapid follow-up stacks an old hit or removes trade/wall feedback")
	check(history.size() == 4 and old.age == 1, "Visual filtering changed the event history")
	check(CombatImpacts.family(cue) == "cut", "Fillet knife lost its cut family")
	cue.character = 4
	check(CombatImpacts.family(cue) == "pierce", "Shark spear lost its pierce family")
	cue.character = 1
	check(CombatImpacts.family(cue) == "blunt", "Hammer lost its blunt family")
	cue.character = 2; cue.move = 16
	check(CombatImpacts.family(cue) == "fire", "Flame Blade lost fire contact")
	cue.move = 15
	check(CombatImpacts.family(cue) == "gas", "Poison Sword lost gas contact")
	cue.kind = 2
	check(CombatImpacts.family(cue) == "block", "Block contact missing")
	check(CombatImpacts.drawing(cue).facing == -1, "Guard crescent wraps toward the attacker")
	cue.facing = -1
	check(CombatImpacts.drawing(cue).facing == 1, "Mirrored guard does not wrap toward the defender")
	cue.facing = 1
	cue.kind = 6
	check(CombatImpacts.family(cue) == "faultless", "FD uses ordinary block art")
	cue.kind = 5
	check(CombatImpacts.family(cue) == "guard_break", "Guard break still uses ordinary block art")
	cue.kind = 7
	check(CombatImpacts.family(cue) == "armor", "Armor lost its metal/ember response")
	cue.kind = 3
	check(CombatImpacts.family(cue) == "counter", "Counter contact missing")
	check(CombatImpacts.impulse([cue], true) == Vector2.ZERO, "Reduced motion still shakes")
	check(CombatImpacts.impulse([cue], false).length() < 4.5, "Impact shake is too large")
	for age in 10:
		cue.age = age
		var spec := CombatImpacts.drawing(cue)
		check(not spec.is_empty() and spec.alpha > 0 and spec.alpha < 1, "Invisible or opaque impact")
	cue.age = 10
	check(CombatImpacts.drawing(cue).is_empty(), "Impact lingers beyond ten action frames")
	check(CombatImpacts.tint(1, [cue]) == Color.WHITE, "Stun keeps an unwanted body tint")
	var model := LegacyFixture.create()
	var data := model.data(); data.characters[5].moves[0].reach = 40000
	check(model.load_data(data).is_empty(), "Impact fixture rejected")
	model.reset()
	for tick in 6: model.step(16 if tick == 0 else 0, 0)
	var before := model.state_hash()
	var arena = load("res://scripts/arena.gd").new()
	arena.size = Vector2(1280, 720); root.add_child(arena)
	arena.refresh(model, model.state(), false, false)
	check(arena.impact_cues.size() == 1, "Native arena did not receive contact")
	check(arena.impact_cues[0].age == 0, "Hitstop did not hold the contact drawing")
	check(arena.impact_layer.get_index() > arena.sprites[0].get_index() and arena.impact_layer.get_index() > arena.sprites[1].get_index(), "Impact hidden behind fighters")
	check(arena.impact_layer.get_index() < arena.hud_layer.get_index(), "Impact covers HUD")
	check(model.state_hash() == before, "Presentation changed combat state")
	var initial_flash_age := int(arena.impact_cues[0].screen_age)
	for tick in 4: model.step(0, 0)
	var frozen_cues := model.cues.visible_at(model.frame())
	check(frozen_cues[0].age == 0 and frozen_cues[0].screen_age == initial_flash_age + 4, "Contact drawing and brief flash do not have independent clocks")
	check(CombatImpacts.impulse(frozen_cues, false) == Vector2.ZERO, "Camera impulse stays displaced through long hitstop")
	check(CombatImpacts.drawing(frozen_cues[0]).key == 0, "Hitstop advanced the held impact drawing")
	var history_hash := model.state_hash()
	arena.refresh(model, model.state(), false, true)
	arena.refresh(model, model.state(), false, true)
	check(frozen_cues[0].screen_age == initial_flash_age + 4 and model.state_hash() == history_hash, "Pause/repaint advances presentation or gameplay")
	var release_history := CombatCues.new()
	var swing := PackedInt32Array([0,8,0,5,3,7,50000,8000,1,3,0,0])
	release_history.capture(0, false, swing)
	check(release_history.releases_at(1).size() == 1 and release_history.visible_at(1).is_empty(), "Whiff release missing or treated as a hit")
	var impact := PackedInt32Array([1,1,0,5,3,7,54000,8000,1,3,0,0])
	release_history.capture(1, false, impact)
	check(release_history.releases_at(2).is_empty(), "A confirmed hit kept its release effect")
	release_history.capture(1, false, PackedInt32Array())
	check(release_history.visible_at(2).is_empty() and release_history.releases_at(2).size() == 1, "Rollback did not restore a corrected whiff")
	for tick in range(2, 9): release_history.capture(tick, true, PackedInt32Array())
	check(release_history.releases_at(9).is_empty(), "A whiff release lingers through unrelated hitstop")
	arena.queue_free(); await process_frame
	print("Ink Snap assets, distinct defense, snap/release clocks, rollback, layering and reduced motion: %d failures" % failures)
	quit(1 if failures else 0)
