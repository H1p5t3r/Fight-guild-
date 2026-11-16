class_name CombatFeedback
extends RefCounted

# Presentation reads rollback state, never wall-clock time or Engine.time_scale.
const DISPLAY_FONT = CombatTypography.FONT
const TINTS := FightHud.PLAYER_COLORS
var cards: Array[Dictionary] = []
var area := Vector2.ZERO
var impact := {}
var reduced_motion := false

func refresh(state: Dictionary, bounds: Vector2) -> void:
	area = bounds
	cards.clear()
	impact = state
	if state.is_empty(): return
	for p in 2:
		var fighter: Dictionary = state.players[p]
		var opponent: Dictionary = state.players[1 - p]
		var left: bool = fighter.x < opponent.x or (fighter.x == opponent.x and p == 0)
		var count: int = fighter.comboDisplay if fighter.comboTime > 0 else 0
		var pop := 1.0 if reduced_motion else 1.0 + 0.13 * maxf(0.0, 1.0 - fighter.comboAge / 10.0)
		var font_size := int(clampf((area.y - 205.0) * 0.92, 125.0, 250.0) * pop)
		var width := DISPLAY_FONT.get_string_size(str(count), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		if width > area.x * 0.31: font_size = int(font_size * area.x * 0.31 / width)
		cards.append({"number": count, "left": left, "center_x": area.x * (0.21 if left else 0.79), "font_size": font_size,
			"alpha": minf(1.0, fighter.comboTime / 18.0), "hit": fighter.hitNotice if fighter.hitNoticeTime > 0 else 0,
			"hit_alpha": minf(1.0, fighter.hitNoticeTime / 12.0), "reversal": fighter.reversalTime > 0,
			"reversal_alpha": minf(1.0, fighter.reversalTime / 12.0), "input_age": fighter.reversalInputAge,
			"tier": fighter.get("counterTier", -1)})

func draw(canvas: CanvasItem) -> void:
	for p in cards.size():
		var card := cards[p]
		var center_x: float = card.center_x
		var tint: Color = TINTS[p]
		if card.number >= 2:
			var base := Vector2(center_x, area.y - 175)
			CombatTypography.word(canvas, str(card.number), base, card.font_size, area.x * 0.32,
				CombatTypography.PAPER, card.alpha * 0.62, -0.07, 7)
			CombatTypography.rule(canvas, Vector2(center_x, area.y - 101), 130, tint, card.alpha * 0.8)
			CombatTypography.word(canvas, "HITS", Vector2(center_x + 40, area.y - 100), 23, 100, tint, card.alpha, -0.07, 2)
		var cinematic: bool = int(impact.get("impactTime", 0)) > 0 and int(impact.get("impactActor", 0)) == p
		if card.hit in [3, 4] and not cinematic:
			var counter: bool = card.hit == 3
			var notice_size: int = [25, 34, 44, 54][card.tier] if counter and card.tier >= 0 else 34
			CombatTypography.word(canvas, "COUNTER" if counter else "PUNISH", Vector2(center_x, 182), notice_size,
				area.x * 0.40, CombatTypography.COUNTER if counter else Color("ff8c70"), card.hit_alpha)
		if card.reversal:
			var detail := "FIRST FRAME" if card.input_age == 0 else "BUFFERED %df" % card.input_age
			CombatTypography.word(canvas, "REVERSAL", Vector2(center_x, 232 if card.hit in [3, 4] else 182), 30,
				area.x * 0.40, Color("b4f0df"), card.reversal_alpha)
			FightHud.centered(canvas, detail, Vector2(center_x, 263 if card.hit in [3, 4] else 216), 13,
				Color(Color("b5d5d0"), card.reversal_alpha), 2)
	if int(impact.get("impactTime", 0)) > 0:
		var age: int = impact.impactDuration - impact.impactTime
		var large: bool = impact.impactTier == 3
		var opacity := minf(1.0, float(impact.impactTime) / 18.0)
		var settle := 1.0 if reduced_motion else 1.0 + 0.10 * (1.0 - smoothstep(0.0, 8.0, age))
		var size := int(clampf(area.x * (0.13 if large else 0.095), 62, 172) * settle)
		var center := Vector2(area.x * 0.5, maxf(210, area.y * 0.46))
		CombatTypography.rule(canvas, center + Vector2(0, size * 0.54), area.x * (0.77 if large else 0.57), CombatTypography.RED, opacity * 0.8)
		CombatTypography.word(canvas, "COUNTER", center, size, area.x * (0.93 if large else 0.72),
			CombatTypography.COUNTER, opacity, -0.055 if large else -0.035, 9 if large else 5)

func zoom() -> float:
	if reduced_motion or int(impact.get("impactTime", 0)) <= 0 or int(impact.get("impactTier", 0)) < 3: return 1.0
	var age: int = impact.impactDuration - impact.impactTime
	var enter := smoothstep(0.0, 4.0, age + 1)
	var leave := minf(1.0, float(impact.impactTime) / 24.0)
	return 1.0 + 0.10 * enter * leave
