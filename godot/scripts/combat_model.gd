class_name CombatModel
extends RefCounted

const CHARACTERS := ["Anvil", "Hammer", "Smoke", "Tapper", "Shark", "Fillet"]
const DATA_VERSION := 7
const MOMENTUM_MAX := 10000
const INPUT_MASK := 4095
const BUTTONS := ["P", "K", "S", "Hs", "D"]
const MOVE_IDS := ["5P", "5K", "5S", "5Hs", "2P", "2K", "2S", "2Hs", "6P", "6K", "6S", "6Hs", "6D", "5D", "236P", "236S", "623Hs", "j.P", "j.K", "j.S", "j.Hs", "j.D", "2D", "4P+K", "6P+K", "236K", "236S>6S", "236S>2S", "214S", "j.214P", "214S>P", "j.214P>P"]
const FIELDS := ["button", "category", "direction", "motion", "air", "startup", "active", "recovery", "damage", "hitstun", "blockstun", "hitstop", "pushback", "reach", "bottom", "height", "specialCancel", "jumpCancel", "whiffCancel", "selfCancel", "advance", "simpleDirection", "simpleButton", "normalRoutes", "commandRoutes", "hitLevel", "chipDamage", "guardBreak", "counterHitstun", "counterHitstop", "reversalEligible", "hitboxBack", "airPushback", "blockPushback", "launch", "airLaunch", "knockdown", "knockdownFrames", "wakeupFrames", "wallDamage", "throwRange", "enabled", "artPose", "followFrom", "followFrom2", "followHit", "travelSpeed", "inertiaPercent", "pullFrames", "pullGap", "hitAngle"]
const MOVEMENT_FIELDS := ["forwardStyle", "walkSpeed", "runSpeed", "runAcceleration", "stepSpeed", "stepFrames", "backSpeed", "backFrames", "attackFriction"]
const RULES := ["buttonBuffer", "motionWindow", "motionGap"]
const MOMENTUM_RULES := ["movementGain", "attackGain", "blockedAttackGain", "damageTakenGain", "guardGain", "specialGain", "fdDrain", "fdBlockCost", "fdDamageCost", "fdPushPercent"]
const RECOVERY_RULES := ["gravityAfter", "gravityStep", "gravityCap", "wallThreshold", "wallRange", "wallDecayDelay", "wallDecay", "wallSplatFrames", "wallBreakFrames", "wallBreakDamage", "positiveFrames", "positiveGainPercent", "positiveRegen"]
const RULE_COUNT := 26 # Input, Momentum, then recovery/wall rules; matches fight::RULE_COUNT.
const STATE_FIELDS := ["x", "y", "facing", "health", "move", "age", "stun", "guarding", "contact", "combo", "event", "lastMove", "raw", "character", "simple", "momentum", "faultless", "blockReaction", "blockAge", "blockAdvantage", "guardBreak", "throwInvulnerable", "comboDisplay", "comboTime", "comboAge", "hitNotice", "hitNoticeTime", "reversalTime", "reversalInputAge", "posePhase", "poseIndex", "reaction", "knockdown", "recoveryTime", "comboReceived", "gravityPercent", "wallDamage", "wallSplatTime", "positiveTime", "vx", "running", "dashTicks", "pullTime", "pullOwner", "weaponBackX", "weaponBackY", "weaponTipX", "weaponTipY", "weaponVisible", "carryVx", "carryTime"]
var core := FightCore.new()
var config: PackedInt32Array = core.configuration()

func reset(characters: Array = [5, 4], simple: Array = [false, false]) -> void:
	core.reset(characters[0], characters[1], simple[0], simple[1])

func step(a: int, b: int) -> void:
	core.step(a, b)

func frame() -> int:
	return core.read_value(-1, 0)

func state_hash() -> int:
	return core.checksum()

func state() -> Dictionary:
	var result := {"frame": frame(), "remaining": core.read_value(-1, 1), "hitstop": core.read_value(-1, 2), "winner": core.read_value(-1, 3), "wallBreakTime": core.read_value(-1, 4), "wallBreakActor": core.read_value(-1, 5), "wallBreakSide": core.read_value(-1, 6), "stage": core.read_value(-1, 7), "wallBreakDuration": core.read_value(-1, 8), "players": []}
	for p in 2:
		var fighter := {}
		for i in STATE_FIELDS.size():
			fighter[STATE_FIELDS[i]] = core.read_value(p, i)
		result.players.append(fighter)
	return result

func move(character: int, slot: int) -> Dictionary:
	var result := {}
	for i in FIELDS.size():
		result[FIELDS[i]] = config[(character * MOVE_IDS.size() + slot) * FIELDS.size() + i]
	return result

func movement(character: int) -> Dictionary:
	var result := {}
	var offset := CHARACTERS.size() * MOVE_IDS.size() * FIELDS.size() + character * MOVEMENT_FIELDS.size()
	for i in MOVEMENT_FIELDS.size(): result[MOVEMENT_FIELDS[i]] = config[offset + i]
	return result

