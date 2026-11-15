extends Control

# Presentation-only title artwork. Reuses the combat atlases without starting a fight.
var anvil := Sprite2D.new()
var shark := Sprite2D.new()
const BRASS := GuildTheme.BRASS
const TEAL := Color("5ab5b5")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	custom_minimum_size = Vector2(640, 460)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	for fighter in [anvil, shark]:
		fighter.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(fighter)
	resized.connect(queue_redraw)

func _draw() -> void:
	var w := size.x
	var h := size.y
	var floor_y := h - 88.0
	# Cut planes and restrained speed lines echo the stock kit's chamfered corners.
	draw_colored_polygon(PackedVector2Array([Vector2(36, 48), Vector2(w * 0.62, 12), Vector2(w * 0.43, floor_y), Vector2(0, floor_y)]), Color("18262e"))
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.65, 12), Vector2(w, 48), Vector2(w, floor_y), Vector2(w * 0.47, floor_y)]), Color("15323a"))
	for i in 4:
		var y := 70.0 + i * 12.0
		draw_line(Vector2(42, y), Vector2(w * 0.40, y - 22), Color(0.87, 0.70, 0.42, 0.18), 1, true)
		draw_line(Vector2(w * 0.76, floor_y - y + 30), Vector2(w - 12, floor_y - y + 10), Color(0.35, 0.71, 0.71, 0.22), 1, true)
	draw_line(Vector2(w * 0.63, 28), Vector2(w * 0.45, floor_y - 12), Color(0.87, 0.70, 0.42, 0.5), 2, true)
	var vs_size := 118
	var vs_width := GuildTheme.SEMIBOLD.get_string_size("VS", HORIZONTAL_ALIGNMENT_LEFT, -1, vs_size).x
	draw_string(GuildTheme.SEMIBOLD, Vector2(w * 0.51 - vs_width * 0.5, h * 0.39), "VS", HORIZONTAL_ALIGNMENT_LEFT, -1, vs_size, Color(0.95, 0.92, 0.86, 0.55))
	FighterArt.apply(anvil, 0, "windup", 4, h * 0.59 / 150.0, 1)
	anvil.position = Vector2(w * 0.25, floor_y)
	FighterArt.apply(shark, 4, "windup", 4, h * 0.70 / 150.0, -1)
	shark.position = Vector2(w * 0.77, floor_y)
	nameplate("ANVIL", "BLACKSMITHS", Vector2(24, h - 64), w * 0.40, BRASS, false)
	nameplate("SHARK", "FISHERMEN", Vector2(w * 0.60, h - 64), w * 0.40 - 24, TEAL, true)

func nameplate(fighter: String, guild: String, origin: Vector2, width: float, accent: Color, right: bool) -> void:
	draw_line(origin - Vector2(0, 12), origin + Vector2(width, -12), accent, 2)
	var name_width := GuildTheme.SEMIBOLD.get_string_size(fighter, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
	var guild_width := GuildTheme.REGULAR.get_string_size(guild, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	draw_string(GuildTheme.SEMIBOLD, origin + Vector2(width - name_width if right else 0, 20), fighter, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, GuildTheme.IVORY)
	draw_string(GuildTheme.REGULAR, origin + Vector2(width - guild_width if right else 0, 42), guild, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, accent)
