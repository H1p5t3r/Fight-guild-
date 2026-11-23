class_name CombatAudio
extends Node

const DIRECTORY := "res://assets/audio/combat/"
static var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_audio.json"))
var volume := 0.65
var enabled := true
var cursor := -1
var epoch := -1
var streams := {}
var voices: Array[AudioStreamPlayer] = []
var voice_index := 0
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
		AudioServer.add_bus_effect(bus, AudioEffectLimiter.new())
	for _voice in 16:
		var player := AudioStreamPlayer.new()
		player.bus = "Combat"
		add_child(player)
		voices.append(player)

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

func play_cue(cue: Dictionary) -> void:
	if voices.is_empty(): return
	var key := sound_for(cue)
	var file := key + ".wav"
	if not streams.has(file): streams[file] = load(DIRECTORY + file)
	var voice := voices[voice_index]
	voice_index = (voice_index + 1) % voices.size()
	voice.stream = streams[file]
	# Variation is derived from event identity, so resimulation sounds the same.
	voice.pitch_scale = 0.97 + float((int(cue.serial) * 7 + int(cue.actor) * 3) % 7) * 0.01
	var gain := -14.0 + float(cue.strength) * 0.6
	if int(cue.kind) == 8: gain -= 5.0
	if int(cue.kind) == 9 and int(cue.strength) == 0: gain -= 6.0
	voice.volume_db = linear_to_db(volume) + gain
	voice.play()
	played += 1
	# Counter adds a low accent underneath the weapon's contact, not in its place.
	if int(cue.kind) == 3:
		var layer := cue.duplicate()
		layer.kind = 1
		play_cue(layer)
