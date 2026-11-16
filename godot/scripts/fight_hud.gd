class_name FightHud
extends RefCounted

const INK := Color("081219")
const IVORY := GuildTheme.IVORY
const PLAYER_COLORS := [Color("e6b96e"), Color("7dcece")]
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
	canvas.draw_polyline(outline, guild.darkened(0.20), 2, true)
	var inner := rail.grow(-4)
	var fraction := clampf(health / 1000.0, 0.0, 1.0)
	var fill_width := inner.size.x * fraction
	if fill_width < 0.5: return
	canvas.draw_colored_polygon(health_shape(inner, right, fraction, 4), guild)
	if fill_width > 12:
		var highlight := PackedVector2Array([health_point(inner, 5 / inner.size.x, 3, right)])
		if fraction - 5 / inner.size.x > 0.30: highlight.append(health_point(inner, 0.30, 3, right))
		highlight.append(health_point(inner, fraction - 5 / inner.size.x, 3, right))
		canvas.draw_polyline(highlight, Color(IVORY, 0.65), 2, true)
	if fill_width > 5:
		canvas.draw_line(health_point(inner, fraction - 2 / inner.size.x, 3, right), health_point(inner, fraction - 2 / inner.size.x, inner.size.y - 3, right), IVORY, 2)

static func portrait(character: int) -> AtlasTexture:
	if not portraits.has(character):
		var source := FighterArt.texture(character, "windup", 0)
		var bounds: Array = FighterArt.sheet(character, "windup").frames[0].bounds
		var result := AtlasTexture.new()
		result.atlas = source.atlas
		result.region = Rect2(source.region.position + Vector2(bounds[0], bounds[1]), Vector2(bounds[2] - bounds[0], (bounds[3] - bounds[1]) * 0.58))
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
	if right: point.x -= font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, 31).x
	canvas.draw_string_outline(font, point + Vector2(2, 2), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 31, 3, INK)
	canvas.draw_string(font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, 31, IVORY)

