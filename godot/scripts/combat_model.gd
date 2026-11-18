class_name CombatModel
extends RefCounted

const CHARACTERS := ["Anvil", "Hammer", "Smoke", "Tapper", "Shark", "Fillet"]
const DATA_VERSION := 22

static func startup_minimum(move: Dictionary) -> int:
	if move.get("category") == 4: return 2
	return 3 if move.get("button") == 0 and move.get("category") in [0, 1] else 5

static func variant_startup_minimum(move: Dictionary) -> int:
	return 2 if move.get("mechanic") == 2 else 5

static func block_advantage(move: Dictionary) -> int:
	var start := 1
	var stun := int(move.blockstun)
	var seen := {1: true}
	var track: Dictionary = move.get("hitboxTimeline", {})
	if track.get("multiHit", false):
		for key in track.get("keys", []):
			if int(key.frame) > int(move.active): break
			if key.boxes is Array and key.boxes.is_empty(): continue
			if not seen.has(int(key.hit)):
				start = int(key.frame)
				stun = int(move.blockstun) if int(key.blockstun) < 0 else int(key.blockstun)
				seen[int(key.hit)] = true
	return stun - (int(move.active) - start + int(move.recovery))
const HIT_KEY_FIELDS := 23
const HIT_TRACK_FIELDS := 738
const HIT_OVERRIDES := ["damage", "hitstun", "blockstun", "hitstop"]
const HURT_PHASES := ["windup", "active", "recovery"]
const HURT_REGIONS := ["legs", "torsoArms", "head", "extension"]
const HURT_FIELDS := 17
const MOMENTUM_MAX := 10000
const INPUT_MASK := 4095
const BUTTONS := ["P", "K", "S", "Hs", "D"]
const MOVE_IDS := ["5P", "5K", "5S", "5Hs", "2P", "2K", "2S", "2Hs", "6P", "6K", "6S", "6Hs", "6D", "5D", "236P", "236S", "623Hs", "j.P", "j.K", "j.S", "j.Hs", "j.D", "2D", "4P+K", "6P+K", "236K", "236S>6S", "236S>2S", "214S", "j.214P", "214S>P", "j.214P>P","c.S","[S/Hs]","[S/Hs]>attack","st.P","st.K","st.S","st.Hs","st.2D","st.236D","j.4P+K","j.6P+K","6[Hs]","5[D]"]
# Smear slots are reserved for schema compatibility; transition smearing is removed.
const FIELDS := ["button", "category", "direction", "motion", "air", "startup", "active", "recovery", "damage", "hitstun", "blockstun", "hitstop", "pushback", "reach", "bottom", "height", "specialCancel", "jumpCancel", "whiffCancel", "selfCancel", "advance", "simpleDirection", "simpleButton", "normalRoutes", "commandRoutes", "hitLevel", "chipDamage", "guardBreak", "counterHitstun", "counterHitstop", "reversalEligible", "hitboxBack", "airPushback", "blockPushback", "launch", "airLaunch", "knockdown", "knockdownFrames", "wakeupFrames", "wallDamage", "throwRange", "enabled", "artPose", "followFrom", "followFrom2", "followHit", "travelSpeed", "inertiaPercent", "pullFrames", "pullGap", "hitAngle", "normalCancelStart", "normalCancelEnd", "specialCancelStart", "specialCancelEnd", "jumpCancelStart", "jumpCancelEnd", "followCancelStart", "followCancelEnd", "cancelOn", "starterProration", "comboScaling", "minimumDamage", "landingRecovery", "attackLevel", "counterTier", "counterVulnerable", "counterFreezeFrames", "counterSlowFrames", "projectileKind", "projectileSpawnFrame", "projectileSpeedX", "projectileSpeedY", "projectileGravity", "projectileLife", "projectileOffsetX", "projectileOffsetY", "projectileWidth", "projectileHeight", "projectileHits", "projectileRehit", "projectileDurability", "projectilePersist", "projectileMelee", "smearMode", "smearPart", "smearStretch", "smearFrame1", "smearFrame2", "smearFrame3", "smearFrame4", "hurtMaskWindup", "hurtMaskActive", "hurtMaskRecovery","mechanic","tetherSpeed","tetherFrames","bleedInitial","bleedTickDamage","bleedTickFrames","bleedDuration","bleedBlockPercent","bleedCap","variantStartup","variantActive","variantRecovery","variantDamage","variantRange","variantSpeed","variantLift","variantHitstun","variantKnockdown","stanceRequired","stanceChange","actionType","holdFollow","holdFrame","holdButton","guardFollow","proximityMove","proximityRange","startupTravel","diveSpeedX","diveSpeedY","groundBounce","wallBounce","crumpleFrames","airCounterKnockdown","hurtWindowStart","hurtWindowEnd","hurtWindowMask","semiAirStart","semiAirEnd","armorFrames","armorHits","grabFrames","finishArtPose","finishArtFrame"]
const MOVEMENT_FIELDS := ["forwardStyle", "walkSpeed", "runSpeed", "runAcceleration", "stepSpeed", "stepFrames", "backSpeed", "backFrames", "attackFriction", "backStyle", "backWalkSpeed", "backRunSpeed", "jumpSpeed", "jumpForwardSpeed", "jumpBackSpeed", "gravity", "airJumps", "prejumpFrames", "airDashEnabled", "airBackdashEnabled", "airDashStyle", "airBackdashStyle", "airDashSpeed", "airBackdashSpeed", "airDashFrames", "airBackdashFrames", "airDashUses", "hoverHeight", "hoverRiseSpeed", "teleportDistance", "backTeleportDistance", "teleportStartup", "fdEnabled", "fdPushPercent", "fdDrain", "fdAirDrain", "fdBlockCost", "smearMode", "smearPart", "smearStretch", "airDashPauseFrames", "airBackdashPauseFrames"]
const RULES := ["buttonBuffer", "motionWindow", "motionGap"]
const MOMENTUM_RULES := ["movementGain", "attackGain", "blockedAttackGain", "damageTakenGain", "guardGain", "specialGain", "fdDrain", "fdBlockCost", "fdDamageCost", "fdPushPercent"]
const RECOVERY_RULES := ["gravityAfter", "gravityStep", "gravityCap", "wallThreshold", "wallRange", "wallDecayDelay", "wallDecay", "wallSplatFrames", "wallBreakFrames", "wallBreakDamage", "positiveFrames", "positiveGainPercent", "positiveRegen"]
const TUNING_RULES := ["fdAirDrain", "fdLevelCost", "cornerPushTransfer", "wallMidCap", "groundedWallPrime", "blockCarryover", "throwGraceFrames", "airLandingFrames", "repeatAfter", "repeatGravityStep"]
const JUMP_RULES := ["prejumpFrames", "emptyLandingFrames"]
const RULE_COUNT := 38 # Input, Momentum, recovery/walls, tuning, then jump rules.
const STATE_FIELDS := ["x", "y", "facing", "health", "move", "age", "stun", "guarding", "contact", "combo", "event", "lastMove", "raw", "character", "simple", "momentum", "faultless", "blockReaction", "blockAge", "blockAdvantage", "guardBreak", "throwInvulnerable", "comboDisplay", "comboTime", "comboAge", "hitNotice", "hitNoticeTime", "reversalTime", "reversalInputAge", "posePhase", "poseIndex", "reaction", "knockdown", "recoveryTime", "comboReceived", "gravityPercent", "wallDamage", "wallSplatTime", "positiveTime", "vx", "running", "dashTicks", "pullTime", "pullOwner", "weaponBackX", "weaponBackY", "weaponTipX", "weaponTipY", "weaponVisible", "carryVx", "carryTime", "landingTime", "throwGrace", "cancelMask", "inputAge", "lastDamage", "damageScale", "starterProration", "comboScale", "counterTier", "repeatGravity", "lastBaseDamage", "prejumpTime", "counterSlowTime", "counterSlowHeld", "knockbackLeft", "hitGroups", "vy", "dashKind", "dashAge", "airDashUsed", "airJumpUsed", "teleported", "contactCount","variant","tetherSource","tetherUsed","bleedSource","bleedTime","bleedClock","greyLife","stance","guardButton","armorLeft","groundBounce","wallBounce","crumpleTime","grabTime","grabOwner","idleTime","dashPause"]
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
	var result := {"frame": frame(), "remaining": core.read_value(-1, 1), "hitstop": core.read_value(-1, 2), "winner": core.read_value(-1, 3), "wallBreakTime": core.read_value(-1, 4), "wallBreakActor": core.read_value(-1, 5), "wallBreakSide": core.read_value(-1, 6), "stage": core.read_value(-1, 7), "wallBreakDuration": core.read_value(-1, 8), "impactTime": core.read_value(-1, 9), "impactDuration": core.read_value(-1, 10), "impactActor": core.read_value(-1, 11), "impactTier": core.read_value(-1, 12), "impactX": core.read_value(-1, 13), "impactY": core.read_value(-1, 14), "wallBreakX": [core.read_value(-1, 15), core.read_value(-1, 16)], "wallBreakY": [core.read_value(-1, 17), core.read_value(-1, 18)], "wallHealth": [core.read_value(-1, 19), core.read_value(-1, 20)], "foregroundPlayer": core.read_value(-1, 21), "players": []}
	for p in 2:
		var fighter := {}
		for i in STATE_FIELDS.size():
			fighter[STATE_FIELDS[i]] = core.read_value(p, i)
		result.players.append(fighter)
	result["projectiles"] = []
	for i in 16:
		if core.read_value(-2-i, 0) <= 0: continue
		var projectile := {}
		var keys := ["life", "owner", "x", "y", "width", "height", "kind", "facing", "move", "vx", "vy", "age"]
		for field in keys.size(): projectile[keys[field]] = core.read_value(-2-i, field)
		result.projectiles.append(projectile)
	return result

