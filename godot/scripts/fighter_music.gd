class_name FighterMusic
extends Node

const CATALOG_PATH := "res://data/fighter_music.json"
const DIRECTORY := "res://assets/audio/themes/"
const CROSSFADE_SECONDS := 0.65
var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
var enabled := true
var volume := 0.55
# 0/1 follow P1/P2; 2..7 choose a particular fighter's theme.
var source := 0
var matchup := [5, 4]
var match_active := false
var dimmed := false
var focused := true
var previewing := false
var current_character := -1
var voices: Array[AudioStreamPlayer] = []
var characters := [-1, -1]
var levels := [0.0, 0.0]
var streams := {}
var duck := 1.0

func _ready() -> void:
	if not OS.get_cmdline_user_args().has("--test"):
		var config := ConfigFile.new()
		if config.load(MenuMotion.PREFERENCES) == OK: read_preferences(config)
	if AudioServer.get_bus_index("Music") < 0:
		AudioServer.add_bus()
		var bus := AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus, "Music")
		AudioServer.add_bus_effect(bus, AudioEffectLimiter.new())
	for i in 2:
		var voice := AudioStreamPlayer.new()
		voice.bus = "Music"
		voice.volume_db = -80.0
		add_child(voice)
		voices.append(voice)

func _exit_tree() -> void:
	for voice in voices: release_voice(voice)
	streams.clear()

func release_voice(voice: AudioStreamPlayer) -> void:
	# Resume before stopping so the audio mixer can retire paused decoders too.
	voice.stream_paused = false
	voice.stop()
	voice.stream = null

func read_preferences(config: ConfigFile) -> void:
	enabled = bool(config.get_value("music", "enabled", true))
	volume = clampf(float(config.get_value("music", "volume", 0.55)), 0.0, 1.0)
	source = clampi(int(config.get_value("music", "source", 0)), 0, 7)

func write_preferences(config: ConfigFile) -> void:
	config.set_value("music", "enabled", enabled)
	config.set_value("music", "volume", volume)
	config.set_value("music", "source", source)

func save_preferences() -> void:
	if OS.get_cmdline_user_args().has("--test"): return
	var config := ConfigFile.new()
	config.load(MenuMotion.PREFERENCES)
	write_preferences(config)
	config.save(MenuMotion.PREFERENCES)

func set_enabled(value: bool) -> void:
	enabled = value
	save_preferences()
	apply_output()

func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	save_preferences()
	apply_output()

func set_source(value: int) -> void:
	source = clampi(value, 0, 7)
	save_preferences()
	refresh_request()

func selected_character() -> int:
	return clampi(int(matchup[source]), 0, 5) if source < 2 else source - 2

func track(character: int) -> Dictionary:
	return catalog.tracks[clampi(character, 0, 5)]

func stream_for(character: int) -> AudioStreamOggVorbis:
	if not streams.has(character):
		var stream := load(DIRECTORY + str(track(character).file)) as AudioStreamOggVorbis
		stream.loop = true
		stream.loop_offset = 0.0
		streams[character] = stream
	return streams[character]

func update_context(active: bool, chosen: Array, subdued: bool, has_focus: bool) -> void:
	match_active = active
	matchup = chosen.duplicate()
	dimmed = subdued
	focused = has_focus
	refresh_request()
	apply_output()

func preview_theme() -> void:
	previewing = true
	refresh_request()

func end_preview() -> void:
	previewing = false
	refresh_request()

func refresh_request() -> void:
	var requested := selected_character() if match_active or previewing else -1
	if requested == current_character: return
	current_character = requested
	if requested < 0: return # Existing voices fade out in _process.
	var slot := characters.find(requested)
	if slot >= 0 and voices[slot].playing: return # Resume an interrupted crossfade.
	slot = 0 if float(levels[0]) <= float(levels[1]) else 1
	release_voice(voices[slot])
	characters[slot] = requested
	levels[slot] = 0.0
	voices[slot].volume_db = -80.0
	voices[slot].stream = stream_for(requested)
	voices[slot].play()
	apply_output()

func apply_output() -> void:
	var muted := not enabled or volume <= 0.0 or not focused
	for i in voices.size():
		voices[i].stream_paused = muted
		voices[i].volume_db = linear_to_db(maxf(0.0001, volume * float(levels[i]) * duck))

func _process(delta: float) -> void:
	# Music is not driven by combat ticks: hitstop, supers, training frame-step,
	# rollback and round reset cannot replay or interrupt a song.
	duck = move_toward(duck, 0.5 if dimmed and not previewing else 1.0, delta * 2.0)
	for i in voices.size():
		var wanted: bool = characters[i] == current_character and current_character >= 0
		levels[i] = move_toward(float(levels[i]), 1.0 if wanted else 0.0, delta / CROSSFADE_SECONDS)
		if not wanted and float(levels[i]) == 0.0 and voices[i].playing:
			release_voice(voices[i])
			characters[i] = -1
	apply_output()
