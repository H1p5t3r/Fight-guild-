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
const TRAVEL_EDGE_FADE := 0.06
# Match presentation fills the viewport. Bodies and all nearby scenery use the
# same world projection; distant scenery has parallax, not a separate zoom cap.
const BODY_HEIGHT := 150.0
const BODY_SCREEN_HEIGHT := 0.60
const FRAME_HEAD_HEIGHT := 152.0
const HORIZONTAL_MARGIN := 0.12
const WALL_SCREEN_MARGIN := 0.12
const SCENE_WORLD_WIDTH := 1240.0
const SCENE_BASELINE := 810.0 / 1024.0
static var textures := {}
static var regions := {}

static func floor_line(bounds: Vector2) -> float:
	return bounds.y * 0.925

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
	var floor_y := floor_line(bounds)
	var hud_bottom := FightHud.TOP_CLEARANCE * minf(bounds.x / 1248.0, 1.0)
	var highest := maxf(float(state.players[0].get("y", 0)), float(state.players[1].get("y", 0))) / 100.0
	# Follow shared air height rather than shrinking two airborne fighters merely
	# to keep an empty floor in view. With a grounded opponent the floor stays put.
	var lowest := minf(float(state.players[0].get("y", 0)), float(state.players[1].get("y", 0))) / 100.0
	var lift_world := maxf(0.0, lowest - 40.0)
	var zoom := bounds.y * BODY_SCREEN_HEIGHT / (BODY_HEIGHT * bounds.x / 1000.0)
	# Essential framing also applies with reduced motion: both fighters stay visible.
	# No pose-dependent zoom or retained tween; pauses and rollback render identically.
	zoom = minf(zoom, 1.0 / (separation + HORIZONTAL_MARGIN * 2.0))
	zoom = minf(zoom, maxf(1.0, floor_y - hud_bottom) / ((highest - lift_world + FRAME_HEAD_HEIGHT) * bounds.x / 1000.0))
	# Narrow development views need enough world-space room for a body beyond its
	# pushbox, even when the minimum screen-relative margin would be too small.
	var wall_margin := maxf(WALL_SCREEN_MARGIN, 0.055 * zoom)
	var edge_center := minf(0.5, (0.5 - wall_margin) / zoom)
	var center := clampf(float(state.players[0].x + state.players[1].x) / 200000.0, edge_center, 1.0 - edge_center)
	var lift := lift_world * bounds.x / 1000.0 * zoom
	return {"center": center, "zoom": zoom, "lift": lift,
		"offset": Vector2(bounds.x * (0.5 - center * zoom), floor_y * (1.0 - zoom) + lift)}

static func layer_rect(bounds: Vector2, image_size: Vector2, depth: float, center: float, zoom: float, lift: float = 0.0) -> Rect2:
	# A source pixel has a fixed world size. The painted seam stays registered;
	# y=810 is our ground plane, leaving visible paving below the fighters' feet.
	var factor := bounds.x / 1000.0 * zoom * SCENE_WORLD_WIDTH / image_size.x
	var extent := image_size * factor
	var shift := (center - 0.5) * bounds.x * zoom * depth
	var x := (bounds.x - extent.x) * 0.5 - shift
	return Rect2(Vector2(x, floor_line(bounds) + lift - image_size.y * SCENE_BASELINE * factor), extent)

