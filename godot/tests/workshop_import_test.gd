extends SceneTree

# Run against JSON downloaded by the real browser editor, not a hand-written
# native fixture: bash scripts/godot.sh --headless --script
# tests/workshop_import_test.gd -- /absolute/path/to/workshop-browser-roundtrip.json
var failures := 0

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr(description)

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("Pass the browser workshop's exported JSON path.")
		quit(1)
		return
	var exported: Variant = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	if not exported is Dictionary:
		printerr("Could not read the workshop export.")
		quit(1)
		return
	var model := CombatModel.new()
	var error := model.load_data(exported)
	check(error.is_empty(), "Browser JSON was rejected by Godot: " + error)
	var actual := model.data()
	for group in ["inputRules", "momentumRules", "recoveryRules", "tuningRules", "jumpRules"]:
		for field in actual[group]:
			check(actual[group][field] == exported[group][field], "Global rule changed: %s/%s" % [group, field])
	for c in CombatModel.CHARACTERS.size():
		for field in CombatModel.MOVEMENT_FIELDS:
			check(actual.characters[c].movement[field] == exported.characters[c].movement[field], "Movement profile changed: %s/%s" % [c, field])
		for m in CombatModel.MOVE_IDS.size():
			for field in CombatModel.FIELDS:
				check(actual.characters[c].moves[m][field] == exported.characters[c].moves[m][field], "Imported field differs: %s/%s/%s" % [c, m, field])
	check(model.move(5, 0).startup == 7 and model.move(5, 0).damage == 44 and model.move(5, 0).reach == 9613, "Fillet browser edits did not arrive")
	check(model.move(4, 28).airLaunch == 1300 and model.move(4, 28).normalRoutes == 1, "Shark browser edits did not arrive")
	check(exported.has("_moveWorkshop"), "Companion art brief was not included")
	var fingerprint := model.fingerprint()
	var invalid: Dictionary = exported.duplicate(true)
	invalid.characters[5].moves[31].startup = 4
	check(not model.load_data(invalid).is_empty() and model.fingerprint() == fingerprint, "Invalid import was not atomic")
	print("Workshop browser → Godot round trip: %d failures" % failures)
	quit(1 if failures else 0)
