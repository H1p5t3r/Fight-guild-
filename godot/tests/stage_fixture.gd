extends RefCounted

# Real input-driven splat + follow-up, on either boundary. Only the wall threshold
# and launch are simplified so this review does not depend on a long combo route.
static func configure(model: CombatModel) -> void:
	var data := model.data()
	data.recoveryRules.wallThreshold = 100
	for character in [4, 5]: data.characters[character].moves[0].launch = 1
	assert(model.load_data(data).is_empty())
	model.reset()

static func approach(model: CombatModel, side: int) -> void:
	for _tick in 220: model.step(2 if side > 0 else 1, 2 if side > 0 else 1)

static func splat(model: CombatModel, side: int) -> bool:
	var actor := 0 if side > 0 else 1
	var character := int(model.state().players[actor].character)
	for _tick in int(model.move(character, 0).startup): model.step(16 if actor == 0 else 0, 16 if actor == 1 else 0)
	return int(model.state().players[1 - actor].reaction) == 4

static func breach(model: CombatModel, side: int) -> bool:
	while model.state().hitstop > 0: model.step(0, 0)
	var actor := 0 if side > 0 else 1
	var character := int(model.state().players[actor].character)
	for _tick in int(model.move(character, 1).startup): model.step(32 if actor == 0 else 0, 32 if actor == 1 else 0)
	return int(model.state().wallBreakTime) > 0
