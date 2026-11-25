class_name PauseTableau
extends Control

# A frozen copy of the *rendered* fight, after movement, reactions and paired
# throws have selected their poses. Simulation/rollback data is never modified.
const FILL = preload("res://assets/ui/pause-fill.gdshader")
const INK = preload("res://assets/ui/pause-ink.gdshader")
const REGIONS_FILE := "res://assets/fighters/pause-weapon-regions.json"
var background: TextureRect
var shade: ColorRect
var actors: Node2D
var fills: Array[ShaderMaterial] = []
var ink: ShaderMaterial
var copies: Array[Sprite2D] = []
var captured_characters: Array[int] = []
var captured_frame := -1
var captured_size := Vector2.ONE
var group_bounds := Rect2()
var focal_point := Vector2(0.5, 0.57)
static var used_rects := {}
var weapon_regions: Dictionary = {}
var amount := 0.0:
	set(value):
		amount = value
		if is_instance_valid(shade): shade.color.a = 0.72 * value
		if ink: ink.set_shader_parameter("opacity", value)
		for fill in fills: fill.set_shader_parameter("amount", value)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	background = TextureRect.new()
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	shade = ColorRect.new()
	shade.color = Color(0.018, 0.018, 0.024, 0.0)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	actors = Node2D.new()
	add_child(actors)
	ink = ShaderMaterial.new()
	ink.shader = INK
	weapon_regions = JSON.parse_string(FileAccess.get_file_as_string(REGIONS_FILE))
	resized.connect(func(): actors.scale = size / captured_size)
	visible = false

func capture(arena: Control, state: Dictionary, frame: int) -> void:
	for child in actors.get_children():
		actors.remove_child(child)
		child.queue_free()
	fills.clear()
	copies.clear()
	captured_characters.clear()
	group_bounds = Rect2()
	captured_frame = frame
	captured_size = size.max(Vector2.ONE)
	actors.scale = Vector2.ONE
	if DisplayServer.get_name() != "headless":
		var rendered := get_viewport().get_texture().get_image()
		if rendered != null and not rendered.is_empty(): background.texture = ImageTexture.create_from_image(rendered)
	for player in state.players: captured_characters.append(int(player.character))
	# Arena sibling order already includes the most-recently-connected fighter.
	for node in arena.get_children():
		var player: int = arena.sprites.find(node) if node is Sprite2D else -1
		if player >= 0:
			include_fighter_bounds(node)
			copy_fighter(node, captured_characters[player])
		else:
			player = arena.weapons.find(node) if node is HookWeapon else -1
			if player >= 0 and node.visible and node.sprite.visible:
				copy_sprite(node.sprite, captured_characters[player], true)
	focal_point = group_bounds.get_center() / captured_size
	amount = 0.0
	modulate.a = 1.0
	visible = true

func include_fighter_bounds(source: Sprite2D) -> void:
	if not used_rects.has(source.texture):
		var pixels := source.texture.get_image()
		var bounds := Rect2()
		if pixels:
			# Generated sheets can have nearly transparent noise far outside the
			# fighter. Only visible silhouette components define the group focus.
			var mask := BitMap.new()
			mask.create_from_image_alpha(pixels, 0.5)
			for polygon in mask.opaque_to_polygons(Rect2i(Vector2i.ZERO, pixels.get_size()), 2.0):
				var area := 0.0
				for i in polygon.size(): area += polygon[i].cross(polygon[(i + 1) % polygon.size()])
				if absf(area) < 32.0: continue
				var part := Rect2(polygon[0], Vector2.ZERO)
				for point in polygon: part = part.expand(point)
				bounds = part if not bounds.has_area() else bounds.merge(part)
		used_rects[source.texture] = bounds if bounds.has_area() else Rect2(Vector2.ZERO, source.texture.get_size())
	var rect: Rect2 = used_rects[source.texture]
	rect.position += source.offset
	if source.centered: rect.position -= source.texture.get_size() * 0.5
	var transform := get_global_transform_with_canvas().affine_inverse() * source.get_global_transform_with_canvas()
	var bounds := transform * rect
	group_bounds = bounds if not group_bounds.has_area() else group_bounds.merge(bounds)

