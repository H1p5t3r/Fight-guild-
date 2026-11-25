class_name SuperFreeze
extends Control

# Rendering only. Future supers must pass their saved freeze age here; this
# component never starts an attack, changes hitstop, or advances the simulation.
const DEFAULT_TICKS := 54
const PORTRAITS_PATH := "res://assets/ui/super-freeze/portraits.json"
const INK := Color("08090d")
const PAPER := Color("fff7e8")
const EDGE := [
	Vector2(-0.04, 0.32), Vector2(0.07, 0.25), Vector2(0.06, 0.29),
	Vector2(0.19, 0.19), Vector2(0.18, 0.23), Vector2(0.31, 0.17),
	Vector2(0.30, 0.20), Vector2(0.43, 0.11), Vector2(0.42, 0.16),
	Vector2(0.57, 0.08), Vector2(0.56, 0.12), Vector2(0.70, 0.05),
	Vector2(0.68, 0.10), Vector2(0.83, 0.02), Vector2(0.81, 0.07),
	Vector2(1.04, -0.02), Vector2(1.00, 0.69), Vector2(0.89, 0.73),
	Vector2(0.90, 0.69), Vector2(0.77, 0.79), Vector2(0.79, 0.74),
	Vector2(0.63, 0.86), Vector2(0.64, 0.81), Vector2(0.50, 0.88),
	Vector2(0.51, 0.85), Vector2(0.36, 0.93), Vector2(0.37, 0.88),
	Vector2(0.23, 0.97), Vector2(0.25, 0.91), Vector2(0.10, 1.00),
	Vector2(0.11, 0.95), Vector2(-0.04, 1.03)]
var character := 0
var facing := 1
var elapsed := 0
var duration := DEFAULT_TICKS
var reduced_motion := false
var portrait: Texture2D
var custom_portrait := false
var portrait_records: Dictionary = {}
var textures: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	clip_contents = true
	portrait_records = JSON.parse_string(FileAccess.get_file_as_string(PORTRAITS_PATH)).get("fighters", {})
	resized.connect(queue_redraw)
	clear()

func clear() -> void:
	visible = false
	elapsed = 0

func present(fighter: int, direction: int, tick: int, total: int = DEFAULT_TICKS) -> void:
	if fighter < 0 or fighter >= CombatModel.CHARACTERS.size() or total <= 0 or tick < 0 or tick >= total:
		clear()
		return
	character = fighter
	facing = -1 if direction < 0 else 1
	elapsed = tick
	duration = total
	portrait = portrait_for(character)
	visible = true
	queue_redraw()

func portrait_for(fighter: int) -> Texture2D:
	var record: Dictionary = portrait_records.get(CombatModel.CHARACTERS[fighter].to_lower(), {})
	custom_portrait = record.get("approved", false) and record.has("file")
	if not custom_portrait: return FightHud.portrait(fighter)
	if not textures.has(fighter):
		var texture := AtlasTexture.new()
		texture.atlas = load("res://assets/ui/super-freeze/" + str(record.file))
		var rect: Array = record.region
		texture.region = Rect2(rect[0], rect[1], rect[2], rect[3])
		texture.filter_clip = true
		textures[fighter] = texture
	return textures[fighter]

func composition() -> Dictionary:
	var phase := float(elapsed) / maxf(duration - 1, 1)
	var opening := clampf(phase / 0.16, 0.0, 1.0)
	var closing := clampf((phase - 0.78) / 0.22, 0.0, 1.0)
	if reduced_motion:
		return {"opening": 1.0, "closing": 0.0, "offset": 0.0, "alpha": minf(opening * 2.0, 1.0) * (1.0 - closing), "phase": phase}
	return {"opening": 1.0 - pow(1.0 - opening, 3), "closing": closing,
		"offset": -1040.0 * pow(1.0 - opening, 3) + 1460.0 * closing * closing,
		"alpha": minf(opening * 5.0, 1.0) * (1.0 - closing * closing), "phase": phase}

func _draw() -> void:
	if portrait == null or not visible: return
	var cue := composition()
	var alpha: float = cue.alpha
	var guild: Color = FighterSelectPortrait.COLORS[character]
	draw_rect(Rect2(Vector2.ZERO, size), Color(INK, alpha * 0.50))
	var scale_factor := size / Vector2(1280, 720)
	var origin := Vector2(1280 if facing < 0 else 0, 0) * scale_factor
	draw_set_transform(origin, 0.0, scale_factor * Vector2(facing, 1))
	# The white slit arrives before the face, like a rip through the frozen arena.
	if cue.opening < 0.85 and not reduced_motion:
		var slit := PackedVector2Array([Vector2(-20, 392), Vector2(1300, 245), Vector2(1280, 253), Vector2(-20, 401)])
		draw_colored_polygon(slit, Color(PAPER, alpha))
	var band_size := Vector2(1220, 304)
	var band_origin := Vector2(30 + float(cue.offset), 214)
	var aperture: float = 1.0 if reduced_motion else lerpf(0.05, 1.0, cue.opening)
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	for point in EDGE:
		points.append(band_origin + Vector2(point.x, 0.5 + (point.y - 0.5) * aperture) * band_size)
		uv.append(Vector2(clampf(point.x, 0, 1), clampf(point.y, 0, 1)))
	var shadow := PackedVector2Array()
	for point in points: shadow.append(point + Vector2(-8, 14))
	draw_colored_polygon(shadow, Color(INK, alpha))
	draw_colored_polygon(points, Color(guild, alpha))
	if custom_portrait:
		draw_polygon(points, PackedColorArray([Color(1, 1, 1, alpha)]), uv, portrait)
	else:
		# Approved existing portraits remain a fallback until new face art is selected.
		var face_points := PackedVector2Array()
		var face_uv := PackedVector2Array()
		var crop_height := minf(1.0, portrait.get_width() / float(portrait.get_height()) * band_size.y / (band_size.x * 0.68))
		for point in EDGE:
			face_points.append(band_origin + Vector2(0.16 + point.x * 0.68, 0.5 + (point.y - 0.5) * aperture) * band_size)
			face_uv.append(Vector2(clampf(point.x, 0, 1), 0.5 + (clampf(point.y, 0, 1) - 0.5) * crop_height))
		draw_polygon(face_points, PackedColorArray([Color(1, 1, 1, alpha)]), face_uv, portrait)
	var rim := points.duplicate()
	rim.append(rim[0])
	draw_polyline(rim, Color(INK, alpha), 16.0, true)
	draw_polyline(rim, Color(PAPER, alpha), 5.0, true)
	# Sparse hard shards travel with the tear, not with the frozen fighter sprites.
	if not reduced_motion:
		for i in 12:
			var x := float((i * 197 + 71) % 1320) + float(cue.offset) * 0.18 + float(cue.closing) * 180 * (1 + i % 3)
			var y := 200.0 - x * 0.07 if i % 2 == 0 else 563.0 - x * 0.06
			var length := 18.0 + (i % 4) * 17.0
			var shard := PackedVector2Array([Vector2(x, y), Vector2(x + length, y - 12), Vector2(x + length - 13, y - 2), Vector2(x + 6, y + 4)])
			draw_colored_polygon(shard, Color(PAPER if i % 3 else guild, alpha))
	draw_set_transform(Vector2.ZERO)
