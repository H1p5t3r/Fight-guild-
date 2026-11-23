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
	cue.kind = 6
	check(CombatImpacts.family(cue) == "faultless", "FD uses ordinary block art")
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
	arena.queue_free(); await process_frame
	print("Ink Snap assets, families, clocks, layering and reduced motion: %d failures" % failures)
	quit(1 if failures else 0)
