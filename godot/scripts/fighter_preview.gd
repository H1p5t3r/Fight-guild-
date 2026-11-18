class_name FighterPreview
extends Control

var character := 0
var phase := "active"
var pose := 0
var idle_ticks := -1
var facing := 1
var sprite := Sprite2D.new()
var weapon := HookWeapon.new()
var move_slot := -1
var show_collision := false
var combat_model: CombatModel
var overlay := Control.new()
static var collision_data: Dictionary = {}

func _ready() -> void:
	clip_contents = true
	add_child(sprite)
	add_child(weapon)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	overlay.draw.connect(draw_boxes)

func present(fighter: int, stage: String, frame: int, direction: int = 1, ticks: int = -1) -> void:
	character = fighter
	phase = stage
	pose = frame
	facing = direction
	idle_ticks = ticks if ticks >= 0 else frame * 20 if stage in ["idle", "crouch_idle"] else -1
	queue_redraw()
	overlay.queue_redraw()

func _draw() -> void:
	# Normalize both atlases to the same body scale and foot anchor for honest comparison.
	var scale_factor := preview_scale()
	FighterArt.apply(sprite, character, phase, pose, scale_factor, facing, idle_ticks)
	sprite.position = preview_anchor()
	weapon.visible = false
	if phase == "signature_active" and character == 4 and pose < 2:
		var move := combat_model.move(character, 28 + pose)
		# Preview first active frame, before the detached spear extends to full range.
		var origin := sprite.position + Vector2(move.hitboxBack * facing, -move.bottom) * scale_factor / 100.0
		weapon.present(origin, origin, origin + Vector2(8000 * facing, -8000 * move.hitAngle) * scale_factor / 100.0, facing, scale_factor)
	draw_line(Vector2(12, size.y - 20), Vector2(size.x - 12, size.y - 20), Color("39444d"))
	overlay.queue_redraw()

func preview_scale() -> float:
	var extent := effect_extent()
	if extent.has_area(): return minf((size.x - 24.0) / extent.size.x, (size.y - 40.0) / extent.size.y)
	return minf(size.x / (360.0 if phase.begins_with("signature_") else 260.0), size.y / 320.0) * 1.4

func preview_anchor() -> Vector2:
	var extent := effect_extent()
	if extent.has_area():
		var scale_factor := preview_scale()
		return Vector2(size.x * 0.5 - extent.get_center().x * scale_factor * facing, size.y - 20.0)
	var air_hook := character == 4 and phase.begins_with("signature_") and pose == 1
	return Vector2(size.x * 0.5, size.y - (64.0 if air_hook else 20.0))

func effect_extent() -> Rect2:
	var info := FighterArt.sheet(character, phase)
	var frame: Dictionary = info.frames[pose]
	var frames: Array = []
	if character == 2 and ((phase == "attack_animation" and pose < 8) or (phase.begins_with("signature_") and pose == 8)):
		frames = FighterArt.sheet(2, "attack_animation").frames.slice(0, 8)
	elif frame.has("effect") and phase.begins_with("signature_"):
		frames = [FighterArt.sheet(character, "signature_windup").frames[pose], FighterArt.sheet(character, "signature_active").frames[pose]]
	else: return Rect2()
	# Use a whole-clip envelope so the actor does not shrink when the effect appears.
	var extent := Rect2()
	for key in frames:
		var bounds: Array = key.bounds
		var root: Array = key.pivot
		var factor: float = 150.0 / key.get("body_height", info.body_height)
		var body := Rect2(Vector2(bounds[0] - root[0], bounds[1] - root[1]) * factor, Vector2(bounds[2] - bounds[0], bounds[3] - bounds[1]) * factor)
		extent = extent.merge(body)
		if key.has("effect"):
			var box: Array = key.effect.box
			extent = extent.merge(Rect2(Vector2(box[0], -box[3]), Vector2(box[2] - box[0], box[3] - box[1])))
	return extent.expand(Vector2.ZERO)

func draw_boxes() -> void:
	if not show_collision: return
	if combat_model == null: combat_model = CombatModel.new()
	var scale_factor := preview_scale() / 100.0
	var anchor := preview_anchor()
	var hurt: PackedInt32Array = combat_model.core.pose_boxes(character, FighterArt.PHASES.find(phase), pose)
	for i in range(0, hurt.size(), 4):
		preview_box(hurt.slice(i, i + 4), anchor, scale_factor, Color("67d5ff"))
	if collision_data.is_empty():
		collision_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/fighter_collision.json"))
	var profile: Dictionary = collision_data.fighters[character].push
	var airborne := (phase == "active" and pose == 8) or (character == 4 and phase.begins_with("signature_") and pose in [1, 3])
	var height: int = profile.airHeight if airborne else profile.crouchingHeight if phase == "crouch_idle" or (phase == "active" and pose == 11) else profile.standingHeight
	var bottom: int = profile.airBottom if airborne else 0
	preview_box(PackedInt32Array([-profile.halfWidth, bottom, profile.halfWidth, bottom + height]), anchor, scale_factor, Color("9ce56b"))
	if (phase == "active" and pose in range(1, 6)) or phase == "signature_active":
		var slot: int = move_slot if move_slot >= 0 else [0, 1, 2, 3, 13][clampi(pose - 1, 0, 4)]
		if phase == "signature_active" and move_slot < 0:
			for candidate in CombatModel.MOVE_IDS.size():
				if combat_model.move(character, candidate).artPose == pose + 1:
					slot = candidate
					break
		var move := combat_model.move(character, slot)
		if move.hitAngle:
			for i in 8:
				var left: int = move.hitboxBack + i * 1000
				var low: int = move.bottom + move.hitAngle * i * 1000
				var high: int = low + move.hitAngle * 1000
				preview_box(PackedInt32Array([left, mini(low, high) - move.height / 2, left + 1000, maxi(low, high) + move.height / 2]), anchor, scale_factor, Color("ff8859"))
		else:
			preview_box(PackedInt32Array([mini(move.hitboxBack, move.reach), move.bottom, maxi(move.hitboxBack, move.reach), move.bottom + move.height]), anchor, scale_factor, Color("ff8859"))

func preview_box(box: PackedInt32Array, anchor: Vector2, factor: float, color: Color) -> void:
	var left: int = box[0] if facing == 1 else -box[2]
	var rect := Rect2(anchor + Vector2(left, -box[3]) * factor, Vector2(box[2] - box[0], box[3] - box[1]) * factor)
	overlay.draw_rect(rect, Color(color, 0.08))
	overlay.draw_rect(rect, color, false, 1.2)