func move(character: int, slot: int) -> Dictionary:
	var result := {}
	for i in FIELDS.size():
		result[FIELDS[i]] = config[(character * MOVE_IDS.size() + slot) * FIELDS.size() + i]
	result.hurtboxes = {}
	for p in HURT_PHASES.size():
		var start := hurt_offset(character, slot, p)
		if config[start] == 0: continue
		var boxes := {}
		for region in config[start]:
			var rect := []
			for edge in 4: rect.append(config[start + 1 + region * 4 + edge])
			boxes[HURT_REGIONS[region]] = rect
		result.hurtboxes[HURT_PHASES[p]] = boxes
	result.hitboxTimeline = {"multiHit": false, "keys": []}
	var hit_start := hit_offset(character, slot)
	result.hitboxTimeline.multiHit = config[hit_start] != 0
	for i in config[hit_start + 1]:
		var at := hit_start + 2 + i * HIT_KEY_FIELDS
		var key := {"frame": config[at], "hit": config[at + 1], "boxes": null}
		if config[at + 2] >= 0:
			key.boxes = []
			for b in config[at + 2]:
				key.boxes.append(Array(config.slice(at + 7 + b * 4, at + 11 + b * 4)))
		for field in HIT_OVERRIDES.size(): key[HIT_OVERRIDES[field]] = config[at + 3 + field]
		result.hitboxTimeline["keys"].append(key)
	return result

