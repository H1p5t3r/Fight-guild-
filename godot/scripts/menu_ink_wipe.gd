class_name MenuInkWipe
extends Control

var motion := MenuMotion.new()
var palette := MenuPalette.new()
var progress := 1.0:
	set(value):
		progress = value
		queue_redraw()
var direction := 1.0
var tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func sweep(towards: float) -> void:
	if motion.instant or motion.reduced:
		finish()
		return
	# Rapid navigation updates the destination under the current cut. Finish its travel
	# instead of snapping coverage back to zero or flickering between wipe directions.
	if is_animating(): return
	if tween: tween.kill()
	direction = towards
	progress = 0.0
	tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "progress", 1.0, motion.duration(0.34))

func finish() -> void:
	if tween: tween.kill()
	progress = 1.0

func is_animating() -> bool:
	return tween != null and tween.is_running()

func _draw() -> void:
	if progress <= 0.0 or progress >= 1.0: return
	var w := size.x
	var h := size.y
	var x := lerpf(-w * 1.6, w * 2.1, progress)
	if direction < 0.0: draw_set_transform(Vector2(w, 0), 0, Vector2(-1, 1))
	# Three staggered cuts travel together: paper edge, guild underprint, black ink.
	for layer in 3:
		var lead: float = x + [90.0, 44.0, 0.0][layer]
		var trail := lead - w * 0.94
		draw_colored_polygon(PackedVector2Array([Vector2(trail + w * 0.28, -1), Vector2(lead + w * 0.35, -1), Vector2(lead, h * 0.44), Vector2(lead - w * 0.10, h * 0.48), Vector2(lead - w * 0.23, h + 1), Vector2(trail - w * 0.15, h + 1)]), [InkMenu.PAPER, palette.accent, InkMenu.INK][layer])
	draw_set_transform(Vector2.ZERO)
