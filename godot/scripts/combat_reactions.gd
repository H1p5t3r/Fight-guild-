class_name CombatReactions
extends RefCounted

# Render-only atlases. Never add these drawings to PHASES or collision authoring:
# the simulation continues using the same poses, roots, boxes and stun rules.
const DIRECTORY := "res://assets/fighters/reactions-v1/"
static var manifest: Dictionary = {}
static var textures: Dictionary = {}

static func receiving(fighter: Dictionary) -> bool:
	var reaction := int(fighter.get("reaction", 0))
	if reaction in [2, 3, 4, 6]: return false # Knockdown, wakeup, wall splat and capture keep their own art.
	return (int(fighter.get("stun", 0)) > 0 and not fighter.get("guarding", 0)) or reaction in [1, 5, 7]

static func family(fighter: Dictionary, cue: Dictionary) -> String:
	if cue.is_empty() or not receiving(fighter): return ""
	var flags := int(cue.get("flags", 0))
	if int(fighter.get("y", 0)) > 0 or flags & 8: return "air"
	match flags & 6:
		2: return "legs"
		6: return "head"
	return "chest" # Includes arm/extension boxes and pre-metadata cues.

static func key(age: int) -> int:
	# Contact holds through hitstop; sharp recoil, then a sustained stun pose.
	# No interpolated morphs or automatic return to idle while still stunned.
	return 0 if age < 2 else 1 if age < 5 else 2

static func catalog() -> Dictionary:
	if manifest.is_empty(): manifest = JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY + "manifest.json"))
	return manifest

static func frame_for(character: int, reaction: String, age: int) -> Dictionary:
	var clip: Dictionary = catalog().get("fighters", {}).get(str(character), {}).get(reaction, {})
	if clip.is_empty(): return {}
	var frame: Dictionary = clip.frames[key(age)].duplicate()
	frame.file = frame.get("file", clip.file)
	frame.body_height = frame.get("body_height", clip.body_height)
	return frame

static func apply(sprite: Sprite2D, fighter: Dictionary, cue: Dictionary, world_scale: float) -> bool:
	var reaction := family(fighter, cue)
	sprite.set_meta("reaction_family", reaction)
	if reaction.is_empty(): return false
	var frame := frame_for(int(fighter.character), reaction, int(cue.age))
	# Unapproved/missing art keeps the existing calibrated reaction drawing.
	if frame.is_empty(): return false
	var identity := "%s/%s" % [frame.file, str(frame.region)]
	if not textures.has(identity):
		var texture := AtlasTexture.new()
		texture.atlas = load(DIRECTORY + str(frame.file))
		var rect: Array = frame.region
		texture.region = Rect2(rect[0], rect[1], rect[2], rect[3])
		texture.filter_clip = true
		textures[identity] = texture
	sprite.texture = textures[identity]
	sprite.centered = false
	sprite.offset = -Vector2(frame.pivot[0], frame.pivot[1])
	var factor := 150.0 / float(frame.body_height) * world_scale
	sprite.scale = Vector2(factor * int(fighter.facing), factor)
	return true
