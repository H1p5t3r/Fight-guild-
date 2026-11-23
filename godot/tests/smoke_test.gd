extends SceneTree
var failures := 0
func check(value: bool, message: String) -> void:
	if not value: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var model := LegacyFixture.create()
	var data := model.data()
	check(data.schema == 27 and data.characters[2].moves.size() == 47, "Smoke schema missing")
	check(model.move(2,43).guardBreak == 1 and model.move(2,43).blockstun == 39, "Charged guard crush missing")
	for dust in [false,true]:
		model.reset([2,3])
		var input := 256 if dust else 2 | 128
		var frames := 28 if dust else 36
		for tick in range(1,frames):
			model.step(input,0)
			check(model.core.boxes(0,2).is_empty(), "Charge dealt damage before release")
		model.step(input,0)
		check(model.state().players[0].move == (44 if dust else 43), "Hold did not select charged slot")
		check(not model.core.boxes(0,2).is_empty(), "Charged active boxes missing")
	var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/2026-11-18-tapper/FightGuild-Tapper.json"))
	check(model.load_data(old).is_empty(), "Schema18 import failed")
	var upgraded := model.data()
	for c in 6:
		check(model.move(c,43).enabled == 0 and model.move(c,44).enabled == 0, "Legacy import enabled new charge slots")
		for m in 43:
			for field in CombatModel.FIELDS:
				var before: Dictionary = old.characters[c].moves[m]
				if not before.has(field): continue
				var expected: int = 2 if field == "startup" and before.category == 4 and before.motion == 0 else int(before[field])
				check(upgraded.characters[c].moves[m][field] == expected, "Legacy move was overwritten")
	verify_special_recovery()
	print("Smoke normals / charge / legacy imports: %d failures" % failures)
	quit(1 if failures else 0)

func verify_special_recovery() -> void:
	var model := CombatModel.new()
	var batch: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/" + batch.file))
	check(model.load_data(source).is_empty(), "Current Smoke special data failed to load")
	var sprite := Sprite2D.new()
	var art: Dictionary = FighterArt.catalog().fighters[2]
	for facing in [-1, 1]:
		for slot in [14,25,15,16]:
			model.reset([2,5])
			model.core.preview_place(0,50000,0,0)
			model.core.preview_place(1,50000+40000*facing,0,0)
			model.step(0,0)
			check(model.core.preview_begin(0,slot) == 1, "Special preview could not start")
			var saw_release := false
			var saw_recovery := false
			for tick in 180:
				model.step(0,0)
				var state := model.state()
				var actor: Dictionary = state.players[0]
				if actor.move != slot: continue
				check(actor.posePhase == 14, "Special fell back to the old two-pose animation")
				if actor.posePhase != 14: continue
				var frame: Dictionary = art.attack_animation.frames[actor.poseIndex]
				FighterArt.apply(sprite,2,"attack_animation",actor.poseIndex,1,facing,actor.idleTime)
				check(sprite.texture.atlas != null and signf(sprite.scale.x) == facing, "Recovery sprite missing or mirrored incorrectly")
				check(model.core.boxes(0,0).size() <= 16, "Special exceeded four body hurtboxes")
				if actor.age == int(source.characters[2].moves[slot].startup):
					saw_release = frame.motion_cue.begins_with("First-active")
				if frame.motion_cue.contains("Collect") or frame.motion_cue.contains("Withdraw"):
					saw_recovery = true
				if not frame.has("effect") and sprite.has_node("AttackEffect"):
					check(not sprite.get_node("AttackEffect").visible, "Residual arc leaked past withdrawal")
			check(saw_release and saw_recovery, "Special lost its release or recovery in native playback")
	sprite.free()