static func draw(canvas: Control, state: Dictionary, wins: Array, round_call: String, diagnostics: bool) -> void:
	var scale_factor := minf(canvas.size.x / 1248.0, 1.0)
	var area := canvas.size / scale_factor
	var detail_size := maxi(14, ceili(12.0 / scale_factor))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * scale_factor)
	var width := (area.x - 244.0) * 0.5
	for p in 2:
		var fighter: Dictionary = state.players[p]
		var right := p == 1
		var x := area.x - width - 24 if right else 24.0
		var accent: Color = PLAYER_COLORS[p]
		var guild: Color = FighterSelectPortrait.COLORS[fighter.character]
		var panel := Rect2(x, 10, width, 64)
		plate(canvas, Rect2(panel.position + Vector2(0, 5), panel.size), Color(0, 0, 0, 0.35), Color(0, 0, 0, 0), 16)
		plate(canvas, panel, Color("11222c"), Color(guild, 0.7), 16, 1)
		var strip := Rect2(x + width - 6 if right else x, 25, 5, 35)
		canvas.draw_rect(strip, accent)
		var bust_x := x + width - 72 if right else x + 8
		plate(canvas, Rect2(bust_x, 16, 60, 53), Color(guild, 0.15), Color(guild, 0.42), 8)
		var bust := portrait(int(fighter.character))
		var image_size := bust.get_size() * minf(58.0 / bust.get_width(), 51.0 / bust.get_height())
		var image_rect := Rect2(Vector2(bust_x + 30, 41.5) - image_size * 0.5, image_size)
		if right: image_rect.size.x = -image_rect.size.x
		canvas.draw_texture_rect(bust, image_rect, false)
		var name_x := x + width - 86 if right else x + 86
		fighter_name(canvas, str(CombatModel.CHARACTERS[fighter.character]).to_upper(), Vector2(name_x, 43), right)
		text(canvas, FighterSelectPortrait.GUILDS[fighter.character], Vector2(name_x, 63), detail_size, guild, right)
		var badge_x := x + 11 if right else x + width - 42
		plate(canvas, Rect2(badge_x, 20, 30, 23), accent, Color(accent, 0.9), 5)
		centered(canvas, "P" + str(p + 1), Vector2(badge_x + 15, 37), 16, INK)
		var rail := Rect2(x, 81, width, 27)
		draw_health(canvas, rail, fighter.health, guild, right)
		var mode := "%d / 1000" % fighter.health if diagnostics else "SIMPLE + MOTIONS" if fighter.simple else "MOTION INPUTS"
		text(canvas, mode, Vector2(x + width if right else x, 135), detail_size, GuildTheme.MUTED, right)
		for mark in MatchScore.WINS_REQUIRED:
			var marker_x := x + 10 + mark * 23 if right else x + width - 10 - mark * 23
			var diamond := PackedVector2Array([Vector2(marker_x, 123), Vector2(marker_x + 7, 130), Vector2(marker_x, 137), Vector2(marker_x - 7, 130), Vector2(marker_x, 123)])
			canvas.draw_colored_polygon(diamond, accent if wins[p] > mark else Color("162730"))
			canvas.draw_polyline(diamond, accent if wins[p] > mark else Color("4b5c62"), 1.4, true)
			if wins[p] > mark: canvas.draw_circle(Vector2(marker_x, 130), 2, IVORY)
		draw_momentum(canvas, fighter, Rect2(x, area.y - 49, width, 23), accent, right)
	var center := area.x * 0.5
	plate(canvas, Rect2(center - 66, 10, 132, 100), INK, Color("687170"), 22, 2)
	plate(canvas, Rect2(center - 60, 16, 120, 88), Color("14242d"), Color(GuildTheme.BRASS, 0.40), 18)
	centered(canvas, round_call.to_upper(), Vector2(center, 36), 16, GuildTheme.BRASS)
	centered(canvas, "%02d" % ceili(state.remaining / 60.0), Vector2(center, 88), 55, Color("ed9a7f") if state.remaining <= 600 else IVORY, 2)
	centered(canvas, "PRACTICE" if diagnostics else "FIRST TO TWO", Vector2(center, 136), 12, GuildTheme.MUTED)
	centered(canvas, "F / G", Vector2(center, area.y - 24), 26, Color(GuildTheme.BRASS, 0.48))
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_momentum(canvas: CanvasItem, fighter: Dictionary, rail: Rect2, accent: Color, right: bool) -> void:
	var color := Color("80e0bc") if fighter.faultless else accent
	var caption := "FAULTLESS DEFENSE" if fighter.faultless else "MOMENTUM"
	text(canvas, caption, Vector2(rail.end.x if right else rail.position.x, rail.position.y - 9), 17, color, right)
	text(canvas, "%.0f%%" % (fighter.momentum / 100.0), Vector2(rail.position.x if right else rail.end.x, rail.position.y - 9), 21, IVORY, not right)
	var section_width := (rail.size.x - 12.0) / 3.0
	for section in 3:
		var x := rail.position.x + (2 - section if right else section) * (section_width + 6)
		var cell := Rect2(x, rail.position.y, section_width, rail.size.y)
		plate(canvas, cell, INK, Color(color, 0.50), 7, 1)
		var fill := clampf(fighter.momentum * 3.0 / CombatModel.MOMENTUM_MAX - section, 0.0, 1.0)
		var inside := cell.grow(-3)
		var width := inside.size.x * fill
		if width > 0.5:
			canvas.draw_colored_polygon(cut(Rect2(inside.end.x - width if right else inside.position.x, inside.position.y, width, inside.size.y), 4), color)
			if width > 8: canvas.draw_line(Vector2(inside.end.x - width + 3 if right else inside.position.x + 3, inside.position.y + 2), Vector2(inside.end.x - 3 if right else inside.position.x + width - 3, inside.position.y + 2), Color(IVORY, 0.6), 1)
