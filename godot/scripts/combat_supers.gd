class_name CombatSupers
extends RefCounted

static var roster: Array = []

static func info(character: int, slot: int) -> Dictionary:
	if roster.is_empty(): roster = JSON.parse_string(FileAccess.get_file_as_string("res://data/supers.json")).roster
	for item in roster:
		if int(item.character) == character and int(item.slot) == slot: return item
	return {}

static func title(character: int, slot: int) -> String:
	return str(info(character, slot).get("name", ""))

static func present(sprites: Array[Sprite2D], state: Dictionary, world_scale: float) -> void:
	if int(state.get("pairKind", 0)) != 8: return
	var owner := int(state.pairOwner)
	var receiver: Dictionary = state.players[1-owner].duplicate()
	var tick := int(state.pairClock)
	var total := maxi(1, int(state.pairTicks))
	var victim := sprites[1-owner]
	# These are strikes, not generic collar grabs. Keep the authored owner art
	# and show the receiver's actual chest/air recoil on the saved impact beats.
	var spec := SuperAnimation.profile(int(state.players[owner].character),int(state.pairMove))
	if tick >= total-8 and not spec.has("finish_receiver"):
		FighterArt.apply(victim, int(receiver.character), "knockdown", 0, world_scale, int(receiver.facing))
	else:
		var beat := 0 if tick < total*45/100 else total*45/100 if tick < total*78/100 else total*78/100
		receiver.reaction = 0
		receiver.stun = 1
		receiver.guarding = 0
		CombatReactions.apply(victim, receiver, {"flags": 8 if int(receiver.y) > 0 else 4, "age": tick-beat+int(spec.get("paired_recoil_age",0))}, world_scale)
	for child in victim.get_children():
		if child is Sprite2D: child.visible = false
	for p in 2: sprites[p].set_meta("super_role", "owner" if p == owner else "receiver")