static func draw_plane(canvas: Control, stage: int, layer: int, center: float, zoom: float,
		offset: Vector2 = Vector2.ZERO, opacity: float = 1.0, feather: bool = false, lift: float = 0.0) -> void:
	if opacity <= 0.0: return
	var source := texture(IDS[stage] + "-" + LAYERS[layer] + ".png")
	var rect := layer_rect(canvas.size, source.get_size(), DEPTHS[layer], center, zoom, lift)
	# The sky is the infinite backdrop; it must cover even when both fighters are
	# high above the floor. Nearby plates retain their exact world scale.
	if layer == 0:
		var factor := maxf(rect.size.x / source.get_width(), maxf(canvas.size.x / source.get_width(), canvas.size.y / source.get_height()))
		var extent := source.get_size() * factor
		rect = Rect2(Vector2(clampf(rect.position.x, canvas.size.x - extent.x, 0), clampf(rect.position.y, canvas.size.y - extent.y, 0)), extent)
	rect.position += offset
	var tint := Color(0.83, 0.88, 0.93, opacity) if layer < 2 else Color(1, 1, 1, opacity)
	var top_fade := layer == 1 and rect.position.y > -20.0
	if not feather and not top_fade:
		canvas.draw_texture_rect(source, rect, false, tint)
		return
	# Fade the exposed image ends during travel; ordinary play uses the untouched
	# image. Three textured quads avoid a rectangular seam between adjoining floors.
	var stops := [0.0, TRAVEL_EDGE_FADE, 1.0 - TRAVEL_EDGE_FADE, 1.0] if feather else [0.0, 1.0]
	var alphas := [0.0, opacity, opacity, 0.0] if feather else [opacity, opacity]
	var rows := [0.0, 0.06, 1.0] if top_fade else [0.0, 1.0]
	var row_alphas := [0.0, 1.0, 1.0] if top_fade else [1.0, 1.0]
	for i in stops.size() - 1:
		var a: float = stops[i]
		var b: float = stops[i + 1]
		for j in rows.size() - 1:
			var c: float = rows[j]
			var d: float = rows[j + 1]
			var uv := PackedVector2Array([Vector2(a, c), Vector2(b, c), Vector2(b, d), Vector2(a, d)])
			var vertices := PackedVector2Array()
			for point in uv: vertices.append(rect.position + point * rect.size)
			var colors := PackedColorArray([Color(tint, alphas[i] * row_alphas[j]), Color(tint, alphas[i + 1] * row_alphas[j]),
				Color(tint, alphas[i + 1] * row_alphas[j + 1]), Color(tint, alphas[i] * row_alphas[j + 1])])
			canvas.draw_polygon(vertices, colors, uv, source)

static func draw(canvas: Control, debug_grid: bool, stage: int = 0, center: float = 0.5, zoom: float = 1.0, lift: float = 0.0) -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO, canvas.size), Color("17252d"))
	for layer in 3: draw_plane(canvas, stage, layer, center, zoom, Vector2.ZERO, 1.0, false, lift)
	if debug_grid: draw_grid(canvas)

static func draw_grid(canvas: Control) -> void:
	var floor_y := floor_line(canvas.size)
	for x in range(0, int(canvas.size.x), 70): canvas.draw_line(Vector2(x, 140), Vector2(x, floor_y), Color(0.35, 0.65, 0.75, 0.16))
	for y in range(160, int(floor_y), 50): canvas.draw_line(Vector2(0, y), Vector2(canvas.size.x, y), Color(0.35, 0.65, 0.75, 0.16))

static func wall_rect(bounds: Vector2, side: int, zoom: float, offset: Vector2) -> Rect2:
	# Solid half-spaces: no gap above, below or beyond the physical contact plane.
	var edge := clampf(offset.x + (0.0 if side < 0 else bounds.x * zoom), 0.0, bounds.x)
	return Rect2(0, 0, edge, bounds.y) if side < 0 else Rect2(edge, 0, bounds.x - edge, bounds.y)

