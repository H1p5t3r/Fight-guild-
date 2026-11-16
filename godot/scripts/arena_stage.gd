class_name ArenaStage
extends RefCounted

# Independently generated image planes; no painted scenery is reconstructed in code.
# Coordinates and weights are shared by normal play, travel, and the review tool.
const DIRECTORY := "res://assets/stages/"
const IDS := ["charter", "quay", "foundry"]
const NAMES := ["THE CHARTER GROUNDS", "THE TIDE DOCKS", "FOUNDRY WALK"]
const SUBTITLES := ["THE GUILDS' COMMON GROUND", "EAST QUAY · FISHERMEN'S END", "WEST CONCOURSE · THE IRON GUILDS"]
const COLORS := [Color("c4ad86"), Color("82b8bd"), Color("d2a178")]
const DEPTHS := [0.16, 0.54, 1.0]
const LAYERS := ["far", "mid", "floor"]
# The supplied 1280x720 Strive reference has ~430px standing silhouettes (60%).
# Our arena sits below the application header: 66% of its height is ~59% of the
# full match window. Keep the canonical 150-world-pixel bodies/collisions intact.
const BODY_HEIGHT := 150.0
const BODY_SCREEN_HEIGHT := 0.66
const FRAME_HEAD_HEIGHT := 152.0
const HORIZONTAL_MARGIN := 0.12
const WALL_SCREEN_MARGIN := 0.12
static var textures := {}
static var regions := {}

static func asset_paths() -> Array[String]:
	var paths: Array[String] = []
	for id in IDS:
		for layer in LAYERS: paths.append(DIRECTORY + id + "-" + layer + ".png")
	for name in ["forge-breach", "quay-breach", "debris-kit", "charter-wall", "quay-wall", "foundry-wall"]: paths.append(DIRECTORY + name + ".png")
	return paths

static func remember(path: String, resource: Resource) -> void:
	textures[path.trim_prefix(DIRECTORY)] = resource

static func texture(file: String) -> Texture2D:
	if not textures.has(file): textures[file] = load(DIRECTORY + file)
	return textures[file]

static func tile(file: String, index: int, columns: int) -> AtlasTexture:
	var key := "%s/%d" % [file, index]
	if not regions.has(key):
		var source := texture(file)
		var result := AtlasTexture.new()
		result.atlas = source
		var width := source.get_width() / columns
		var height := source.get_height() / 2
		result.region = Rect2((index % columns) * width, (index / columns) * height, width, height)
		result.filter_clip = true
		regions[key] = result
	return regions[key]

static func next_stage(stage: int, side: int) -> int:
	return posmod(stage + side, IDS.size())

static func camera(state: Dictionary, bounds: Vector2, _reduced: bool = false) -> Dictionary:
	if state.is_empty() or bounds.x <= 0 or bounds.y <= 0: return {"center": 0.5, "zoom": 1.0, "offset": Vector2.ZERO}
	var separation := absf(float(state.players[0].x - state.players[1].x)) / 100000.0
	var floor_y := bounds.y - 76.0
	var hud_bottom := 140.0 * minf(bounds.x / 1248.0, 1.0)
	var highest := maxf(float(state.players[0].get("y", 0)), float(state.players[1].get("y", 0))) / 100.0
	var zoom := bounds.y * BODY_SCREEN_HEIGHT / (BODY_HEIGHT * bounds.x / 1000.0)
	# Essential framing also applies with reduced motion: both fighters stay visible.
	# No pose-dependent zoom or retained tween; pauses and rollback render identically.
	zoom = minf(zoom, 1.0 / (separation + HORIZONTAL_MARGIN * 2.0))
	zoom = minf(zoom, maxf(1.0, floor_y - hud_bottom) / ((highest + FRAME_HEAD_HEIGHT) * bounds.x / 1000.0))
	var edge_center := minf(0.5, (0.5 - WALL_SCREEN_MARGIN) / zoom)
	var center := clampf(float(state.players[0].x + state.players[1].x) / 200000.0, edge_center, 1.0 - edge_center)
	return {"center": center, "zoom": zoom, "offset": Vector2(bounds.x * (0.5 - center * zoom), floor_y * (1.0 - zoom))}

static func layer_rect(bounds: Vector2, image_size: Vector2, depth: float, center: float, zoom: float) -> Rect2:
	# Extra image width covers the complete camera range without mirrored/repeated buildings.
	var factor := bounds.x / image_size.x * maxf(1.14, 1.10 + depth * 0.20) * lerpf(1.0, zoom, depth)
	var shift := (center - 0.5) * bounds.x * depth * zoom
	# Very wide spacing/high launches can pull farther back than the authored view.
	# Maintain coverage in both axes while preserving the image's aspect ratio.
	factor = maxf(factor, (bounds.x + absf(shift) * 2.0) / image_size.x)
	factor = maxf(factor, (bounds.y - 76.0) / (image_size.y * (900.0 / 1024.0)))
	factor = maxf(factor, 76.0 / (image_size.y * (124.0 / 1024.0)))
	var extent := image_size * factor
	var x := (bounds.x - extent.x) * 0.5 - shift
	return Rect2(Vector2(x, bounds.y - 76.0 - image_size.y * (900.0 / 1024.0) * factor), extent)

