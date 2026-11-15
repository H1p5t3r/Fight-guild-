class_name MatchCeremony
extends RefCounted

# Editable presentation copy/timing. Combat rules and snapshots do not use this data.
static var data: Dictionary = {}

static func script() -> Dictionary:
	if data.is_empty():
		data = JSON.parse_string(FileAccess.get_file_as_string("res://data/match_ceremony.json"))
	return data

static func round_call(number: int) -> String:
	return str(script().roundCalls[clampi(number - 1, 0, 2)])
