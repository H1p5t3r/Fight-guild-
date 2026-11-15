class_name MenuMotion
extends RefCounted

# Presentation time only: never participates in combat frames or rollback state.
const PREFERENCES := "user://preferences.cfg"
var reduced := false
var instant := false # Deterministic fixture setup; animated navigation is tested separately.

func load_preferences() -> void:
	if OS.get_cmdline_user_args().has("--test"): return
	var config := ConfigFile.new()
	if config.load(PREFERENCES) == OK:
		reduced = bool(config.get_value("menus", "reduced_motion", false))

func toggle_reduced() -> void:
	reduced = not reduced
	if OS.get_cmdline_user_args().has("--test"): return
	var config := ConfigFile.new()
	config.load(PREFERENCES)
	config.set_value("menus", "reduced_motion", reduced)
	config.save(PREFERENCES)

func duration(seconds: float) -> float:
	return 0.0 if instant else minf(seconds, 0.09) if reduced else seconds

func distance(pixels: float) -> float:
	return 0.0 if reduced or instant else pixels

static func interactive(control: Control, enabled: bool) -> void:
	# Disable the whole outgoing tree without changing real disabled/locked states.
	control.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED if enabled else Control.MOUSE_BEHAVIOR_DISABLED
	control.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED if enabled else Control.FOCUS_BEHAVIOR_DISABLED