static func draw_plane(canvas: Control, stage: int, layer: int, center: float, zoom: float,
		offset: Vector2 = Vector2.ZERO, opacity: float = 1.0, feather: bool = false) -> void:
	if opacity <= 0.0: return
	var source := texture(IDS[stage] + "-" + LAYERS[layer] + ".png")
	var rect := layer_rect(canvas.size, source.get_size(), DEPTHS[layer], center, zoom)
	rect.position += offset
	if not feather:
		canvas.draw_texture_rect(source, rect, false, Color(1, 1, 1, opacity))
		return
	# Fade the exposed image ends during travel; ordinary play uses the untouched
	# image. Three textured quads avoid a rectangular seam between adjoining floors.
	var stops := [0.0, 0.08, 0.92, 1.0]
	var alphas := [0.0, opacity, opacity, 0.0]
	for i in 3:
		var a: float = stops[i]
		var b: float = stops[i + 1]
		var vertices := PackedVector2Array([rect.position + Vector2(rect.size.x * a, 0),
			rect.position + Vector2(rect.size.x * b, 0), rect.position + Vector2(rect.size.x * b, rect.size.y),
			rect.position + Vector2(rect.size.x * a, rect.size.y)])
		var colors := PackedColorArray([Color(1, 1, 1, alphas[i]), Color(1, 1, 1, alphas[i + 1]),
			Color(1, 1, 1, alphas[i + 1]), Color(1, 1, 1, alphas[i])])
		canvas.draw_polygon(vertices, colors, PackedVector2Array([Vector2(a, 0), Vector2(b, 0), Vector2(b, 1), Vector2(a, 1)]), source)

static func draw(canvas: Control, debug_grid: bool, stage: int = 0, center: float = 0.5, zoom: float = 1.0) -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO, canvas.size), Color("17252d"))
	for layer in 3: draw_plane(canvas, stage, layer, center, zoom)
	if debug_grid: draw_grid(canvas)

static func draw_grid(canvas: Control) -> void:
	var floor_y := canvas.size.y - 76.0
	for x in range(0, int(canvas.size.x), 70): canvas.draw_line(Vector2(x, 140), Vector2(x, floor_y), Color(0.35, 0.65, 0.75, 0.16))
	for y in range(160, int(floor_y), 50): canvas.draw_line(Vector2(0, y), Vector2(canvas.size.x, y), Color(0.35, 0.65, 0.75, 0.16))

static func wall_rect(bounds: Vector2, side: int, zoom: float, offset: Vector2) -> Rect2:
	# Solid half-spaces: no gap above, below or beyond the physical contact plane.
	var edge := clampf(offset.x + (0.0 if side < 0 else bounds.x * zoom), 0.0, bounds.x)
	return Rect2(0, 0, edge, bounds.y) if side < 0 else Rect2(edge, 0, bounds.x - edge, bounds.y)

static func draw_boundaries(canvas: Control, stage: int, zoom: float, offset: Vector2,
		broken_side: int = 0, fracture: float = 0.0, opacity: float = 1.0) -> void:
	var source := texture(IDS[stage] + "-wall.png")
	for side in [-1, 1]:
		var rect := wall_rect(canvas.size, side, zoom, offset)
		if rect.size.x <= 0: continue
		var factor := maxf(rect.size.y / source.get_height(), rect.size.x / source.get_width())
		var source_width := rect.size.x / factor
		var region := Rect2(source.get_width() - source_width if side < 0 else 0.0, 0.0, source_width, rect.size.y / factor)
		var alpha := opacity * (1.0 - fracture if side == broken_side else 1.0)
		canvas.draw_texture_rect_region(source, rect, region, Color(1, 1, 1, alpha))

static func portal(canvas: Control, file: String, progress: float, side: int, opacity: float) -> void:
	if opacity <= 0.0: return
	var source := texture(file + ".png")
	var factor := maxf(canvas.size.x / source.get_width(), canvas.size.y / source.get_height()) * 1.2
	var extent := source.get_size() * factor
	var position := (canvas.size - extent) * 0.5 + Vector2(-side * (progress - 0.5) * canvas.size.x * 1.4, 0)
	canvas.draw_texture_rect(source, Rect2(position, extent), false, Color(1, 1, 1, opacity))

static func draw_footer(canvas: Control, stage: int) -> void:
	# The HUD rests on its own calm strip; the generated playing plane remains unobscured.
	canvas.draw_rect(Rect2(0, canvas.size.y - 75, canvas.size.x, 75), Color("081219", 0.80))
	FightHud.centered(canvas, NAMES[stage], Vector2(canvas.size.x * 0.5, canvas.size.y - 57), 12, Color(COLORS[stage], 0.8), 2)
