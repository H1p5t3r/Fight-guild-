extends RefCounted

# Real input-driven depletion, separate splat impact, then follow-up break.
static func configure(model: CombatModel) -> void:
	var data := model.data()
	data.recoveryRules.wallThreshold = 100
	for character in [4, 5]:
		for slot in [0, 4]:
			data.characters[character].moves[slot].launch = 0
			data.characters[character].moves[slot].knockdown = 0
	assert(model.load_data(data).is_empty())
	model.reset()

static func approach(model: CombatModel, side: int) -> void:
	for _tick in 220: model.step(2 if side > 0 else 1, 2 if side > 0 else 1)

static func splat(model: CombatModel, side: int) -> bool:
	var actor := 0 if side > 0 else 1
	var character := int(model.state().players[actor].character)
	for slot in [0, 4]:
		var input := 16 if slot == 0 else 16 | 4
		for _tick in int(model.move(character, slot).startup): model.step(input if actor == 0 else 0, input if actor == 1 else 0)
		while model.state().hitstop > 0: model.step(0, 0)
		model.step(0, 0) # The outgoing knockback actually collides on this tick.
		if slot == 0 and (model.state().wallHealth[1 if side > 0 else 0] != 0 or model.state().players[1 - actor].reaction == 4): return false
	return int(model.state().players[1 - actor].reaction) == 4

static func breach(model: CombatModel, side: int) -> bool:
	while model.state().hitstop > 0: model.step(0, 0)
	var actor := 0 if side > 0 else 1
	var character := int(model.state().players[actor].character)
	for _tick in int(model.move(character, 1).startup): model.step(32 if actor == 0 else 0, 32 if actor == 1 else 0)
	return int(model.state().wallBreakTime) > 0
