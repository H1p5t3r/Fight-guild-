class_name CombatModel
extends RefCounted

const CHARACTERS := ["Anvil", "Hammer", "Smoke", "Tapper", "Shark", "Fillet"]
const DATA_VERSION := 5
const MOMENTUM_MAX := 10000
const INPUT_MASK := 4095
const BUTTONS := ["P", "K", "S", "Hs", "D"]
const MOVE_IDS := ["5P", "5K", "5S", "5Hs", "2P", "2K", "2S", "2Hs", "6P", "6K", "6S", "6Hs", "6D", "5D", "236P", "236S", "623Hs", "j.P", "j.K", "j.S", "j.Hs", "j.D"]
const FIELDS := ["button", "category", "direction", "motion", "air", "startup", "active", "recovery", "damage", "hitstun", "blockstun", "hitstop", "pushback", "reach", "bottom", "height", "specialCancel", "jumpCancel", "whiffCancel", "selfCancel", "advance", "simpleDirection", "simpleButton", "normalRoutes", "commandRoutes", "hitLevel", "chipDamage", "guardBreak", "counterHitstun", "counterHitstop", "reversalEligible", "hitboxBack"]
const RULES := ["buttonBuffer", "motionWindow", "motionGap"]
const MOMENTUM_RULES := ["movementGain", "attackGain", "blockedAttackGain", "damageTakenGain", "guardGain", "specialGain", "fdDrain", "fdBlockCost", "fdDamageCost", "fdPushPercent"]
const RULE_COUNT := 13 # 3 input rules + 10 Momentum rules, matching fight::RULE_COUNT.
const STATE_FIELDS := ["x", "y", "facing", "health", "move", "age", "stun", "guarding", "contact", "combo", "event", "lastMove", "raw", "character", "simple", "momentum", "faultless", "blockReaction", "blockAge", "blockAdvantage", "guardBreak", "throwInvulnerable", "comboDisplay", "comboTime", "comboAge", "hitNotice", "hitNoticeTime", "reversalTime", "reversalInputAge", "posePhase", "poseIndex"]
var core := FightCore.new()
var config: PackedInt32Array = core.configuration()

func reset(characters: Array = [0, 1], simple: Array = [false, false]) -> void:
	core.reset(characters[0], characters[1], simple[0], simple[1])

func step(a: int, b: int) -> void:
	core.step(a, b)

func frame() -> int:
	return core.read_value(-1, 0)

func state_hash() -> int:
	return core.checksum()

func state() -> Dictionary:
	var result := {"frame": frame(), "remaining": core.read_value(-1, 1), "hitstop": core.read_value(-1, 2), "winner": core.read_value(-1, 3), "players": []}
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

func data() -> Dictionary:
	var result := {"schema": DATA_VERSION, "coreVersion": DATA_VERSION, "inputRules": {}, "momentumRules": {}, "characters": []}
	for i in RULES.size():
		result.inputRules[RULES[i]] = config[config.size() - RULE_COUNT + i]
	for i in MOMENTUM_RULES.size():
		result.momentumRules[MOMENTUM_RULES[i]] = config[config.size() - MOMENTUM_RULES.size() + i]
	for c in CHARACTERS.size():
		var character := {"name": CHARACTERS[c], "moves": []}
		for m in MOVE_IDS.size():
			var definition := {"id": MOVE_IDS[m]}
			definition.merge(move(c, m))
			character.moves.append(definition)
		result.characters.append(character)
	return result

static func valid_integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= -2147483648 and value <= 2147483647 and float(int(value)) == float(value)

func load_data(value: Variant) -> String:
	if not value is Dictionary:
		return "Unsupported move data version."
	var legacy: bool = valid_integer(value.get("schema")) and int(value.schema) in [1, 2, 3, 4] and value.schema == value.get("coreVersion")
	if not legacy and (value.get("schema") != DATA_VERSION or value.get("coreVersion") != DATA_VERSION):
		return "Unsupported move data version."
	var characters: Variant = value.get("characters")
	var expected := 2 if value.get("schema") == 1 else CHARACTERS.size()
	if not characters is Array or characters.size() != expected or not value.get("inputRules") is Dictionary:
		return "Missing characters or input rules."
	var candidate := PackedInt32Array()
	for c in expected:
		if not characters[c] is Dictionary or characters[c].get("name") != CHARACTERS[c]:
			return "Character list differs from this build."
		var definitions: Variant = characters[c].get("moves")
		if not definitions is Array or definitions.size() != MOVE_IDS.size():
			return "Incomplete move list."
		for m in MOVE_IDS.size():
			if not definitions[m] is Dictionary or definitions[m].get("id") != MOVE_IDS[m]:
				return "Move slot IDs must match this build."
			for field in FIELDS:
				if legacy and field == "hitboxBack":
					candidate.append(1200) # Preserve the previous 12px origin for saved move edits.
					continue
				if value.schema < 4 and field in ["counterHitstun", "counterHitstop", "reversalEligible"]:
					candidate.append(4 if field == "counterHitstun" else 3 if field == "counterHitstop" else int(int(definitions[m].category) in [2, 3]))
					continue
				if value.schema < 3 and field == "guardBreak":
					candidate.append(0)
					continue
				if value.schema < 3 and field == "chipDamage":
					if not valid_integer(definitions[m].get("reserved")) or definitions[m].reserved != 0:
						return "Invalid legacy reserved field."
					var chip: int = maxi(1, int(definitions[m].damage) / 10) if int(definitions[m].category) in [2, 3] else 0
					candidate.append(chip)
					continue
				if not valid_integer(definitions[m].get(field)):
					return "Invalid integer for %s / %s." % [MOVE_IDS[m], field]
				if field == "startup" and definitions[m][field] < 5:
					return "%s / %s: startup must be at least 5 frames." % [CHARACTERS[c], MOVE_IDS[m]]
				candidate.append(int(definitions[m][field]))
	# Old two-fighter saves keep their edits; newly added fighters start from defaults.
	var defaults := FightCore.new().configuration()
	if expected < CHARACTERS.size():
		candidate.append_array(defaults.slice(candidate.size(), defaults.size() - RULE_COUNT))
	for rule in RULES:
		if not valid_integer(value.inputRules.get(rule)):
			return "Invalid input rule: " + rule
		candidate.append(int(value.inputRules[rule]))
	if value.schema < 3:
		candidate.append_array(defaults.slice(defaults.size() - MOMENTUM_RULES.size()))
	else:
		if not value.get("momentumRules") is Dictionary:
			return "Missing Momentum rules."
		for rule in MOMENTUM_RULES:
			if not valid_integer(value.momentumRules.get(rule)):
				return "Invalid Momentum rule: " + rule
			candidate.append(int(value.momentumRules[rule]))
	if not core.configure(candidate):
		return "A move value or input rule is outside the supported range."
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
