class_name SuperFreeze
extends Control

# Rendering only. Supers pass their deterministic, saved freeze age here. The screen
# copy precedes the tear, so this renderer never feeds back on itself.
const DEFAULT_TICKS := 54
const PORTRAITS_PATH := "res://assets/ui/super-freeze/portraits.json"
const TEAR_SHADER = preload("res://assets/ui/super-freeze/screen-tear.gdshader")
var character := 0
var facing := 1
var elapsed := 0
var duration := DEFAULT_TICKS
var reduced_motion := false
var portrait: Texture2D
var custom_portrait := false
var portrait_records: Dictionary = {}
var textures: Dictionary = {}
var tear_material: ShaderMaterial
var screen_copy: BackBufferCopy
var move_title: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	portrait_records = JSON.parse_string(FileAccess.get_file_as_string(PORTRAITS_PATH)).get("fighters", {})
	screen_copy = BackBufferCopy.new()
	screen_copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(screen_copy)
	var panel := ColorRect.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tear_material = ShaderMaterial.new()
	tear_material.shader = TEAR_SHADER
	panel.material = tear_material
	add_child(panel)
	move_title = Label.new()
	move_title.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	move_title.offset_top = -172
	move_title.offset_bottom = -100
	move_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_title.add_theme_font_override("font", CombatTypography.FONT)
	move_title.add_theme_font_size_override("font_size", 52)
	move_title.add_theme_color_override("font_color", Color("fff7e9"))
	move_title.add_theme_color_override("font_outline_color", Color("09090c"))
	move_title.add_theme_constant_override("outline_size", 12)
	add_child(move_title)
	resized.connect(update_material)
	clear()

func clear() -> void:
	visible = false
	elapsed = 0

func present(fighter: int, direction: int, tick: int, total: int = DEFAULT_TICKS, title: String = "") -> void:
	if fighter < 0 or fighter >= CombatModel.CHARACTERS.size() or total <= 0 or tick < 0 or tick >= total:
		clear()
		return
	character = fighter
	facing = -1 if direction < 0 else 1
	elapsed = tick
	duration = total
	move_title.text = title.to_upper()
	move_title.modulate.a = float(composition().alpha)
	portrait = portrait_for(character)
	visible = true
	update_material()

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
	var opening := clampf(phase / 0.26, 0.0, 1.0)
	var closing := clampf((phase - 0.62) / 0.38, 0.0, 1.0)
	# Cut out a fixed strip from left to right in facing-relative coordinates,
	# then replace it from right to left. Overscan clears every ragged edge.
	var rip_front := minf(lerpf(-0.12, 1.12, smoothstep(0.0, 1.0, opening)),
		lerpf(1.12, -0.12, smoothstep(0.0, 1.0, closing)))
	return {"opening": opening, "closing": closing, "phase": phase,
		"rip_front": rip_front, "alpha": minf(opening * 2.0, 1.0) * (1.0 - closing)}

func update_material() -> void:
	if tear_material == null or portrait == null: return
	var cue := composition()
	var atlas := portrait as AtlasTexture
	var texture: Texture2D = atlas.atlas if atlas else portrait
	var region := atlas.region if atlas else Rect2(Vector2.ZERO, texture.get_size())
	var texture_size := texture.get_size()
	tear_material.set_shader_parameter("face_atlas", texture)
	tear_material.set_shader_parameter("face_region", Vector4(region.position.x / texture_size.x,
		region.position.y / texture_size.y, region.size.x / texture_size.x, region.size.y / texture_size.y))
	var width := 1.0 if custom_portrait else 0.68
	var height := width * (size.x / maxf(size.y, 1.0)) / (region.size.x / maxf(region.size.y, 1.0))
	tear_material.set_shader_parameter("face_box", Vector4((1.0 - width) * 0.5, 0.5 - height * 0.5, width, height))
	tear_material.set_shader_parameter("panel_pixels", size.max(Vector2.ONE))
	tear_material.set_shader_parameter("guild", FighterSelectPortrait.COLORS[character])
	tear_material.set_shader_parameter("direction", facing)
	tear_material.set_shader_parameter("rip_front", cue.rip_front)
	tear_material.set_shader_parameter("knit_close", cue.closing)
	tear_material.set_shader_parameter("opacity", cue.alpha)
	tear_material.set_shader_parameter("reduced_motion", reduced_motion)
