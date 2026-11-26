class_name CombatOverhead
extends RefCounted

# Dust-inspired warning, never a contact event. The action's saved age owns the
# animation, so hitstop, pause and rollback need no extra emitter state.
const DIRECTORY := "res://assets/effects/overhead-v1/"
static var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY + "manifest.json"))
static var textures := {}

static func value(model: CombatModel, base: int, field: String) -> int:
	return model.config[base + CombatModel.FIELDS.find(field)]

static func describe(model: CombatModel, state: Dictionary, reduced: bool = false) -> Array:
	var result := []
	if state.is_empty() or int(state.get("wallBreakTime", 0)) > 0 or int(state.get("pairKind", 0)) > 0: return result
	for p in state.players.size():
		var fighter: Dictionary = state.players[p]
		var move := int(fighter.move)
		if move < 0 or int(fighter.reaction) != 0 or int(fighter.stun) > 0 or int(fighter.contact) > 0 or int(fighter.variant) != 0: continue
		var character := int(fighter.character)
		var base := (character * CombatModel.MOVE_IDS.size() + move) * CombatModel.FIELDS.size()
		if value(model, base, "hitLevel") != 2 or value(model, base, "enabled") == 0: continue
		# Throws/captures and non-striking movement cannot be defended by high
		# guard, even if their dormant guard-level field is edited to overhead.
		var action := value(model, base, "actionType")
		if value(model, base, "category") == 4 or action in [1, 7, 8, 10, 11] or value(model, base, "mechanic") in [4, 5]: continue
		if model.config[model.extension_offset(character, -1)] == 1 and model.config[model.extension_offset(character, move) + 1] != 0: continue
		var age := int(fighter.age)
		var startup := value(model, base, "startup")
		# Native charge anticipation extends startup while its button is held.
		if action == 5 and int(fighter.guardButton) != 0: startup = maxi(startup, age + 2)
		var active := value(model, base, "active")
		if age >= startup + mini(2, active): continue
		var releasing := age >= startup
		result.append({"player":p, "character":character, "move":move, "serial":int(fighter.attackSerial),
			"age":age, "startup":startup, "facing":int(fighter.facing), "reduced":reduced,
			"release":releasing, "key":2 if releasing else 1 if reduced or age >= 4 else 0,
			"alpha":0.50 if reduced else (0.48 if releasing else 0.76),
			"flash":0.0 if reduced or releasing else maxf(0.0, 1.0 - age / 8.0)})
	return result

static func place(cues: Array, model: CombatModel, state: Dictionary, sprites: Array, scale: float) -> Array:
	var result := []
	for cue in cues:
		var placed: Dictionary = cue.duplicate()
		var p := int(cue.player)
		placed.root = sprites[p].position + Vector2(0, -20) * scale
		placed.chest = CombatStatusEffects.body_anchor(model, state.players[p], sprites[p], scale)
		result.append(placed)
	return result

static func texture(name: String) -> AtlasTexture:
	if not textures.has(name):
		var art := AtlasTexture.new()
		art.atlas = load(DIRECTORY + str(catalog.file))
		var rect: Array = catalog.frames[name].region
		art.region = Rect2(rect[0], rect[1], rect[2], rect[3])
		art.filter_clip = true
		textures[name] = art
	return textures[name]

static func element(canvas: CanvasItem, name: String, point: Vector2, height: float, alpha: float, facing: int = 1) -> void:
	var art := texture(name)
	var factor := height / art.get_height()
	var pivot: Array = catalog.frames[name].pivot
	canvas.draw_set_transform(point, 0.0, Vector2(float(facing), 1))
	canvas.draw_texture_rect(art, Rect2(-Vector2(pivot[0], pivot[1]) * factor, art.get_size() * factor), false, Color(1, 1, 1, alpha))
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_behind(canvas: CanvasItem, cues: Array, scale: float) -> void:
	for cue in cues:
		var height := 144.0 if cue.reduced else lerpf(130.0, 148.0, minf(1.0, float(cue.age) / 6.0))
		element(canvas, ["gather", "flare", "dissipate"][int(cue.key)], cue.root, height * scale, cue.alpha, cue.facing)

static func draw_front(canvas: CanvasItem, cues: Array, scale: float) -> void:
	for cue in cues:
		var chest: Vector2 = cue.chest
		var facing := int(cue.facing)
		if float(cue.flash) > 0.0:
			element(canvas, "glint", chest + Vector2(facing * 25, 8) * scale, 55.0 * scale, cue.flash)
		# Thin rising sparks keep the tell readable against both dark scenery
		# and bright character art. They belong to the attacker, never the target.
		for i in 3:
			var progress := 0.22 + i * 0.20 if cue.reduced else fposmod(float(cue.age) + i * 5.0, 17.0) / 17.0
			var point := chest + Vector2(([-31.0, 34.0, 12.0][i]) * facing, 22.0 - progress * 67.0) * scale
			var alpha := float(cue.alpha) * (0.72 if cue.reduced else 1.0 - progress * 0.65)
			element(canvas, "sparks" if i == 2 else "spark", point, (34.0 if i == 2 else 28.0) * scale, alpha, facing)
