class_name ReactionFixtures
extends RefCounted

# Isolated review fixtures only. Never saved to workshop data or game defaults.
static func contact(character: int, family: String, facing: int = 1) -> CombatModel:
	var model := CombatModel.new()
	model.reset([0, character])
	model.core.preview_place(0, 50000 - facing * 10000, 0, 0)
	model.core.preview_place(1, 50000 + facing * 10000, 12000 if family == "air" else 0, 0)
	var data := model.data()
	var move: Dictionary = data.characters[0].moves[0]
	for field in ["pushback", "airPushback", "groundHitSpeed", "airHitSpeed", "launch", "airLaunch", "groundBounce", "wallBounce", "knockdown", "counterSlowFrames", "advance"]: move[field] = 0
	move.startup = 5; move.active = 1; move.recovery = 20
	move.damage = 1; move.hitstun = 40; move.hitstop = 8
	move.hitboxBack = 0; move.reach = 40000; move.height = 600
	move.hitboxTimeline = {"multiHit": false, "keys": []}
	assert(model.load_data(data).is_empty())
	model.core.preview_begin(0, 0)
	for tick in 3: model.step(0, 0)
	var boxes: PackedInt32Array = model.core.boxes(1, 0)
	var region := {"legs": 0, "chest": 1, "head": 2, "air": 1}[family] as int
	var bottom := int(boxes[region * 4 + 1])
	var top := int(boxes[region * 4 + 3])
	var fighter: Dictionary = model.state().players[1]
	var drift := int(fighter.vy) - int(model.movement(character).gravity) if family == "air" else 0
	move.bottom = int(lerpf(bottom, top, 0.7 if family == "head" else 0.5)) + drift - 300
	assert(model.load_data(data).is_empty())
	for tick in 3:
		model.step(0, 0)
		if not model.cues.reaction_at(model.frame(), 1).is_empty(): return model
	return model
