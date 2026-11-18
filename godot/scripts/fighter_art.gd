class_name FighterArt
extends RefCounted

# Atlas pivots/scales also compile into core/combat_data.h. Regenerate combat data after art geometry changes.
const PHASES := ["active", "windup", "block", "signature_windup", "signature_active", "ready", "walk", "run", "stance"]
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
		var file: String = info.frames[pose].get("file", info.file)
		if not textures.has(file): textures[file] = load(DIRECTORY + file)
		var result := AtlasTexture.new()
		result.atlas = textures[file]
		var frame: Dictionary = info.frames[pose]
		var rect: Array = frame.get("render_region", frame.region)
		result.region = Rect2(rect[0], rect[1], rect[2], rect[3])
		if frame.has("render_region"):
			# Trim atlas-neighbor bleed without changing the logical foot pivot,
			# body coordinates or texture size used by collision authoring.
			result.margin = Rect2(rect[0] - frame.region[0], rect[1] - frame.region[1], frame.region[2] - rect[2], frame.region[3] - rect[3])
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

static func phase_names(character: int) -> Array[String]:
	var result: Array[String] = []
	for phase in PHASES:
		if catalog().fighters[character].has(phase): result.append(phase)
	return result
