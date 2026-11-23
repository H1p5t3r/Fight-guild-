class_name CombatImpacts
extends RefCounted

const DIRECTORY := "res://assets/effects/impact-v1/"
static var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY + "manifest.json"))
static var textures := {}
const SIZES := {"cut": 84.0, "blunt": 56.0, "pierce": 92.0, "fire": 80.0, "gas": 78.0, "block": 84.0, "faultless": 100.0, "counter": 106.0}

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
		2, 5: return "block"
		3: return "counter"
		6: return "faultless"
		7, 12: return "pierce"
		10, 11: return "blunt"
	var sound := CombatAudio.sound_for(cue).trim_prefix("hit_")
	return {"body": "blunt", "hammer": "blunt", "stone": "blunt", "spear": "pierce"}.get(sound, sound)

static func drawing(cue: Dictionary) -> Dictionary:
	if int(cue.kind) in [8, 9] or int(cue.age) >= 10: return {}
	var name := family(cue)
	var sheet: Dictionary = catalog.families[name]
	var age := int(cue.age)
	# Hold the contact key in hitstop; no interpolation between generated drawings.
	var key := 0 if age < 2 else 1 if age < 5 else 2
	var frame: Dictionary = sheet.frames[key]
	var extent := float(SIZES[name]) + float(cue.strength) * (7.0 if name == "blunt" else 4.0)
	if int(cue.kind) == 5: extent *= 1.15
	if int(cue.kind) == 10: extent = 105.0
	if int(cue.kind) == 11: extent = 150.0
	var alpha := 0.88 if key == 0 else 0.76 if key == 1 else 0.6 * float(10 - age) / 5.0
	return {"file": sheet.file, "region": frame.region, "pivot": frame.pivot,
		"extent": extent, "alpha": alpha, "key": key, "family": name}

static func impulse(cues: Array, reduced: bool) -> Vector2:
	if reduced: return Vector2.ZERO
	var best := Vector2.ZERO
	for cue in cues:
		if int(cue.kind) not in [1, 3, 4, 5, 10, 11] or int(cue.age) >= 4: continue
		var strength := 1.0 + float(cue.strength) * 0.6
		var value: float = [-1.0, 0.55, -0.25, 0.1][int(cue.age)]
		var offset := Vector2(float(cue.facing) * strength * value, -absf(value) * strength * 0.25)
		if offset.length_squared() > best.length_squared(): best = offset
	return best # A trade cannot sum two shakes into a large camera jump.

static func tint(player: int, cues: Array) -> Color:
	for cue in cues:
		if int(cue.actor) != player and int(cue.kind) in [1, 3, 4] and int(cue.age) < 2:
			return Color(1.08, 1.02, 0.97)
	return Color.WHITE

static func draw(canvas: CanvasItem, cues: Array, project: Callable, scale: float) -> void:
	for cue in cues:
		var spec := drawing(cue)
		if spec.is_empty(): continue
		if not textures.has(spec.file): textures[spec.file] = load(DIRECTORY + str(spec.file))
		var region: Array = spec.region
		var pivot := Vector2(spec.pivot[0], spec.pivot[1])
		var factor := float(spec.extent) * scale / float(region[3])
		var size := Vector2(region[2], region[3]) * factor
		var point: Vector2 = project.call(Vector2(cue.x, cue.y))
		var rect := Rect2(-pivot * factor, size)
		# Mirror around the registered contact nick, never around the texture bounds.
		canvas.draw_set_transform(point, 0.0, Vector2(float(cue.facing), 1.0))
		canvas.draw_texture_rect_region(textures[spec.file], rect, Rect2(region[0], region[1], region[2], region[3]), Color(1, 1, 1, spec.alpha))
		canvas.draw_set_transform(Vector2.ZERO)