func data() -> Dictionary:
	var result := {"schema": DATA_VERSION, "coreVersion": DATA_VERSION, "inputRules": {}, "momentumRules": {}, "recoveryRules": {}, "characters": []}
	for i in RULES.size():
		result.inputRules[RULES[i]] = config[config.size() - RULE_COUNT + i]
	for i in MOMENTUM_RULES.size():
		result.momentumRules[MOMENTUM_RULES[i]] = config[config.size() - RULE_COUNT + RULES.size() + i]
	for i in RECOVERY_RULES.size():
		result.recoveryRules[RECOVERY_RULES[i]] = config[config.size() - RECOVERY_RULES.size() + i]
	for c in CHARACTERS.size():
		var character := {"name": CHARACTERS[c], "moves": [], "movement": movement(c)}
		for m in MOVE_IDS.size():
			var definition := {"id": MOVE_IDS[m]}
			definition.merge(move(c, m))
			character.moves.append(definition)
		result.characters.append(character)
	return result

static func valid_integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= -2147483648 and value <= 2147483647 and float(int(value)) == float(value)

func load_data(value: Variant) -> String:
	if not value is Dictionary or not valid_integer(value.get("schema")):
		return "Unsupported move data version."
	var version := int(value.schema)
	if version < 1 or version > DATA_VERSION or value.get("coreVersion") != version:
		return "Unsupported move data version."
	var characters: Variant = value.get("characters")
	var expected := 2 if version == 1 else CHARACTERS.size()
	var slots := 22 if version < 6 else 25 if version == 6 else MOVE_IDS.size()
	if not characters is Array or characters.size() != expected:
		return "Missing characters."
	# Start with shipped defaults, so older files gain the new universal move slots.
	var candidate := FightCore.new().configuration()
	for c in expected:
		if not characters[c] is Dictionary or characters[c].get("name") != CHARACTERS[c]:
			return "Character list differs from this build."
		var definitions: Variant = characters[c].get("moves")
		if not definitions is Array or definitions.size() != slots:
			return "Incomplete move list."
		for m in slots:
			if not definitions[m] is Dictionary or definitions[m].get("id") != MOVE_IDS[m]:
				return "Move slot IDs must match this build."
			var definition: Dictionary = definitions[m].duplicate()
			if not valid_integer(definition.get("category")) or not valid_integer(definition.get("damage")):
				return "Invalid move category or damage."
			if version < 3:
				if not valid_integer(definition.get("reserved")) or definition.reserved != 0:
					return "Invalid legacy reserved field."
				definition.chipDamage = maxi(1, int(definition.damage) / 10) if int(definition.category) in [2, 3] else 0
				definition.guardBreak = 0
			if version < 4:
				definition.counterHitstun = 4
				definition.counterHitstop = 3
				definition.reversalEligible = int(int(definition.category) in [2, 3])
			if version < 5: definition.hitboxBack = 1200
			if version < 6:
				# Keep authored displacement on hit and block; do not turn old normals into launchers.
				definition.airPushback = definition.get("pushback")
				definition.blockPushback = definition.get("pushback")
				definition.launch = 0
				definition.airLaunch = 850
				definition.knockdown = 0
				definition.knockdownFrames = 6
				definition.wakeupFrames = 8
				definition.wallDamage = clampi(int(definition.damage) * 3 + 80, 0, 5000)
				definition.throwRange = 2000
			if version < 7:
				for i in range(41, FIELDS.size()): definition[FIELDS[i]] = candidate[(c * MOVE_IDS.size() + m) * FIELDS.size() + i]
			for i in FIELDS.size():
				var field: String = FIELDS[i]
				if not valid_integer(definition.get(field)):
					return "Invalid integer for %s / %s." % [MOVE_IDS[m], field]
				if field == "startup" and definition[field] < 5:
					return "%s / %s: startup must be at least 5 frames." % [CHARACTERS[c], MOVE_IDS[m]]
				candidate[(c * MOVE_IDS.size() + m) * FIELDS.size() + i] = int(definition[field])
		if version >= 7:
			if not characters[c].get("movement") is Dictionary: return "Missing movement profile."
			var start := CHARACTERS.size() * MOVE_IDS.size() * FIELDS.size() + c * MOVEMENT_FIELDS.size()
			for i in MOVEMENT_FIELDS.size():
				var field: String = MOVEMENT_FIELDS[i]
				if not valid_integer(characters[c].movement.get(field)): return "Invalid movement: " + field
				candidate[start + i] = int(characters[c].movement[field])
	var offset := candidate.size() - RULE_COUNT
	for group in [["inputRules", RULES, 1], ["momentumRules", MOMENTUM_RULES, 3], ["recoveryRules", RECOVERY_RULES, 6]]:
		if version >= group[2]:
			if not value.get(group[0]) is Dictionary: return "Missing " + group[0]
			for i in group[1].size():
				var rule: String = group[1][i]
				if not valid_integer(value[group[0]].get(rule)): return "Invalid rule: " + rule
				candidate[offset + i] = int(value[group[0]][rule])
		offset += group[1].size()
	if not core.configure(candidate):
		return "A move value or rule is outside the supported range."
	config = core.configuration()
	return ""

func restore_defaults() -> void:
	core.restore_defaults()
	config = core.configuration()

func fingerprint() -> String:
	var hash_value: int = 2166136261
	for byte in JSON.stringify(data(), "", false).to_utf8_buffer():
		hash_value = ((hash_value ^ byte) * 16777619) & 0xffffffff
	return "%d-%08x-%08x" % [DATA_VERSION, core.collision_hash(), hash_value]

func save_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return "Could not write " + path
	file.store_string(JSON.stringify(data(), "\t", false))
	return ""

func load_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "Could not read " + path
	if file.get_length() > 1000000:
		return "Move files must be smaller than 1 MB."
	return load_data(JSON.parse_string(file.get_as_text()))
