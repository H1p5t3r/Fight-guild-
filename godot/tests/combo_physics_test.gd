extends SceneTree
var failures := 0
func check(ok: bool, text: String) -> void:
	if not ok: failures += 1; push_error(text)
func _initialize() -> void:
	var model := CombatModel.new()
	var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/2026-11-20-fillet-otg/FightGuild-Fillet-OTG.json"))
	check(model.load_data(old).is_empty(), "Schema 25 imports")
	var data := model.data()
	check(data.schema == 26 and data.comboRules.comboPhysics == 1, "Modern physics enabled on migration")
	for group in ["tuningRules", "recoveryRules"]:
		for key in old[group]: check(data[group][key] == old[group][key], "Other saved rules preserved")
	for c in 6:
		for m in 47:
			check(data.characters[c].moves[m].groundHitSpeed == ceili(float(old.characters[c].moves[m].pushback) / 6.0), "Ground velocity migration")
			check(data.characters[c].moves[m].airHitSpeed == ceili(float(old.characters[c].moves[m].airPushback) / 6.0), "Air velocity migration")
	check(model.load_data(data).is_empty() and model.data() == data, "Schema 26 round trip")
	var fingerprint := model.fingerprint()
	var bad := data.duplicate(true)
	bad.comboRules.airHitDrag = 101
	check(not model.load_data(bad).is_empty() and model.fingerprint() == fingerprint, "Invalid shared rule atomic")
	model.reset([4,2])
	model.core.preview_place(0,42000,0,0)
	model.core.preview_place(1,48500,0,0)
	model.step(64,0)
	for i in 40:
		if model.state().players[0].contactCount: break
		model.step(0,0)
	check(model.state().players[1].comboDecay == 5, "Native decay diagnostic")
	var saved := model.core.snapshot()
	for i in 50: model.step(0,0)
	var checksum := model.state_hash()
	check(model.core.restore(saved), "New snapshot accepted")
	for i in 50: model.step(0,0)
	check(model.state_hash() == checksum, "Native rollback identical")
	print("Godot combo physics, migration and rollback: %d failures" % failures)
	quit(1 if failures else 0)
