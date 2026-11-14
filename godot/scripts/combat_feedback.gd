class_name CombatFeedback
extends RefCounted

# All clocks come from the restored combat state. Drawing never advances a timer.
const DISPLAY_FONT = preload("res://assets/fonts/DejaVuSansCondensed-BoldOblique.ttf")
const TINTS := [Color("f4b45e"), Color("91b6cb")]
var cards: Array[Dictionary] = []
var area := Vector2.ZERO

func refresh(state: Dictionary, bounds: Vector2) -> void:
	area = bounds
	cards.clear()
	if state.is_empty(): return
	for p in 2:
		var fighter: Dictionary = state.players[p]
		var opponent: Dictionary = state.players[1 - p]
		# Position follows the fighter, including side switches; player colors stay stable.
		var left: bool = fighter.x < opponent.x or (fighter.x == opponent.x and p == 0)
		var count: int = fighter.comboDisplay if fighter.comboTime > 0 else 0
		var pop := 1.0 + 0.10 * maxf(0.0, 1.0 - fighter.comboAge / 8.0)
		var font_size := int(clampf((area.y - 205.0) * 0.92, 125.0, 250.0) * pop)
		var digits := str(count)
		var text_width := DISPLAY_FONT.get_string_size(digits, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var limit := area.x * 0.34
		if text_width > limit:
			font_size = int(font_size * limit / text_width)
		var center_x := area.x * (0.23 if left else 0.77)
		cards.append({"number": count, "left": left, "center_x": center_x, "font_size": font_size,
			"alpha": minf(1.0, fighter.comboTime / 18.0), "hit": fighter.hitNotice if fighter.hitNoticeTime > 0 else 0,
			"hit_alpha": minf(1.0, fighter.hitNoticeTime / 12.0), "reversal": fighter.reversalTime > 0,
			"reversal_alpha": minf(1.0, fighter.reversalTime / 12.0), "input_age": fighter.reversalInputAge})

func centered(canvas: CanvasItem, text: String, x: float, y: float, font_size: int, color: Color) -> void:
	var width := DISPLAY_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var origin := Vector2(x - width / 2.0, y)
	canvas.draw_string_outline(DISPLAY_FONT, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color(0.06, 0.09, 0.11, color.a))
	canvas.draw_string(DISPLAY_FONT, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func draw(canvas: CanvasItem) -> void:
	for p in cards.size():
		var card := cards[p]
		var tint: Color = TINTS[p]
		var center_x: float = card.center_x
		if card.number >= 2:
			var digits := str(card.number)
			var font_size: int = card.font_size
			var width := DISPLAY_FONT.get_string_size(digits, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			var base := Vector2(center_x - width / 2.0, area.y - 112.0)
			var alpha: float = card.alpha
			# Offset contour, translucent body and short diagonal cuts share the cast's hard edges.
			canvas.draw_string_outline(DISPLAY_FONT, base + Vector2(8, 6), digits, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 2, Color(tint, 0.22 * alpha))
			canvas.draw_string_outline(DISPLAY_FONT, base, digits, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(tint, 0.64 * alpha))
			canvas.draw_string(DISPLAY_FONT, base, digits, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(tint, 0.23 * alpha))
			for n in 3:
				var start := Vector2(center_x - 53 + n * 15, base.y + 18)
				canvas.draw_line(start, start + Vector2(8, -10), Color(tint, 0.8 * alpha), 3, true)
			centered(canvas, "HIT COMBO", center_x + 35, base.y + 22, 15, Color(tint, 0.95 * alpha))
		if card.hit in [3, 4]:
			var hit_color := Color("ffc771") if card.hit == 3 else Color("ff9d87")
			centered(canvas, "COUNTER" if card.hit == 3 else "PUNISH", center_x, 151, 31, Color(hit_color, card.hit_alpha))
		if card.reversal:
			var detail := "FIRST FRAME" if card.input_age == 0 else "BUFFERED %df" % card.input_age
			if card.number >= 2 or card.hit in [3, 4]:
				centered(canvas, "REVERSAL · " + detail, center_x, 123, 14, Color(Color("8ee4cf"), card.reversal_alpha))
			else:
				centered(canvas, "REVERSAL", center_x, 151, 23, Color(Color("8ee4cf"), card.reversal_alpha))
				centered(canvas, detail, center_x, 169, 11, Color(Color("b5d5d0"), card.reversal_alpha))
