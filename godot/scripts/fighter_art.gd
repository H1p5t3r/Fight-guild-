class_name FighterArt
extends RefCounted

# Atlas pivots/scales also compile into core/combat_data.h. Regenerate combat data after art geometry changes.
const DIRECTORY := "res://assets/fighters/"
static var manifest: Dictionary = {}
static var textures: Dictionary = {}
static var regions: Dictionary = {}

static func catalog() -> Dictionary:
	if manifest.is_empty():
		manifest = JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY + "manifest.json"))
	return manifest

static func sheet(character: int, phase: String = "active") -> Dictionary:
	return catalog().fighters[character][phase]

static func texture(character: int, phase: String, pose: int) -> AtlasTexture:
	var key := "%d/%s/%d" % [character, phase, pose]
	if not regions.has(key):
		var info := sheet(character, phase)
		if not textures.has(info.file): textures[info.file] = load(DIRECTORY + info.file)
		var result := AtlasTexture.new()
		result.atlas = textures[info.file]
		var rect: Array = info.frames[pose].region
		result.region = Rect2(rect[0], rect[1], rect[2], rect[3])
		result.filter_clip = true
		regions[key] = result
	return regions[key]

static func apply(sprite: Sprite2D, character: int, phase: String, pose: int, world_scale: float, facing: int) -> void:
	var info := sheet(character, phase)
	var pivot: Array = info.frames[pose].pivot
	sprite.texture = texture(character, phase, pose)
	sprite.centered = false
	sprite.offset = -Vector2(pivot[0], pivot[1])
	var factor: float = 150.0 / info.body_height * world_scale
	sprite.scale = Vector2(factor * facing, factor)
	sprite.set_meta("phase", phase)
	sprite.set_meta("pose", pose)
