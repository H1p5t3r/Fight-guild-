class_name LegacyFixture
extends RefCounted
# Archived behavior is checked independently of the v1-kit acceptance suite.
static func strip_extensions(data: Dictionary) -> void:
	for character in data.characters:
		character.erase("extensions")
		if character.moves.size() == 47: character.moves.resize(45)
		for action in character.moves: action.erase("extensions")
static func reset(model: CombatModel) -> void:
	model.restore_defaults()
	var data := model.data()
	data.comboRules.comboPhysics = 0 # Historical distance-budget/gatling fixture.
	var additions: Array = data.characters[5].moves.slice(45)
	for action in additions:
		action.erase("extensions")
		action.enabled = 0
	data.characters[5] = JSON.parse_string(FileAccess.get_file_as_string("res://data/legacy_fillet_v22.json"))
	data.characters[5].moves.append_array(additions)
	for action in data.characters[5].moves:
		action.tetherDuration = 180
		action.tetherRange = 45000
		action.tetherGap = 6000
		action.comboDecay = 5
		action.starterDecay = 0
		action.groundHitSpeed = ceili(float(action.pushback) / 6.0)
		action.airHitSpeed = ceili(float(action.airPushback) / 6.0)
	assert(model.load_data(data).is_empty())
static func create() -> CombatModel:
	var model := CombatModel.new()
	reset(model)
	return model
