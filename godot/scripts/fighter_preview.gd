class_name FighterPreview
extends Control

var character := 0
var phase := "active"
var pose := 0
var facing := 1
var sprite := Sprite2D.new()

func _ready() -> void:
	clip_contents = true
	add_child(sprite)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func present(fighter: int, stage: String, frame: int, direction: int = 1) -> void:
	character = fighter
	phase = stage
	pose = frame
	facing = direction
	queue_redraw()

func _draw() -> void:
	# Normalize both atlases to the same body scale and foot anchor for honest comparison.
	var scale_factor := minf(size.x / 260.0, size.y / 320.0) * 1.4
	FighterArt.apply(sprite, character, phase, pose, scale_factor, facing)
	sprite.position = Vector2(size.x * 0.5, size.y - 20.0)
	draw_line(Vector2(12, size.y - 20), Vector2(size.x - 12, size.y - 20), Color("39444d"))