static func hit_offset(character: int, slot: int) -> int:
	return CHARACTERS.size() * (MOVE_IDS.size() * (FIELDS.size() + HURT_PHASES.size() * HURT_FIELDS) + MOVEMENT_FIELDS.size()) + (character * MOVE_IDS.size() + slot) * HIT_TRACK_FIELDS

static func load_hitboxes(value: Variant, candidate: PackedInt32Array, character: int, slot: int) -> String:
	if not value is Dictionary or not value.get("multiHit") is bool or not value.get("keys") is Array or value["keys"].size() > 32:
		return "Invalid hitbox timeline."
	var start := hit_offset(character, slot)
	candidate[start] = int(value.multiHit)
	candidate[start + 1] = value["keys"].size()
	var previous := 0
	for i in value["keys"].size():
		var key: Variant = value["keys"][i]
		if not key is Dictionary or not valid_integer(key.get("frame")) or not valid_integer(key.get("hit")) or key.frame <= previous or key.frame > 120 or key.hit < 1 or key.hit > 32:
			return "Hitbox keys need increasing active frames and hit numbers 1–32."
		previous = int(key.frame)
		if not key.has("boxes") or (key.boxes != null and (not key.boxes is Array or key.boxes.size() > 4)):
			return "A hitbox key supports base geometry or up to four boxes."
		var at: int = start + 2 + int(i) * HIT_KEY_FIELDS
		candidate[at] = int(key.frame)
		candidate[at + 1] = int(key.hit)
		candidate[at + 2] = -1 if key.boxes == null else key.boxes.size()
		for field in HIT_OVERRIDES.size():
			if not valid_integer(key.get(HIT_OVERRIDES[field])): return "Invalid hit timing override."
			candidate[at + 3 + field] = int(key[HIT_OVERRIDES[field]])
		if key.boxes == null: continue
		for b in key.boxes.size():
			if not key.boxes[b] is Array or key.boxes[b].size() != 4: return "Hitboxes need four edges."
			for edge in 4:
				if not valid_integer(key.boxes[b][edge]): return "Invalid hitbox coordinate."
				candidate[at + 7 + b * 4 + edge] = int(key.boxes[b][edge])
	return ""

