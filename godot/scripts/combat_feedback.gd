class_name CombatFeedback
extends RefCounted

# Presentation reads rollback state, never wall-clock time or Engine.time_scale.
const TINTS := FightHud.PLAYER_COLORS
const COMBO_FULL_SIZE_HITS := 10
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
		var maximum := clampf(area.y * 0.40, 125.0, 250.0)
		var growth := clampf(float(count - 2) / (COMBO_FULL_SIZE_HITS - 2), 0.0, 1.0)
		var font_size := roundi(minf(maximum, lerpf(maximum * 0.34, maximum, growth) * lerpf(pop, 1.0, growth)))
		# echo_word fits long counts horizontally, keeping the height capped at 10.
		cards.append({"number": count, "left": left, "center_x": area.x * (0.21 if left else 0.79), "center_y": area.y * 0.47, "font_size": font_size,
			"alpha": minf(1.0, fighter.comboTime / 18.0), "hit": fighter.hitNotice if fighter.hitNoticeTime > 0 else 0,
			"hit_alpha": minf(1.0, fighter.hitNoticeTime / 12.0), "reversal": fighter.reversalTime > 0,
			"reversal_alpha": minf(1.0, fighter.reversalTime / 12.0), "input_age": fighter.reversalInputAge,
			"tier": fighter.get("counterTier", -1)})

func draw(canvas: CanvasItem) -> void:
	var notice_y := FightHud.TOP_CLEARANCE * minf(area.x / 1248.0, 1.0) + 16.0
	for p in cards.size():
		var card := cards[p]
		var center_x: float = card.center_x
		var tint: Color = TINTS[p]
		if card.number >= 2:
			var base := Vector2(center_x, card.center_y)
			CombatTypography.echo_word(canvas, str(card.number), base, card.font_size, area.x * 0.32,
				CombatTypography.PAPER, card.alpha, 0.12)
			var caption_y: float = card.center_y + card.font_size * 0.38 + 12.0
			var rule_width := clampf(card.font_size * 0.6, 64.0, 130.0)
			CombatTypography.rule(canvas, Vector2(center_x, caption_y - 3), rule_width, tint, card.alpha * 0.35)
			CombatTypography.word(canvas, "HITS", Vector2(center_x + rule_width * 0.28, caption_y), int(clampf(card.font_size * 0.12, 14, 23)), 100, tint, card.alpha, -0.07, 2)
		var cinematic: bool = int(impact.get("impactTime", 0)) > 0 and int(impact.get("impactActor", 0)) == p
		if card.hit in [3, 4] and not cinematic:
			var counter: bool = card.hit == 3
			var notice_size: int = [25, 34, 44, 54][card.tier] if counter and card.tier >= 0 else 34
			CombatTypography.word(canvas, "COUNTER" if counter else "PUNISH", Vector2(center_x, notice_y), notice_size,
				area.x * 0.40, CombatTypography.COUNTER if counter else Color("ff8c70"), card.hit_alpha * 0.7)
		if card.reversal:
			var detail := "FIRST FRAME" if card.input_age == 0 else "BUFFERED %df" % card.input_age
			CombatTypography.word(canvas, "REVERSAL", Vector2(center_x, notice_y + 50 if card.hit in [3, 4] else notice_y), 30,
				area.x * 0.40, Color("b4f0df"), card.reversal_alpha * 0.7)
			FightHud.centered(canvas, detail, Vector2(center_x, notice_y + 81 if card.hit in [3, 4] else notice_y + 34), 13,
				Color(Color("b5d5d0"), card.reversal_alpha), 2)
	if int(impact.get("impactTime", 0)) > 0:
		var age: int = impact.impactDuration - impact.impactTime
		var large: bool = impact.impactTier == 3
		var opacity := minf(1.0, float(impact.impactTime) / 18.0)
		var settle := 1.0 if reduced_motion else 1.0 + 0.10 * (1.0 - smoothstep(0.0, 8.0, age))
		var size := int(clampf(area.x * (0.13 if large else 0.095), 62, 172) * settle)
		var center := Vector2(area.x * 0.5, maxf(210, area.y * 0.46))
		# Two broken speed marks frame the open lettering instead of a solid banner.
		for side in [-1, 1]:
			var edge := center + Vector2(side * area.x * 0.30, size * 0.64)
			CombatTypography.rule(canvas, edge, area.x * 0.13, CombatTypography.RED, opacity * 0.38)
		CombatTypography.echo_word(canvas, "COUNTER", center, size, area.x * (0.93 if large else 0.72),
			CombatTypography.COUNTER.lerp(CombatTypography.PAPER, 0.30), opacity, 0.24)

func zoom() -> float:
	if reduced_motion or int(impact.get("impactTime", 0)) <= 0 or int(impact.get("impactTier", 0)) < 3: return 1.0
	var age: int = impact.impactDuration - impact.impactTime
	var enter := smoothstep(0.0, 4.0, age + 1)
	var leave := minf(1.0, float(impact.impactTime) / 24.0)
	return 1.0 + 0.10 * enter * leave