static func draw_boundaries(canvas: Control, stage: int, zoom: float, offset: Vector2,
		broken_side: int = 0, fracture: float = 0.0, opacity: float = 1.0) -> void:
	var source := texture(IDS[stage] + "-wall.png")
	var factor := canvas.size.x / 1000.0 * zoom * 0.34
	var ground := offset.y + floor_line(canvas.size) * zoom
	for side in [-1, 1]:
		var rect := wall_rect(canvas.size, side, zoom, offset)
		if rect.size.x <= 0: continue
		# Repeat a world-sized surface through the infinite collision half-space.
		# Bricks now change size with the fighters and stay anchored to the floor.
		var region := Rect2(1160.0 - rect.size.x / factor if side < 0 else 360.0,
			880.0 - ground / factor, rect.size.x / factor, rect.size.y / factor)
		var alpha := opacity * (1.0 - fracture if side == broken_side else 1.0)
		draw_wall_surface(canvas, source, rect, region.position, factor, alpha)
		var edge := rect.end.x if side < 0 else rect.position.x
		var bevel := minf(rect.size.x, 9.0 * factor)
		canvas.draw_rect(Rect2(edge - bevel if side < 0 else edge, 0, bevel, canvas.size.y), Color("080d16", 0.55 * alpha))
		canvas.draw_line(Vector2(edge - bevel if side < 0 else edge + bevel, 0), Vector2(edge - bevel if side < 0 else edge + bevel, canvas.size.y), Color(COLORS[stage], 0.42 * alpha), 1.2, true)
		var shade_end: float = edge - side * 25.0 * factor
		canvas.draw_polygon(PackedVector2Array([Vector2(edge, 0), Vector2(shade_end, 0), Vector2(shade_end, canvas.size.y), Vector2(edge, canvas.size.y)]),
			PackedColorArray([Color("080d16", 0.28 * alpha), Color("080d16", 0), Color("080d16", 0), Color("080d16", 0.28 * alpha)]))

static func draw_wall_surface(canvas: Control, source: Texture2D, rect: Rect2, origin: Vector2, factor: float, alpha: float) -> void:
	var tiles := wall_surface_tiles(rect, origin, factor, source.get_size())
	for i in range(0, tiles.size(), 2):
		canvas.draw_texture_rect_region(source, tiles[i], tiles[i + 1], Color(0.78, 0.83, 0.88, alpha))

static func wall_surface_tiles(rect: Rect2, origin: Vector2, factor: float, image_size: Vector2) -> Array[Rect2]:
	# Explicit bounded UV tiles avoid the clamped edge streaks of out-of-range
	# texture regions, including high airborne cameras and very wide views.
	var tiles: Array[Rect2] = []
	var x := rect.position.x
	var u := fposmod(origin.x, image_size.x)
	var first_v := fposmod(origin.y, image_size.y)
	while x < rect.end.x - 0.01:
		var width := minf(rect.end.x - x, (image_size.x - u) * factor)
		var y := rect.position.y
		var v := first_v
		while y < rect.end.y - 0.01:
			var height := minf(rect.end.y - y, (image_size.y - v) * factor)
			if width > 0 and height > 0:
				tiles.append(Rect2(x, y, width, height))
				tiles.append(Rect2(u, v, width / factor, height / factor))
			y += height
			# Advance to the next tile explicitly. Recomputing modulo at a seam
			# can round to the full texture height, producing a zero-size loop.
			v = 0.0
		x += width
		u = 0.0
	return tiles

static func portal(canvas: Control, file: String, progress: float, side: int, opacity: float) -> void:
	if opacity <= 0.0: return
	var source := texture(file + ".png")
	var factor := maxf(canvas.size.x / source.get_width(), canvas.size.y / source.get_height()) * 1.2
	var extent := source.get_size() * factor
	var position := (canvas.size - extent) * 0.5 + Vector2(-side * (progress - 0.5) * canvas.size.x * 1.4, 0)
	canvas.draw_texture_rect(source, Rect2(position, extent), false, Color(1, 1, 1, opacity))

static func draw_footer(canvas: Control, stage: int, caption: bool = true) -> void:
	# Momentum floats over the stage. A fade, rather than a hard panel edge, keeps
	# the playing surface visible through the bottom of the frame.
	var w := canvas.size.x
	var h := canvas.size.y
	canvas.draw_polygon(PackedVector2Array([Vector2(0, h - 62), Vector2(w, h - 62), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([Color("081219", 0), Color("081219", 0), Color("081219", 0.68), Color("081219", 0.68)]))
	if caption: FightHud.centered(canvas, NAMES[stage], Vector2(w * 0.5, h - 16), int(clampf(w * 0.009, 9, 12)), Color(COLORS[stage], 0.7), 2)
