class_name FightHud
extends RefCounted

const INK := Color("081219")
const IVORY := GuildTheme.IVORY
const PLAYER_COLORS := [Color("e6b96e"), Color("7dcece")]
const TOP_CLEARANCE := 124.0
const PORTRAIT_SHEET = preload("res://assets/ui/fighter-portraits.png")
static var portraits := {}

static func cut(rect: Rect2, corner: float = 10.0) -> PackedVector2Array:
	var a := rect.position
	var b := rect.end
	var c := minf(corner, minf(rect.size.x, rect.size.y) * 0.45)
	return PackedVector2Array([a + Vector2(c, 0), Vector2(b.x, a.y), Vector2(b.x, b.y - c), b - Vector2(c, 0), Vector2(a.x, b.y), a + Vector2(0, c)])

static func plate(canvas: CanvasItem, rect: Rect2, fill: Color, stroke: Color, corner: float = 10.0, weight: float = 1.0) -> void:
	var points := cut(rect, corner)
	canvas.draw_colored_polygon(points, fill)
	points.append(points[0])
	canvas.draw_polyline(points, stroke, weight, true)

static func text(canvas: CanvasItem, value: String, point: Vector2, font_size: int, color: Color = IVORY, right: bool = false, outline: int = 0) -> void:
	var font := GuildTheme.SEMIBOLD
	if right: point.x -= font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	if outline > 0: canvas.draw_string_outline(font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline, Color(INK, color.a))
	canvas.draw_string(font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

static func centered(canvas: CanvasItem, value: String, point: Vector2, font_size: int, color: Color = IVORY, outline: int = 0) -> void:
	point.x -= GuildTheme.SEMIBOLD.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x * 0.5
	text(canvas, value, point, font_size, color, false, outline)

# u is remaining health measured from the timer toward the outside. The inner
# 30% descends eight pixels; damage clears the outer end toward the center.
static func health_point(rect: Rect2, u: float, y: float, right: bool) -> Vector2:
	return Vector2(rect.position.x + rect.size.x * u if right else rect.end.x - rect.size.x * u,
		rect.position.y + y + 8.0 * maxf(0.0, 1.0 - u / 0.30))

static func health_shape(rect: Rect2, right: bool, fraction: float = 1.0, corner: float = 7.0) -> PackedVector2Array:
	var cut_size := minf(corner, minf(rect.size.x * fraction, rect.size.y) * 0.45)
	var cut_u := cut_size / rect.size.x
	var result := PackedVector2Array([health_point(rect, 0, cut_size, right), health_point(rect, cut_u, 0, right)])
	if cut_u < 0.30 and fraction > 0.30: result.append(health_point(rect, 0.30, 0, right))
	result.append(health_point(rect, fraction, 0, right))
	result.append(health_point(rect, fraction, rect.size.y - cut_size, right))
	result.append(health_point(rect, fraction - cut_u, rect.size.y, right))
	if fraction - cut_u > 0.30: result.append(health_point(rect, 0.30, rect.size.y, right))
	result.append(health_point(rect, 0, rect.size.y, right))
	return result

static func draw_health(canvas: CanvasItem, rail: Rect2, health: int, guild: Color, right: bool) -> void:
	canvas.draw_colored_polygon(health_shape(Rect2(rail.position + Vector2(0, 4), rail.size), right), Color(0, 0, 0, 0.42))
	var outline := health_shape(rail, right)
	canvas.draw_colored_polygon(outline, guild.darkened(0.83))
	outline.append(outline[0])
	canvas.draw_polyline(outline, Color(IVORY, 0.6), 1.2, true)
	var inner := rail.grow(-2)
	var fraction := clampf(health / 1000.0, 0.0, 1.0)
	var fill_width := inner.size.x * fraction
	if fill_width < 0.5: return
	var shape := health_shape(inner, right, fraction, 4)
	var colors := PackedColorArray()
	for point in shape:
		colors.append(guild.lerp(guild.darkened(0.22), clampf((point.y - inner.position.y) / inner.size.y, 0, 1)))
	canvas.draw_polygon(shape, colors)
	if fill_width > 12:
		var highlight := PackedVector2Array([health_point(inner, 5 / inner.size.x, 3, right)])
		if fraction - 5 / inner.size.x > 0.30: highlight.append(health_point(inner, 0.30, 3, right))
		highlight.append(health_point(inner, fraction - 5 / inner.size.x, 3, right))
		canvas.draw_polyline(highlight, Color(IVORY, 0.65), 2, true)
	if fill_width > 5:
		canvas.draw_line(health_point(inner, fraction - 2 / inner.size.x, 3, right), health_point(inner, fraction - 2 / inner.size.x, inner.size.y - 3, right), IVORY, 2)

static func portrait(character: int) -> AtlasTexture:
	if not portraits.has(character):
		if character in [4, 5]:
			var result := AtlasTexture.new()
			result.atlas = PORTRAIT_SHEET
			result.region = Rect2(24 if character == 5 else 776, 112, 716 if character == 5 else 752, 808)
			result.filter_clip = true
			portraits[character] = result
			return result
		var source := FighterArt.texture(character, "windup", 0)
		var bounds: Array = FighterArt.sheet(character, "windup").frames[0].bounds
		var result := AtlasTexture.new()
		result.atlas = source.atlas
		result.region = Rect2(source.region.position + Vector2(bounds[0], bounds[1]), Vector2(bounds[2] - bounds[0], (bounds[3] - bounds[1]) * 0.34))
		result.filter_clip = true
		portraits[character] = result
	return portraits[character]

static func stamp(canvas: CanvasItem, value: String, center: Vector2, font_size: int, accent: Color, alpha: float = 1.0, inverted: bool = false) -> void:
	var available: float = canvas.size.x if canvas is Control else canvas.get_viewport_rect().size.x
	var width := minf(available * 0.84, CombatTypography.FONT.get_string_size(value.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 40)
	CombatTypography.rule(canvas, center + Vector2(0, font_size * 0.67), width, accent, alpha * 0.38)
	CombatTypography.echo_word(canvas, value.to_upper(), center, font_size, available * 0.84,
		accent if inverted else CombatTypography.PAPER, alpha, 0.42)

static func fighter_name(canvas: CanvasItem, value: String, point: Vector2, right: bool) -> void:
	var font := CombatTypography.FONT
	if right: point.x -= font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
	canvas.draw_string_outline(font, point + Vector2(1, 1), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 3, INK)
	canvas.draw_string(font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, IVORY)

static func draw(canvas: Control, state: Dictionary, wins: Array, round_call: String, diagnostics: bool) -> void:
	var scale_factor := minf(canvas.size.x / 1280.0, 1.0)
	var area := canvas.size / scale_factor
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * scale_factor)
	# A soft shade carries the lettering without boxing off the scene.
	canvas.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(area.x, 0), Vector2(area.x, 126), Vector2(0, 126)]),
		PackedColorArray([Color(INK, 0.70), Color(INK, 0.70), Color(INK, 0), Color(INK, 0)]))
	var center := area.x * 0.5
	var width := center - 170.0
	for p in 2:
		var fighter: Dictionary = state.players[p]
		var right := p == 1
		var accent: Color = PLAYER_COLORS[p]
		var guild: Color = FighterSelectPortrait.COLORS[fighter.character]
		var rail := Rect2(center + 64 if right else 106.0, 29, width, 31)
		draw_health(canvas, rail, fighter.health, guild, right)
		var name_x := rail.end.x - 19 if right else rail.position.x + 19
		fighter_name(canvas, str(CombatModel.CHARACTERS[fighter.character]).to_upper(), Vector2(name_x, 53), right)
		text(canvas, FighterSelectPortrait.GUILDS[fighter.character], Vector2(name_x, 20), 13, guild.lightened(0.24), right, 2)
		# Oversized cutout faces overlap the outer rail; no thumbnail card frames.
		var origin := Vector2(area.x - 126 if right else 4.0, 3)
		var crest := PackedVector2Array([origin + Vector2(4, 28), origin + Vector2(113, 14),
			origin + Vector2(118, 83), origin + Vector2(68, 119), origin + Vector2(8, 103)])
		canvas.draw_colored_polygon(crest, Color(INK, 0.78))
		canvas.draw_polyline(PackedVector2Array([origin + Vector2(9, 105), origin + Vector2(68, 121), origin + Vector2(116, 86)]), guild, 2.0, true)
		var bust := portrait(int(fighter.character))
		var image_size := bust.get_size() * minf(121.0 / bust.get_width(), 119.0 / bust.get_height())
		var image_rect := Rect2(origin + Vector2(61, 60) - image_size * 0.5, image_size)
		if right: image_rect.size.x = -image_rect.size.x
		canvas.draw_texture_rect(bust, image_rect, false)
		var detail := "P%d" % (p + 1)
		if fighter.simple: detail += " / SIMPLE"
		if diagnostics: detail += " / %d HP" % fighter.health
		text(canvas, "POSITIVE BONUS" if fighter.positiveTime > 0 else detail,
			Vector2(name_x, 80), maxi(13, ceili(11.0 / scale_factor)), Color("a8e9b1") if fighter.positiveTime > 0 else Color(IVORY, 0.7), right, 2)
		for mark in MatchScore.WINS_REQUIRED:
			var marker_x := rail.position.x + 12 + mark * 23 if right else rail.end.x - 12 - mark * 23
			var diamond := PackedVector2Array([Vector2(marker_x - 8, 77), Vector2(marker_x, 72), Vector2(marker_x + 8, 77), Vector2(marker_x, 82), Vector2(marker_x - 8, 77)])
			canvas.draw_colored_polygon(diamond, accent if wins[p] > mark else Color(INK, 0.75))
			canvas.draw_polyline(diamond, accent if wins[p] > mark else Color(IVORY, 0.40), 1.2, true)
			if wins[p] > mark: canvas.draw_line(Vector2(marker_x - 3, 77), Vector2(marker_x + 3, 77), IVORY, 1.5)
		var meter_width := center - 150.0
		draw_momentum(canvas, fighter, Rect2(center + 100 if right else 50.0, area.y - 25, meter_width, 15), accent, right, scale_factor)
	# Open timer dial: a compact sports instrument, not another panel.
	canvas.draw_circle(Vector2(center, 45), 41, Color(INK, 0.74), true, -1, true)
	for side in [-1, 1]:
		var angle := 0.0 if side == 1 else PI
		canvas.draw_arc(Vector2(center, 45), 43, angle - 0.86, angle + 0.86, 24, Color(IVORY, 0.72), 1.4, true)
		canvas.draw_line(Vector2(center + side * 48, 36), Vector2(center + side * 58, 36), Color(GuildTheme.BRASS, 0.75), 2.0, true)
	centered(canvas, "%02d" % ceili(state.remaining / 60.0), Vector2(center, 64), 53,
		Color("ed9a7f") if state.remaining <= 600 else IVORY, 3)
	centered(canvas, round_call.to_upper(), Vector2(center, 103), 15, GuildTheme.BRASS, 3)
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_momentum(canvas: CanvasItem, fighter: Dictionary, rail: Rect2, accent: Color, right: bool, ui_scale: float = 1.0) -> void:
	var color := Color("80e0bc") if fighter.faultless else accent
	var caption := "FAULTLESS DEFENSE" if fighter.faultless else "MOMENTUM"
	text(canvas, caption, Vector2(rail.end.x if right else rail.position.x, rail.position.y - 6), maxi(13, ceili(12.0 / ui_scale)), color, right, 2)
	text(canvas, "%.0f%%" % (fighter.momentum / 100.0), Vector2(rail.position.x if right else rail.end.x, rail.position.y - 6), maxi(15, ceili(14.0 / ui_scale)), IVORY, not right, 2)
	var section_width := (rail.size.x - 12.0) / 3.0
	for section in 3:
		var x := rail.position.x + (2 - section if right else section) * (section_width + 6)
		var cell := Rect2(x, rail.position.y, section_width, rail.size.y)
		plate(canvas, cell, Color(INK, 0.65), Color(color, 0.65), 4, 1)
		var fill := clampf(fighter.momentum * 3.0 / CombatModel.MOMENTUM_MAX - section, 0.0, 1.0)
		var inside := cell.grow(-2)
		var width := inside.size.x * fill
		if width > 0.5:
			canvas.draw_colored_polygon(cut(Rect2(inside.end.x - width if right else inside.position.x, inside.position.y, width, inside.size.y), 4), color)
			if width > 8: canvas.draw_line(Vector2(inside.end.x - width + 3 if right else inside.position.x + 3, inside.position.y + 2), Vector2(inside.end.x - 3 if right else inside.position.x + width - 3, inside.position.y + 2), Color(IVORY, 0.6), 1)
