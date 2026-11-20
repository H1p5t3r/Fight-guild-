class_name HookWeapon
extends Node2D

var sprite := Sprite2D.new()
var hand := Vector2.ZERO
var butt := Vector2.ZERO
var rope_width := 1.5

func _ready() -> void:
	add_child(sprite)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.centered = false
	visible = false

func present(origin: Vector2, back: Vector2, tip: Vector2, facing: int, world_scale: float) -> void:
	var info: Dictionary = FighterArt.catalog().fighters[4].hook_weapon
	if sprite.texture == null: sprite.texture = load(FighterArt.DIRECTORY + info.file)
	var source_back := Vector2(info.butt[0], info.butt[1])
	var source_tip := Vector2(info.tip[0], info.tip[1])
	var source_vector := source_tip - source_back
	var target_vector := tip - back
	var factor := target_vector.length() / source_vector.length()
	sprite.offset = -source_back
	sprite.position = back
	sprite.scale = Vector2(factor * facing, factor)
	sprite.rotation = target_vector.angle() - Vector2(source_vector.x * facing, source_vector.y).angle()
	hand = origin
	butt = back
	rope_width = maxf(1.0, 1.5 * world_scale)
	visible = true
	queue_redraw()

func _draw() -> void:
	if hand.distance_to(butt) > 1.0:
		draw_line(hand, butt, Color("292f31"), rope_width + 2.0, true)
		draw_line(hand, butt, Color("c8b98f"), rope_width, true)