func copy_fighter(source: Sprite2D, character: int) -> void:
	for child in source.get_children():
		if child is Sprite2D and child.visible and child.show_behind_parent:
			copy_sprite(child, character, false, true)
	copy_sprite(source, character)
	for child in source.get_children():
		if child is Sprite2D and child.visible and not child.show_behind_parent:
			copy_sprite(child, character, child.name == "AttackEffect", true)

func clone_sprite(source: Sprite2D, displacement: Vector2, material: ShaderMaterial) -> Sprite2D:
	var clone := Sprite2D.new()
	clone.texture = source.texture
	clone.centered = source.centered
	clone.offset = source.offset
	clone.flip_h = source.flip_h
	clone.flip_v = source.flip_v
	clone.region_enabled = source.region_enabled
	clone.region_rect = source.region_rect
	clone.hframes = source.hframes
	clone.vframes = source.vframes
	clone.frame = source.frame
	clone.texture_filter = source.texture_filter
	clone.material = material
	if material == ink: clone.modulate.a = source.modulate.a * source.self_modulate.a
	actors.add_child(clone)
	clone.transform = get_global_transform_with_canvas().affine_inverse() * source.get_global_transform_with_canvas()
	clone.position += displacement
	return clone

func copy_sprite(source: Sprite2D, character: int, whole_weapon: bool = false, effect: bool = false) -> void:
	if not source.visible or source.texture == null or source.modulate.a * source.self_modulate.a < 0.001: return
	var unit := size.y / 720.0
	clone_sprite(source, Vector2(13, 16) * unit, ink)
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2(-0.707, -0.707), Vector2(0.707, -0.707), Vector2(-0.707, 0.707), Vector2(0.707, 0.707)]:
		clone_sprite(source, direction * 3.5 * unit, ink)
	var fill := material_for(source, character, whole_weapon, effect)
	fills.append(fill)
	var copy := clone_sprite(source, Vector2.ZERO, fill)
	copy.set_meta("source_transform", source.get_global_transform_with_canvas())
	copy.set_meta("source_id", source.get_instance_id())
	copy.set_meta("character", character)
	copy.set_meta("weapon", whole_weapon)
	copies.append(copy)

func material_for(source: Sprite2D, character: int, whole_weapon: bool = false, effect: bool = false) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = FILL
	material.set_shader_parameter("guild", FighterSelectPortrait.COLORS[character])
	material.set_shader_parameter("source_tint", source.modulate * source.self_modulate)
	var texture := source.texture
	var rect := Rect2(Vector2.ZERO, texture.get_size())
	if texture is AtlasTexture:
		rect = texture.region
		texture = texture.atlas
	material.set_shader_parameter("atlas_size", texture.get_size())
	material.set_shader_parameter("region", Vector4(rect.position.x, rect.position.y, rect.size.x, rect.size.y))
	var file := texture.resource_path.trim_prefix(FighterArt.DIRECTORY)
	var key := "%s:%d,%d,%d,%d" % [file, rect.position.x, rect.position.y, rect.size.x, rect.size.y]
	var polygons: Array = weapon_regions.get(key, [])
	var mode := 3 if whole_weapon else 0 if character == 2 or effect else 1 if weapon_regions.has(key) else 2
	material.set_shader_parameter("weapon_mode", mode)
	material.set_shader_parameter("amount", amount)
	var points := PackedVector2Array()
	var ends := PackedInt32Array()
	var bounds := PackedVector4Array()
	for polygon in polygons:
		var box := Rect2(Vector2(polygon[0][0], polygon[0][1]), Vector2.ZERO)
		for point in polygon:
			var vertex := Vector2(point[0], point[1])
			points.append(vertex)
			box = box.expand(vertex)
		bounds.append(Vector4(box.position.x, box.position.y, box.end.x, box.end.y))
		ends.append(points.size())
	points.resize(96)
	ends.resize(12)
	bounds.resize(12)
	material.set_shader_parameter("points", points)
	material.set_shader_parameter("ends", ends)
	material.set_shader_parameter("bounds", bounds)
	material.set_shader_parameter("polygon_count", polygons.size())
	# Legacy sheets: conservative protection for hair, face and pale torso cloth.
	var w := rect.size.x
	var h := rect.size.y
	material.set_shader_parameter("protected_head", Vector4(w * 0.31, 0, w * 0.70, h * 0.39))
	material.set_shader_parameter("protected_body", Vector4(w * 0.27, h * 0.32, w * 0.68, h))
	return material