static func hurt_offset(character: int, slot: int, phase: int) -> int:
	return CHARACTERS.size() * (MOVE_IDS.size() * FIELDS.size() + MOVEMENT_FIELDS.size()) + ((character * MOVE_IDS.size() + slot) * HURT_PHASES.size() + phase) * HURT_FIELDS

static func load_hurtboxes(value: Variant, candidate: PackedInt32Array, character: int, slot: int) -> String:
	if not value is Dictionary: return "Missing attack hurtbox profiles."
	for phase in value:
		if not phase in HURT_PHASES: return "Unknown hurtbox phase."
		var boxes: Variant = value[phase]
		if not boxes is Dictionary: return "Invalid hurtbox profile."
		for region in boxes:
			if not region in HURT_REGIONS: return "Only four body hurtbox regions are allowed."
		for region in HURT_REGIONS.slice(0, 3):
			if not boxes.has(region): return "Hurtboxes require legs, torso and arms, and head."
		var start := hurt_offset(character, slot, HURT_PHASES.find(phase))
		candidate[start] = boxes.size()
		for region in HURT_REGIONS:
			if not boxes.has(region): continue
			var rect: Variant = boxes[region]
			if not rect is Array or rect.size() != 4: return "Hurtboxes need four edges."
			for edge in 4:
				if not valid_integer(rect[edge]): return "Invalid hurtbox coordinate."
				candidate[start + 1 + HURT_REGIONS.find(region) * 4 + edge] = int(rect[edge])
	return ""

func movement(character: int) -> Dictionary:
	var result := {}
	var offset := CHARACTERS.size() * MOVE_IDS.size() * FIELDS.size() + character * MOVEMENT_FIELDS.size()
	for i in MOVEMENT_FIELDS.size(): result[MOVEMENT_FIELDS[i]] = config[offset + i]
	return result

