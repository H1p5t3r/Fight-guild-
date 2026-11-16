extends SceneTree
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	var model := CombatModel.new()
	var data := model.data()
	var move: Dictionary = data.characters[5].moves[0]
	move.active = 7
	move.pushback = 0
	move.hitstop = 0
	move.starterProration = 100
	move.comboScaling = 0
	var first := {"frame": 1, "hit": 1, "boxes": [[0,0,30000,20000],[0,0,30000,20000]], "damage": 20, "hitstun": 90, "blockstun": 90, "hitstop": 0}
	var second: Dictionary = first.duplicate(true)
	second.frame = 3
	second.hit = 2
	second.damage = 30
	move.hitboxTimeline = {"multiHit": true, "keys": [first, second]}
	check(model.load_data(data).is_empty(), "Timeline import failed")
	check(model.move(5,0).hitboxTimeline == move.hitboxTimeline, "Timeline did not round-trip")
	model.reset()
	for tick in 5: model.step(16 if tick == 0 else 0, 0)
	check(model.state().players[1].health == 980, "Overlapping boxes inflicted multiple hits")
	var snapshot: PackedByteArray = model.core.snapshot()
	for tick in 10: model.step(0,0)
	check(model.state().players[1].health == 950, "Second hit was not applied")
	var expected := model.state_hash()
	check(model.core.restore(snapshot), "Multi-hit snapshot rejected")
	for tick in 10: model.step(0,0)
	check(model.state_hash() == expected, "Multi-hit rollback differs")
	var before := model.fingerprint()
	var bad: Dictionary = data.duplicate(true)
	bad.characters[5].moves[0].hitboxTimeline["keys"][1].frame = 1
	check(not model.load_data(bad).is_empty() and model.fingerprint() == before, "Malformed timeline was not rejected atomically")
	move.hitboxTimeline.multiHit = false
	check(model.load_data(data).is_empty(), "Single-hit toggle rejected")
	model.reset()
	for tick in 18: model.step(16 if tick == 0 else 0,0)
	check(model.state().players[1].health == 980, "Single-hit toggle did not apply")
	var path := "user://hit-timeline-roundtrip.json"
	check(model.save_file(path).is_empty(), "Timeline save failed")
	var loaded := CombatModel.new()
	check(loaded.load_file(path).is_empty() and loaded.move(5,0).hitboxTimeline == move.hitboxTimeline, "Saved timeline was lost")
	var legacy: Dictionary = data.duplicate(true)
	legacy.schema = 13
	legacy.coreVersion = 13
	for c in legacy.characters:
		for m in c.moves: m.erase("hitboxTimeline")
	check(model.load_data(legacy).is_empty() and model.move(5,0).hitboxTimeline["keys"].is_empty(), "Schema-13 migration failed")
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		var browser_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
		check(browser_data is Dictionary, "Browser download was not JSON")
		if browser_data is Dictionary:
			check(model.load_data(browser_data).is_empty(), "Browser download failed import")
			for c in 6:
				for m in 32:
					check(JSON.parse_string(JSON.stringify(model.move(c,m).hitboxTimeline)) == browser_data.characters[c].moves[m].hitboxTimeline, "Browser key data changed during native import %d/%d" % [c,m])
			check(model.move(5,0).hitboxTimeline.multiHit and model.move(5,0).hitboxTimeline["keys"].size()==2, "Browser multi-hit fixture was not loaded")
	print("Godot hitbox timelines and multi-hit toggle: %d failures" % failures)
	quit(1 if failures else 0)
