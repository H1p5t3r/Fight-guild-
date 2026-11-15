class_name FighterPreview
extends Control

var character := 0
var phase := "active"
var pose := 0
var facing := 1
var sprite := Sprite2D.new()
var show_collision := false
var combat_model: CombatModel
var overlay := Control.new()
static var collision_data: Dictionary = {}

func _ready() -> void:
	clip_contents = true
	add_child(sprite)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	overlay.draw.connect(draw_boxes)

func present(fighter: int, stage: String, frame: int, direction: int = 1) -> void:
	character = fighter
	phase = stage
	pose = frame
	facing = direction
	queue_redraw()
	overlay.queue_redraw()

func _draw() -> void:
	# Normalize both atlases to the same body scale and foot anchor for honest comparison.
	var scale_factor := minf(size.x / 260.0, size.y / 320.0) * 1.4
	FighterArt.apply(sprite, character, phase, pose, scale_factor, facing)
	sprite.position = Vector2(size.x * 0.5, size.y - 20.0)
	draw_line(Vector2(12, size.y - 20), Vector2(size.x - 12, size.y - 20), Color("39444d"))
	overlay.queue_redraw()

func draw_boxes() -> void:
	if not show_collision: return
	if combat_model == null: combat_model = CombatModel.new()
	var scale_factor := minf(size.x / 260.0, size.y / 320.0) * 1.4 / 100.0
	var anchor := Vector2(size.x * 0.5, size.y - 20.0)
	var hurt: PackedInt32Array = combat_model.core.pose_boxes(character, ["active", "windup", "block"].find(phase), pose)
	for i in range(0, hurt.size(), 4):
		preview_box(hurt.slice(i, i + 4), anchor, scale_factor, Color("67d5ff"))
	if collision_data.is_empty():
		collision_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/fighter_collision.json"))
	var profile: Dictionary = collision_data.fighters[character].push
	var height: int = profile.airHeight if phase == "active" and pose == 8 else profile.crouchingHeight if phase == "active" and pose == 11 else profile.standingHeight
	var bottom: int = profile.airBottom if phase == "active" and pose == 8 else 0
	preview_box(PackedInt32Array([-profile.halfWidth, bottom, profile.halfWidth, bottom + height]), anchor, scale_factor, Color("9ce56b"))
	if phase == "active" and pose in range(1, 6):
		var move := combat_model.move(character, [0, 1, 2, 3, 13][pose - 1])
		preview_box(PackedInt32Array([mini(move.hitboxBack, move.reach), move.bottom, maxi(move.hitboxBack, move.reach), move.bottom + move.height]), anchor, scale_factor, Color("ff8859"))

func preview_box(box: PackedInt32Array, anchor: Vector2, factor: float, color: Color) -> void:
	var left: int = box[0] if facing == 1 else -box[2]
	var rect := Rect2(anchor + Vector2(left, -box[3]) * factor, Vector2(box[2] - box[0], box[3] - box[1]) * factor)
	overlay.draw_rect(rect, Color(color, 0.08))
	overlay.draw_rect(rect, color, false, 1.2)
