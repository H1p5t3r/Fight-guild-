class_name ExtensionData
extends RefCounted

const ACTION_WORDS := 714
const CHARACTER_WORDS := 947
const REGIONS := ["legs", "torsoArms", "head", "extension"]
static var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/extension_layout.json"))
static var default_art: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/extension_art.json"))

static func integer(v: Variant) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and float(int(v)) == float(v) and abs(v) <= 1000000

static func allowed(value: Variant, names: Array) -> bool:
	if not value is Dictionary: return false
	for key in value:
		if not key in names: return false
	return true

static func body(value: Variant) -> Array:
	if not allowed(value, REGIONS): return []
	var result := [0]
	for i in 4:
		var b: Variant = value.get(REGIONS[i])
		if b == null:
			result.append_array([0, 0, 0, 0])
		else:
			if not b is Array or b.size() != 4: return []
			for v in b:
				if not integer(v): return []
			if b[0] >= b[2] or b[1] >= b[3]: return []
			result[0] |= 1 << i
			result.append_array(b)
	return result

static func pack(value: Variant, character := false) -> PackedInt32Array:
	var result := PackedInt32Array()
	if value == null:
		result.resize(CHARACTER_WORDS if character else ACTION_WORDS)
		return result
	var names: Array = ["version", "params", "profiles", "pairTracks", "art"] if character else ["version", "params", "routes", "hurtboxes", "pushboxes", "rootTrack", "verticalRootKeys", "art"]
	if not allowed(value, names) or value.get("version") != 1: return result
	var parameters: Array = layout.characterParams if character else layout.actionParams
	if not allowed(value.get("params"), parameters): return result
	for name in parameters:
		if not integer(value.params.get(name)): return PackedInt32Array()
		result.append(int(value.params[name]))
	if result[0] != 1 and not (character and result[0] == 2): return PackedInt32Array()
	if value.has("art") and not value.art is Dictionary: return PackedInt32Array()
	if character:
		if not allowed(value.get("profiles"), layout.profiles): return PackedInt32Array()
		for name in layout.profiles:
			var b := body(value.profiles.get(name))
			if b.is_empty(): return PackedInt32Array()
			result.append_array(PackedInt32Array(b))
		if not value.get("pairTracks") is Array or value.pairTracks.size() != 4: return PackedInt32Array()
		for track in value.pairTracks:
			if not track is Array or track.size() < 2 or track.size() > 8: return PackedInt32Array()
			result.append(track.size())
			for key in track:
				if not allowed(key, ["tick", "owner", "victim"]) or not integer(key.get("tick")): return PackedInt32Array()
				result.append(int(key.tick))
				for role in ["owner", "victim"]:
					if not key.get(role) is Array or key[role].size() != 2: return PackedInt32Array()
					for v in key[role]:
						if not integer(v): return PackedInt32Array()
						result.append(int(v))
			for _i in (8-track.size())*5: result.append(0)
	else:
		if not allowed(value.get("routes"), layout.routeNames): return PackedInt32Array()
		for name in layout.routeNames:
			var route: Variant = value.routes.get(name)
			if not route is Array: return PackedInt32Array()
			var mask: int = 0
			for slot in route:
				if not integer(slot) or slot < 0 or slot >= 47 or (mask & (1 << int(slot))): return PackedInt32Array()
				mask |= 1 << int(slot)
			result.append(mask & 0xffffffff)
			result.append(mask >> 32)
		for section in [["hurtboxes", 32, 18, ["frame", "boxes"]], ["pushboxes", 8, 5, ["frame", "box"]], ["rootTrack", 8, 5, ["first", "last", "dx", "dy", "collision"]], ["verticalRootKeys", 8, 2, ["frame", "y"]]]:
			var track: Variant = value.get(section[0])
			if not track is Array or track.size() > section[1]: return PackedInt32Array()
			result.append(track.size())
			for key in track:
				if not allowed(key, section[3]): return PackedInt32Array()
				var values: Array = []
				if section[0] == "hurtboxes":
					var b := body(key.get("boxes"))
					if b.is_empty(): return PackedInt32Array()
					values = [key.get("frame")]; values.append_array(b)
				elif section[0] == "pushboxes":
					if not key.get("box") is Array or key.box.size() != 4: return PackedInt32Array()
					values = [key.get("frame")]; values.append_array(key.box)
				else:
					for field in section[3]: values.append(key.get(field))
				for v in values:
					if not integer(v): return PackedInt32Array()
					result.append(int(v))
			for _i in (section[1]-track.size())*section[2]: result.append(0)
	return result

static func unpack_body(v: PackedInt32Array) -> Dictionary:
	var result := {}
	for i in 4:
		if v[0] & (1 << i): result[REGIONS[i]] = Array(v.slice(1+i*4, 5+i*4))
	return result

static func unpack(v: PackedInt32Array, character := false, art: Dictionary = {}) -> Dictionary:
	if v.is_empty() or not v[0]: return {}
	var parameters: Array = layout.characterParams if character else layout.actionParams
	var result := {"version": 1, "params": {}}
	for i in parameters.size(): result.params[parameters[i]] = v[i]
	var at := parameters.size()
	if character:
		result.profiles = {}
		for name in layout.profiles:
			result.profiles[name] = unpack_body(v.slice(at, at+17)); at += 17
		result.pairTracks = []
		for _n in 4:
			var count := v[at]; at += 1
			var track := []
			for i in 8:
				if i < count: track.append({"tick": v[at], "owner": Array(v.slice(at+1, at+3)), "victim": Array(v.slice(at+3, at+5))})
				at += 5
			result.pairTracks.append(track)
	else:
		result.routes = {}
		for name in layout.routeNames:
			var route := []
			for i in 47:
				if v[at+i/32] & (1 << (i%32)): route.append(i)
			result.routes[name] = route; at += 2
		for section in [["hurtboxes", 32, 18], ["pushboxes", 8, 5], ["rootTrack", 8, 5], ["verticalRootKeys", 8, 2]]:
			var count := v[at]; at += 1
			var track := []
			for i in section[1]:
				if i < count:
					var key := {}
					match section[0]:
						"hurtboxes": key = {"frame": v[at], "boxes": unpack_body(v.slice(at+1, at+18))}
						"pushboxes": key = {"frame": v[at], "box": Array(v.slice(at+1, at+5))}
						"rootTrack": key = {"first": v[at], "last": v[at+1], "dx": v[at+2], "dy": v[at+3], "collision": v[at+4]}
						"verticalRootKeys": key = {"frame": v[at], "y": v[at+1]}
					track.append(key)
				at += section[2]
			result[section[0]] = track
	if not art.is_empty(): result.art = art.duplicate(true)
	return result
