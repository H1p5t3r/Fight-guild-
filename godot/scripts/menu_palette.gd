class_name MenuPalette
extends RefCounted

signal changed

# One shared guild palette per menu flow; never written into combat state.
var character := 5
var accent := FighterSelectPortrait.COLORS[5]

func set_fighter(index: int) -> void:
	index = clampi(index, 0, FighterSelectPortrait.COLORS.size() - 1)
	if character == index: return
	character = index
	accent = FighterSelectPortrait.COLORS[index]
	changed.emit()
