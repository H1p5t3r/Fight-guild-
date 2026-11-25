class_name FighterArt
extends RefCounted

# Atlas pivots/scales also compile into core/combat_data.h. Regenerate combat data after art geometry changes.
const PHASES := ["active", "windup", "block", "signature_windup", "signature_active", "ready", "walk", "run", "stance", "knockdown", "knockdown_back", "idle", "crouch_idle", "back_walk", "attack_animation", "backdash"]
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

static func idle_pose(character: int, ticks: int) -> int:
	var durations: Array = sheet(character, "idle").get("frame_ticks", [20, 20, 20, 20])
	var total := 0
	for duration in durations: total += int(duration)
	var elapsed := maxi(0, ticks) % total
	for index in durations.size():
		if elapsed < int(durations[index]): return index
		elapsed -= int(durations[index])
	return 0

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

static func apply(sprite: Sprite2D, character: int, phase: String, pose: int, world_scale: float, facing: int, idle_time: int = -1) -> void:
	var info := sheet(character, phase)
	var pivot: Array = info.frames[pose].pivot
	sprite.texture = texture(character, phase, pose)
	sprite.centered = false
	sprite.offset = -Vector2(pivot[0], pivot[1])
	var factor: float = 150.0 / info.frames[pose].get("body_height", info.body_height) * world_scale
	sprite.scale = Vector2(factor * facing, factor)
	sprite.set_meta("phase", phase)
	sprite.set_meta("pose", pose)
	apply_idle_smoke(sprite, character, phase, pose, idle_time)
	apply_frame_effect(sprite, character, phase, pose)

static func apply_frame_effect(sprite: Sprite2D, character: int, phase: String, pose: int) -> void:
	var info := sheet(character, phase)
	var frame: Dictionary = info.frames[pose]
	var effect: Dictionary = frame.get("effect", {})
	var layer := sprite.get_node_or_null("AttackEffect") as Sprite2D
	if layer == null:
		if effect.is_empty(): return
		layer = Sprite2D.new()
		layer.name = "AttackEffect"
		layer.centered = false
		sprite.add_child(layer)
	layer.visible = not effect.is_empty()
	if effect.is_empty(): return
	layer.show_behind_parent = effect.get("behind", false)
	layer.texture = texture(character, effect.sheet, effect.pose)
	var box: Array = effect.box
	var factor: float = frame.get("body_height", info.body_height) / 150.0
	layer.position = Vector2(box[0], -box[3]) * factor
	layer.scale = Vector2((box[2] - box[0]) / layer.texture.get_width(), (box[3] - box[1]) / layer.texture.get_height()) * factor
	layer.modulate = Color(1, 1, 1, effect.get("opacity", 1.0))

static func projectile_art(character: int, move: int, life: int, age: int = 0) -> Dictionary:
	var fighter: Dictionary = catalog().fighters[character]
	var effect: Dictionary = fighter.get("projectile_variants", {}).get(str(move), fighter.get("projectile", {}))
	if effect.has("frames"):
		# Remaining life is saved and freezes with hitstop. Both pillar distances
		# share the exact same texture and geometry, including expiration art.
		var interval: int = int(effect.get("frame_ticks", 6))
		var index: int = 3 if life <= 6 else (age / interval) % 3
		return {"file": effect.file, "region": effect.frames[index].region}
	return effect

static func apply_idle_smoke(sprite: Sprite2D, character: int, phase: String, pose: int, ticks: int) -> void:
	var fighter: Dictionary = catalog().fighters[character]
	var movement: Dictionary = fighter.get("movement_smoke", {})
	var effect_phase := "movement_smoke" if movement.get("presentations", {}).has(phase) else "idle_smoke"
	var effect: Dictionary = fighter.get(effect_phase, {})
	var presentation: Dictionary = effect.get("presentations", {}).get(phase, {})
	var enabled := ticks >= 0 and not presentation.is_empty()
	# Children inherit their owner's facing, foot root and foreground order.
	# show_behind_parent keeps the vapor behind the body without a global z-index.
	for layer in 2:
		var node_name := "IdleSmoke%d" % layer
		var vapor := sprite.get_node_or_null(node_name) as Sprite2D
		if vapor == null:
			if not enabled: continue
			vapor = Sprite2D.new()
			vapor.name = node_name
			vapor.show_behind_parent = true
			vapor.centered = false
			sprite.add_child(vapor)
		vapor.visible = enabled
		if not enabled: continue
		var interval: int = presentation.get("frame_ticks", effect.frame_ticks)
		var index: int = (ticks / interval + layer) % effect.frames.size()
		var blend := float(ticks % interval) / interval
		var info := sheet(character, phase)
		var body_height: float = info.frames[pose].get("body_height", info.body_height)
		var factor: float = body_height / effect.body_height
		var pivot: Array = effect.frames[index].pivot
		vapor.texture = texture(character, effect_phase, index)
		vapor.offset = -Vector2(pivot[0], pivot[1])
		vapor.scale = Vector2(presentation.scale[0], presentation.scale[1]) * factor
		if presentation.get("flip_x", false): vapor.scale.x *= -1
		vapor.position = Vector2(presentation.offset[0], -presentation.offset[1]) * body_height / 150.0
		vapor.modulate = Color(1, 1, 1, float(effect.opacity) * (blend if layer else 1.0 - blend))

static func phase_names(character: int) -> Array[String]:
	var result: Array[String] = []
	for phase in PHASES:
		if catalog().fighters[character].has(phase): result.append(phase)
	return result
