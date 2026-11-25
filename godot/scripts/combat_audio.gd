class_name CombatAudio
extends Node

const DIRECTORY := "res://assets/audio/combat-v2/"
static var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_audio_v2.json"))
var volume := 0.65
var enabled := true
var cursor := -1
var epoch := -1
var streams := {}
var voices: Array[AudioStreamPlayer] = []
var priorities: Array[int] = []
var orders: Array[int] = []
var identities: Array[String] = []
var played := 0
var was_audible := false

func _ready() -> void:
	var config := ConfigFile.new()
	if not OS.get_cmdline_user_args().has("--test") and config.load(MenuMotion.PREFERENCES) == OK:
		volume = clampf(float(config.get_value("audio", "volume", 0.65)), 0.0, 1.0)
		enabled = bool(config.get_value("audio", "enabled", true))
	if AudioServer.get_bus_index("Combat") < 0:
		AudioServer.add_bus()
		var bus := AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus, "Combat")
		var limiter := AudioEffectLimiter.new()
		limiter.ceiling_db = -1.0
		limiter.threshold_db = -4.0
		AudioServer.add_bus_effect(bus, limiter)
	for _voice in 16:
		var player := AudioStreamPlayer.new()
		player.bus = "Combat"
		add_child(player)
		voices.append(player)
		priorities.append(0)
		orders.append(0)
		identities.append("")
	# Load the small bank at match boot; the first hit must not hitch on disk IO.
	var bank: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY + "manifest.json"))
	for sample in bank.sounds:
		streams[str(sample.file)] = load(DIRECTORY + str(sample.file))
	for name in ["clamp","lift","fall","slam"]:
		var file: String = "../supers-v2/sky_foundry_"+str(name)+".wav"
		streams[file] = load(DIRECTORY+file)

func save_preferences() -> void:
	if OS.get_cmdline_user_args().has("--test"): return
	var config := ConfigFile.new()
	config.load(MenuMotion.PREFERENCES)
	config.set_value("audio", "volume", volume)
	config.set_value("audio", "enabled", enabled)
	config.save(MenuMotion.PREFERENCES)

func silence() -> void:
	for voice in voices: voice.stop()

func consume(model: CombatModel, through: int, audible: bool) -> void:
	if epoch != model.cues.epoch:
		epoch = model.cues.epoch
		cursor = -1
		silence()
	if not audible or not enabled or volume <= 0:
		cursor = model.frame() - 1
		if was_audible: silence()
		was_audible = false
		return
	was_audible = true
	if through < cursor: return # Confirmed input is monotonic within a round.
	# Never burst a long backlog after focus loss, a debugger stall or a seek.
	for tick in range(maxi(cursor + 1, through - 5), through + 1):
		for cue in model.cues.events_at(tick): play_cue(cue)
	cursor = through

static func sound_for(cue: Dictionary) -> String:
	var kind := int(cue.kind)
	var fixed: Dictionary = manifest.kinds
	if fixed.has(str(kind)): return str(fixed[str(kind)])
	var character: Dictionary = manifest.characters[int(cue.character)]
	var family: String = character.moves.get(str(cue.move), character.family)
	return "swing_" + family if kind == 8 else "hit_" + family

static func layers(cue: Dictionary) -> Array:
	if cue.has("sound"):
		return [{"key":"super_motion","file":str(cue.sound),"gain":-9.0,"pitch":1.0,"priority":3}]
	if SuperAnimation.enabled and int(cue.character)==0 and int(cue.move)==16 and int(cue.kind) in [1,3,4]:
		return [{"key":"super_slam","file":"../supers-v2/sky_foundry_slam.wav","gain":-7.0,"pitch":1.0,"priority":4}]
	var key := sound_for(cue)
	var kind := int(cue.kind)
	var strength := clampi(int(cue.strength), 0, 4)
	# Unlike serial * 7 modulo 7, this actually varies consecutive attacks.
	var identity := absi(int(cue.get("serial", 0)) * 13 + int(cue.actor) * 5 + int(cue.move) * 3)
	var pitch := 0.97 + float(identity % 7) * 0.01
	var priority := 1 if kind in [8, 9] else 4 if kind in [3, 5, 11] else 3
	var gain := -11.5 + strength * 1.1
	if kind == 8: gain = -18.0 + strength * 0.65
	if kind == 9: gain = -19.0 + strength
	var result := [{"key": key, "gain": gain, "pitch": pitch, "priority": priority}]
	if kind == 3:
		var hit := cue.duplicate(); hit.kind = 1
		result.append({"key": sound_for(hit), "gain": -9.0 + strength * 0.7, "pitch": pitch, "priority": 4})
	elif (kind in [1, 4] and strength >= 3) or kind == 5:
		result.append({"key": "heavy", "gain": -14.0 + strength * 0.5, "pitch": 1.0, "priority": priority})
	for layer in result:
		var count := 3 if str(layer.key).begins_with("hit_") else 2
		var variant := identity % count
		layer.file = str(layer.key) + ("_%d" % (variant + 1) if variant else "") + ".wav"
	return result

func select_voice(priority: int) -> int:
	var candidate := -1
	for i in voices.size():
		if not voices[i].playing: return i
		if priorities[i] > priority: continue
		if candidate < 0 or priorities[i] < priorities[candidate] or (priorities[i] == priorities[candidate] and orders[i] < orders[candidate]): candidate = i
	return candidate

func play_cue(cue: Dictionary) -> void:
	if voices.is_empty() or not enabled or volume <= 0: return
	var identity := "%d:%d" % [int(cue.actor), int(cue.get("serial", 0))]
	if int(cue.kind) in [1, 2, 3, 4, 5, 6, 7]:
		# A confirmed impact cuts its own release tail, keeping rapid strings dry.
		for i in voices.size():
			if priorities[i] == 1 and identities[i] == identity: voices[i].stop()
	for layer in layers(cue):
		var index := select_voice(int(layer.priority))
		if index < 0: continue # A quiet swing never steals a big confirmed impact.
		var voice := voices[index]
		voice.stream = streams.get(str(layer.file))
		if voice.stream == null: continue
		priorities[index] = int(layer.priority)
		orders[index] = played
		identities[index] = identity
		voice.pitch_scale = float(layer.pitch)
		voice.volume_db = linear_to_db(volume) + float(layer.gain)
		voice.play()
		played += 1