func data() -> Dictionary:
	var result := {"schema": DATA_VERSION, "coreVersion": DATA_VERSION, "inputRules": {}, "momentumRules": {}, "recoveryRules": {}, "tuningRules": {}, "jumpRules": {}, "characters": []}
	for i in RULES.size():
		result.inputRules[RULES[i]] = config[config.size() - RULE_COUNT + i]
	for i in MOMENTUM_RULES.size():
		result.momentumRules[MOMENTUM_RULES[i]] = config[config.size() - RULE_COUNT + RULES.size() + i]
	for i in RECOVERY_RULES.size():
		result.recoveryRules[RECOVERY_RULES[i]] = config[config.size() - RULE_COUNT + RULES.size() + MOMENTUM_RULES.size() + i]
	for i in TUNING_RULES.size():
		result.tuningRules[TUNING_RULES[i]] = config[config.size() - TUNING_RULES.size() - JUMP_RULES.size() + i]
	for i in JUMP_RULES.size():
		result.jumpRules[JUMP_RULES[i]] = config[config.size() - JUMP_RULES.size() + i]
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
	var slots := 22 if version < 6 else 25 if version == 6 else 32 if version < 18 else 43 if version == 18 else MOVE_IDS.size()
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
		if version < 18:
			var additions: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/stance_fields.json"))
			for slot in MOVE_IDS.size():
				for field in additions:
					candidate[(c * MOVE_IDS.size() + slot) * FIELDS.size() + FIELDS.find(field.key)] = int(field.default)
				if slot >= 32: candidate[(c * MOVE_IDS.size() + slot) * FIELDS.size() + FIELDS.find("enabled")] = 0
		if version < 19:
			for slot in range(43, MOVE_IDS.size()): candidate[(c * MOVE_IDS.size() + slot) * FIELDS.size() + FIELDS.find("enabled")] = 0
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
				for i in range(41, 51): definition[FIELDS[i]] = candidate[(c * MOVE_IDS.size() + m) * FIELDS.size() + i]
			if version < 8:
				var legacy_defaults := [1, 0, 1, 0, 1, 0, 1, 0, 7, 100, 0, 0, 0, -1, -1, 3]
				for i in legacy_defaults.size(): definition[FIELDS[51+i]] = legacy_defaults[i]
			if version < 10:
				definition.counterFreezeFrames = -1
				definition.counterSlowFrames = 0
			if version < 20 and definition.category == 4 and definition.get("motion") == 0:
				definition.startup = 2
			for i in FIELDS.size():
				if (version < 15 and i >= 69) or (version < 16 and i >= 91) or (version < 17 and i >= 94) or (version < 18 and i >= 112): continue
				var field: String = FIELDS[i]
				if not valid_integer(definition.get(field)):
					return "Invalid integer for %s / %s." % [MOVE_IDS[m], field]
				if field == "startup" and definition[field] < startup_minimum(definition):
					return "%s / %s: startup must be at least %d frames." % [CHARACTERS[c], MOVE_IDS[m], startup_minimum(definition)]
				if field == "variantStartup" and definition[field] < variant_startup_minimum(definition):
					return "%s / %s: follow-up startup must be at least %d frames." % [CHARACTERS[c], MOVE_IDS[m], variant_startup_minimum(definition)]
				candidate[(c * MOVE_IDS.size() + m) * FIELDS.size() + i] = int(definition[field])
			if version >= 13:
				var hurt_error := load_hurtboxes(definition.get("hurtboxes"), candidate, c, m)
				if not hurt_error.is_empty(): return "%s / %s: %s" % [CHARACTERS[c], MOVE_IDS[m], hurt_error]
			if version >= 14:
				var hit_error := load_hitboxes(definition.get("hitboxTimeline"), candidate, c, m)
				if not hit_error.is_empty(): return "%s / %s: %s" % [CHARACTERS[c], MOVE_IDS[m], hit_error]
			else:
				load_hitboxes({"multiHit": false, "keys": []}, candidate, c, m)
		if version >= 7:
			if not characters[c].get("movement") is Dictionary: return "Missing movement profile."
			var start := CHARACTERS.size() * MOVE_IDS.size() * FIELDS.size() + c * MOVEMENT_FIELDS.size()
			for i in MOVEMENT_FIELDS.size():
				if version < 15 and i >= 9: continue
				if version < 22 and i >= 40: continue
				var field: String = MOVEMENT_FIELDS[i]
				if not valid_integer(characters[c].movement.get(field)): return "Invalid movement: " + field
				candidate[start + i] = int(characters[c].movement[field])
	var offset := candidate.size() - RULE_COUNT
	for group in [["inputRules", RULES, 1], ["momentumRules", MOMENTUM_RULES, 3], ["recoveryRules", RECOVERY_RULES, 6], ["tuningRules", TUNING_RULES, 8], ["jumpRules", JUMP_RULES, 9]]:
		if version >= group[2]:
			if not value.get(group[0]) is Dictionary: return "Missing " + group[0]
			for i in group[1].size():
				var rule: String = group[1][i]
				if not valid_integer(value[group[0]].get(rule)): return "Invalid rule: " + rule
				candidate[offset + i] = int(value[group[0]][rule])
		offset += group[1].size()
	if version < 8:
		# Retain saved FD costs and gravity behavior; new editor fields remain available.
		candidate[candidate.size() - RULE_COUNT + 26] = candidate[candidate.size() - RULE_COUNT + 9]
		candidate[candidate.size() - RULE_COUNT + 27] = 0
		candidate[candidate.size() - RULE_COUNT + 35] = 0
	if version < 9:
		candidate[candidate.size() - JUMP_RULES.size()] = 0 # Preserve legacy instant takeoff.
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
	if file.get_length() > 32 * 1024 * 1024:
		return "Move files must be smaller than 32 MB."
	return load_data(JSON.parse_string(file.get_as_text()))
