class_name PairedThrowFixtures
extends RefCounted

# Native review/test setup only. Use the current shipped move stats unchanged.
static func create() -> CombatModel:
	var model := CombatModel.new()
	var batch: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	assert(model.load_file("res://data/workshop/" + str(batch.file)).is_empty())
	return model

static func prepare(model: CombatModel, attacker: int, victim: int, slot: int, owner: int = 0, facing: int = 1, middle: int = 50000) -> void:
	model.reset([attacker, victim] if owner == 0 else [victim, attacker])
	model.core.preview_place(owner, middle - facing * 3000, 0, 0)
	model.core.preview_place(1 - owner, middle + facing * 3000, 0, 0)
	model.step(0, 0)
	if attacker == 5 and slot in [45, 46]: assert(model.core.preview_status(1 - owner, 1, 59))
	if attacker == 5 and slot == 13: assert(model.core.preview_status(1 - owner, 0, 120))
