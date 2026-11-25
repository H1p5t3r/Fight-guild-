class_name CombatImpacts
extends RefCounted

const DIRECTORY := "res://assets/effects/impact-v1/"
const ACCENTS_DIRECTORY := "res://assets/effects/impact-v2/"
static var catalog: Dictionary = load_catalog()
static var textures := {}
const SIZES := {"cut": 88.0, "blunt": 64.0, "pierce": 96.0, "fire": 86.0, "gas": 80.0, "block": 88.0, "faultless": 112.0, "counter": 116.0, "guard_break": 116.0, "armor": 76.0, "flash": 35.0, "release": 46.0}

static func load_catalog() -> Dictionary:
	var result: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY + "manifest.json"))
	var accents: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ACCENTS_DIRECTORY + "manifest.json"))
	for name in accents.families:
		var entry: Dictionary = accents.families[name].duplicate(true)
		entry.file = "../impact-v2/" + str(entry.file)
		result.families[name] = entry
	return result

static func visible(cues: Array) -> Array:
	# A rapid follow-up replaces the old held body burst. Keep trades and wall
	# impacts independent; never discard the underlying audio/rollback events.
	var result := []
	var receivers := {}
	for i in range(cues.size() - 1, -1, -1):
		var cue: Dictionary = cues[i]
		if int(cue.kind) >= 1 and int(cue.kind) <= 7:
			var receiver := 1 - int(cue.actor)
			if receivers.has(receiver): continue
			receivers[receiver] = true
		result.push_front(cue)
	return result

static func family(cue: Dictionary) -> String:
	match int(cue.kind):
		2: return "block"
		5: return "guard_break"
		3: return "counter"
		6: return "faultless"
		7, 12: return "armor"
		10, 11: return "blunt"
	var sound := CombatAudio.sound_for(cue).trim_prefix("hit_")
	return {"body": "blunt", "hammer": "blunt", "shield": "blunt", "stone": "blunt", "spear": "pierce"}.get(sound, sound)

static func drawing(cue: Dictionary) -> Dictionary:
	if int(cue.kind) in [8, 9] or int(cue.age) >= 10: return {}
	var name := family(cue)
	var sheet: Dictionary = catalog.families[name]
	var age := int(cue.age)
	# Hold the contact key in hitstop; no interpolation between generated drawings.
	var key := 0 if age < 2 else 1 if age < 5 else 2
	var frame: Dictionary = sheet.frames[key]
	var extent := float(SIZES[name]) + float(cue.strength) * (7.0 if name == "blunt" else 4.0)
	if int(cue.kind) == 10: extent = 105.0
	if int(cue.kind) == 11: extent = 150.0
	var alpha := 0.91 if key == 0 else 0.78 if key == 1 else 0.6 * float(10 - age) / 5.0
	return {"file": sheet.file, "region": frame.region, "pivot": frame.pivot,
		"extent": extent, "alpha": alpha, "key": key, "family": name,
		"facing": -int(cue.facing) if int(cue.kind) in [2, 6] else int(cue.facing)}

static func impulse(cues: Array, reduced: bool) -> Vector2:
	if reduced: return Vector2.ZERO
	var best := Vector2.ZERO
	for cue in cues:
		var age := int(cue.get("screen_age", cue.age))
		if int(cue.kind) not in [1, 3, 4, 5, 10, 11] or age >= 4: continue
		var strength := 1.0 + float(cue.strength) * 0.7
		var value: float = [-1.0, 0.50, -0.20, 0.06][age]
		var offset := Vector2(float(cue.facing) * strength * value, -absf(value) * strength * 0.25)
		if offset.length_squared() > best.length_squared(): best = offset
	return best # A trade cannot sum two shakes into a large camera jump.

static func tint(player: int, cues: Array) -> Color:
	for cue in cues:
		if int(cue.actor) == player or int(cue.get("screen_age", cue.age)) >= 2: continue
		if int(cue.kind) in [1, 3, 4]: return Color(1.14, 1.07, 0.97)
		if int(cue.kind) in [2, 6]: return Color(0.98, 1.07, 1.13)
		if int(cue.kind) == 7: return Color(1.13, 1.06, 0.94)
	return Color.WHITE

static func accent(name: String, key: int, extent: float, alpha: float) -> Dictionary:
	var sheet: Dictionary = catalog.families[name]
	var frame: Dictionary = sheet.frames[clampi(key, 0, 2)]
	return {"file": sheet.file, "region": frame.region, "pivot": frame.pivot, "extent": extent, "alpha": alpha}

static func draw_sprite(canvas: CanvasItem, spec: Dictionary, point: Vector2, scale: float, facing: int, color := Color.WHITE, shadow := false) -> void:
	if not textures.has(spec.file): textures[spec.file] = load(DIRECTORY + str(spec.file))
	var region: Array = spec.region
	var pivot := Vector2(spec.pivot[0], spec.pivot[1])
	var factor := float(spec.extent) * scale / float(region[3])
	var size := Vector2(region[2], region[3]) * factor
	var rect := Rect2(-pivot * factor, size)
	canvas.draw_set_transform(point, 0.0, Vector2(float(facing), 1.0))
	if shadow:
		canvas.draw_texture_rect_region(textures[spec.file], Rect2(rect.position + Vector2(1.5, 2.0) * scale, rect.size), Rect2(region[0], region[1], region[2], region[3]), Color(0.025, 0.035, 0.04, float(spec.alpha) * 0.50))
	color.a *= float(spec.alpha)
	canvas.draw_texture_rect_region(textures[spec.file], rect, Rect2(region[0], region[1], region[2], region[3]), color)
	canvas.draw_set_transform(Vector2.ZERO)

static func draw(canvas: CanvasItem, cues: Array, project: Callable, scale: float) -> void:
	for cue in cues:
		var spec := drawing(cue)
		if spec.is_empty(): continue
		var point: Vector2 = project.call(Vector2(cue.x, cue.y))
		draw_sprite(canvas, spec, point, scale, int(spec.facing), Color.WHITE, true)
		var screen_age := int(cue.get("screen_age", cue.age))
		if screen_age < 5 and int(cue.kind) in [1, 2, 3, 4, 6]:
			# The small bright core snaps then clears during hitstop; the authored
			# weapon burst still holds. Never flash the whole screen or a fighter.
			var extent := 30.0 + float(cue.strength) * 5.0
			var alpha: float = [0.96, 0.86, 0.67, 0.43, 0.22][screen_age]
			var key := 0 if screen_age < 2 else 1 if screen_age < 4 else 2
			draw_sprite(canvas, accent("flash", key, extent, alpha), point, scale, int(cue.facing))

static func draw_releases(canvas: CanvasItem, cues: Array, project: Callable, scale: float) -> void:
	for cue in cues:
		var age := int(cue.age)
		if age >= 5 or int(cue.get("screen_age", age)) >= 8: continue
		var key := 0 if age == 0 else 1 if age < 3 else 2
		var point: Vector2 = project.call(Vector2(int(cue.x) + int(cue.facing) * 4200, cue.y))
		var tint: Color = FighterSelectPortrait.COLORS[int(cue.character)].lerp(Color.WHITE, 0.65)
		if int(cue.character) == 0: tint = Color("ffb16c")
		draw_sprite(canvas, accent("release", key, 38.0 + float(cue.strength) * 6, 0.55 * float(5 - age) / 5.0), point, scale, int(cue.facing), tint)
