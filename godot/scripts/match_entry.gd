class_name MatchEntry
extends Control

signal intros_finished
signal opening_finished
signal intermission_finished
signal canceled
signal failed(message: String)

const INTRO_POSES := [4, 4, 3, 1, 4, 2]
const ENTRANCES := [Vector2(0, -24), Vector2(52, 0), Vector2(0, 32), Vector2(-28, 0), Vector2(72, 0), Vector2(-64, 0)]
var motion := MenuMotion.new()
var phase := "hidden"
var elapsed := 0.0
var characters := [5, 4]
var round_number := 1
var practice := false
var repeat_match := false
var online := false
var intro_player := 0
var beat := 0
var load_progress := 0.0
var asset_paths: Array[String] = []
var abandoned_loads: Array[String] = []
var load_frames := 0
var loaded_at := -1.0
var sprites: Array[Sprite2D] = []
var back_button: Button
var skip_button: Button
var waiting_text := ""
var score_winner := 2
var score_points := [0, 0]
var next_call := ""

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	for _p in 2:
		var sprite := Sprite2D.new()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(sprite)
		sprites.append(sprite)
	back_button = action("Back", func(): canceled.emit())
	back_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	back_button.offset_left = 36
	back_button.offset_right = 146
	back_button.offset_top = -64
	back_button.offset_bottom = -24
	skip_button = action("Skip intros", request_skip)
	skip_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	skip_button.offset_left = -180
	skip_button.offset_right = -36
	skip_button.offset_top = -64
	skip_button.offset_bottom = -24
	resized.connect(queue_redraw)

func action(value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(110, 40)
	button.focus_mode = Control.FOCUS_NONE
	GuildTheme.apply(button, "secondary")
	button.pressed.connect(callback)
	add_child(button)
	return button

func begin(chosen: Array, number: int, is_practice: bool, is_online: bool, repeated: bool = false) -> void:
	cancel()
	characters = chosen.duplicate()
	round_number = number
	practice = is_practice
	online = is_online
	repeat_match = repeated
	visible = true
	modulate.a = 0.0 if not motion.instant else 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	MenuMotion.interactive(self, true)
	back_button.visible = true
	back_button.text = "Back"
	skip_button.visible = false
	load_progress = 0.0
	load_frames = 0
	loaded_at = -1.0
	asset_paths.clear()
	set_phase("loading")
	if motion.instant:
		finish_intros()
		return
	# Prepare selected fighters and every adjoining area before revealing the stage.
	var paths: Array[String] = ArenaStage.asset_paths()
	for character in characters:
		for stage in FighterArt.phase_names(character):
			paths.append(FighterArt.DIRECTORY + FighterArt.sheet(character, stage).file)
		if FighterArt.catalog().fighters[character].has("hook_weapon"):
			paths.append(FighterArt.DIRECTORY + FighterArt.catalog().fighters[character].hook_weapon.file)
	for path in paths:
		if path in asset_paths: continue
		asset_paths.append(path)
		abandoned_loads.erase(path)
		var status := ResourceLoader.load_threaded_get_status(path)
		if status not in [ResourceLoader.THREAD_LOAD_IN_PROGRESS, ResourceLoader.THREAD_LOAD_LOADED] and ResourceLoader.load_threaded_request(path) != OK:
			loading_failed("Could not prepare match artwork. Return and try again.")
			return

func cache_loaded(path: String) -> void:
	var resource := ResourceLoader.load_threaded_get(path)
	if path.begins_with(ArenaStage.DIRECTORY): ArenaStage.remember(path, resource)
	else: FighterArt.textures[path.trim_prefix(FighterArt.DIRECTORY)] = resource

func cancel() -> void:
	phase = "hidden"
	visible = false
	for sprite in sprites: sprite.visible = false
	for path in asset_paths:
		if path not in abandoned_loads: abandoned_loads.append(path)
	asset_paths.clear()

func drain_abandoned_loads() -> void:
	for path in abandoned_loads.duplicate():
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS: continue
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			cache_loaded(path)
		abandoned_loads.erase(path)

func _exit_tree() -> void:
	for path in asset_paths + abandoned_loads:
		if ResourceLoader.load_threaded_get_status(path) in [ResourceLoader.THREAD_LOAD_IN_PROGRESS, ResourceLoader.THREAD_LOAD_LOADED]:
			ResourceLoader.load_threaded_get(path)

func set_phase(next: String) -> void:
	phase = next
	elapsed = 0.0
	skip_button.visible = phase == "intro"
	queue_redraw()

func request_skip() -> void:
	if phase == "intro": finish_intros()

func finish_intros() -> void:
	set_phase("waiting")
	waiting_text = "Waiting for your rival's introduction…" if online else "Taking the field…"
	intros_finished.emit()

func begin_opening() -> void:
	beat = 0
	set_phase("opening")
	if practice or motion.instant: finish_opening()

func finish_opening() -> void:
	set_phase("ready")
	waiting_text = "Waiting for both players…" if online else "Ready."
	opening_finished.emit()

func begin_intermission(winner: int, points: Array, following: String) -> void:
	visible = true
	modulate.a = 1.0
	MenuMotion.interactive(self, true)
	mouse_filter = Control.MOUSE_FILTER_STOP
	score_winner = winner
	score_points = points.duplicate()
	next_call = following
	back_button.visible = true
	back_button.text = "Leave match"
	set_phase("score")
	if motion.instant: finish_intermission()

func finish_intermission() -> void:
	set_phase("round_wait")
	intermission_finished.emit()

func release() -> void:
	back_button.visible = false
	skip_button.visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	MenuMotion.interactive(self, false)
	set_phase("release")
	if motion.instant: cancel()

func loading_failed(message: String) -> void:
	cancel()
	failed.emit(message)

func loading_end() -> float:
	return maxf(motion.duration(0.3 if repeat_match else 0.65), loaded_at + motion.duration(0.18))

func release_seconds() -> float:
	return motion.duration(0.22) if practice else float(MatchCeremony.script().releaseSeconds)

func poll_loading() -> void:
	load_frames += 1
	var total := 0.0
	var complete := true
	for path in asset_paths:
		var progress := []
		var status := ResourceLoader.load_threaded_get_status(path, progress)
		if status in [ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE]:
			loading_failed("Match artwork could not be loaded. Return and try again.")
			return
		complete = complete and status == ResourceLoader.THREAD_LOAD_LOADED
		total += 1.0 if status == ResourceLoader.THREAD_LOAD_LOADED else float(progress[0]) if not progress.is_empty() else 0.0
	load_progress = total / maxf(1.0, asset_paths.size())
	if complete and loaded_at < 0.0: loaded_at = elapsed
	var end := loading_end()
	if not complete or load_frames < 2 or elapsed < end: return
	for path in asset_paths:
		cache_loaded(path)
	if practice or repeat_match:
		finish_intros()
	else:
		intro_player = 0
		set_phase("intro")

func _process(delta: float) -> void:
	drain_abandoned_loads()
	if phase == "hidden": return
	elapsed += delta
	match phase:
		"loading":
			modulate.a = smoothstep(0.0, motion.duration(0.22), elapsed)
			poll_loading()
		"intro":
			if elapsed >= float(MatchCeremony.script().introSeconds):
				if intro_player == 0:
					intro_player = 1
					set_phase("intro")
				else: finish_intros()
		"opening":
			if elapsed >= float(MatchCeremony.script().beatSeconds[beat]):
				if beat < 2:
					beat += 1
					elapsed = 0.0
				else: finish_opening()
		"release":
			if elapsed >= release_seconds(): cancel()
		"score":
			if elapsed >= float(MatchCeremony.script().intermissionSeconds): finish_intermission()
	queue_redraw()

func centered(value: String, center: Vector2, font_size: int, color: Color = GuildTheme.IVORY) -> void:
	var font := GuildTheme.SEMIBOLD
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string_outline(font, center - Vector2(width * 0.5, 0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color(0.02, 0.04, 0.05, color.a))
	draw_string(font, center - Vector2(width * 0.5, 0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	for sprite in sprites: sprite.visible = false
	if phase == "hidden": return
	var w := size.x
	var h := size.y
	var scale_factor := minf(w / 1280.0, h / 720.0)
	var left: Color = FighterSelectPortrait.COLORS[characters[0]]
	var right: Color = FighterSelectPortrait.COLORS[characters[1]]
	if phase in ["score", "round_wait"]:
		draw_intermission(scale_factor)
		return
	if phase in ["opening", "ready", "release"]:
		draw_opening(scale_factor)
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("081218"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, h * 0.15), Vector2(w * 0.67, h * 0.10), Vector2(w * 0.48, h * 0.87), Vector2(0, h * 0.91)]), Color(left, 0.13))
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.70, h * 0.10), Vector2(w, h * 0.15), Vector2(w, h * 0.91), Vector2(w * 0.51, h * 0.87)]), Color(right, 0.13))
	centered("FIGHT GUILD", Vector2(w * 0.5, h * 0.075), int(24 * scale_factor), GuildTheme.BRASS)
	if phase == "intro":
		draw_intro(scale_factor)
	else:
		var content_alpha := 1.0
		if phase == "loading" and loaded_at >= 0.0:
			var end := loading_end()
			content_alpha = 1.0 - smoothstep(end - motion.duration(0.18), end, elapsed)
		for p in 2:
			var character: int = characters[p]
			var x := w * (0.25 if p == 0 else 0.75)
			FighterArt.apply(sprites[p], character, "windup", 0, h * 0.41 / 150.0, 1 if p == 0 else -1)
			sprites[p].position = Vector2(x, h * 0.62)
			sprites[p].modulate = Color(1, 1, 1, content_alpha)
			sprites[p].visible = true
			centered(CombatModel.CHARACTERS[character].to_upper(), Vector2(x, h * 0.72), int(44 * scale_factor), Color(GuildTheme.IVORY, content_alpha))
			centered(FighterSelectPortrait.GUILDS[character], Vector2(x, h * 0.76), int(18 * scale_factor), Color(FighterSelectPortrait.COLORS[character], content_alpha))
		centered("VS", Vector2(w * 0.5, h * 0.48), int(80 * scale_factor), Color(GuildTheme.BRASS, content_alpha))
		if phase == "loading":
			var caption := "FIGHTERS READY" if load_progress >= 1.0 else "PREPARING THE FIELD"
			centered(caption, Vector2(w * 0.5, h * 0.84), int(20 * scale_factor), Color(GuildTheme.MUTED, content_alpha))
			draw_rect(Rect2(w * 0.3, h * 0.87, w * 0.4, 4 * scale_factor), Color(Color("2b3b43"), content_alpha))
			draw_rect(Rect2(w * 0.3, h * 0.87, w * 0.4 * load_progress, 4 * scale_factor), Color(GuildTheme.BRASS, content_alpha))
		else: centered(waiting_text, Vector2(w * 0.5, h * 0.85), int(21 * scale_factor), GuildTheme.MUTED)

func draw_intro(scale_factor: float) -> void:
	var w := size.x
	var h := size.y
	var character: int = characters[intro_player]
	var accent: Color = FighterSelectPortrait.COLORS[character]
	var duration: float = MatchCeremony.script().introSeconds
	var reveal := smoothstep(0.0, motion.duration(0.28), elapsed)
	var fade := 1.0 - smoothstep(duration - motion.duration(0.18), duration, elapsed)
	var text_alpha := minf(reveal, fade)
	var offset: Vector2 = ENTRANCES[character] * (1.0 - reveal) * scale_factor
	if motion.reduced: offset = Vector2.ZERO
	FighterArt.apply(sprites[intro_player], character, "windup", INTRO_POSES[character], h * 0.67 / 150.0, -1)
	sprites[intro_player].position = Vector2(w * 0.74, h * 0.84) + offset
	sprites[intro_player].modulate = Color(1, 1, 1, text_alpha)
	sprites[intro_player].visible = true
	var center_x := w * 0.28
	centered("PLAYER %02d / %s" % [intro_player + 1, FighterSelectPortrait.GUILDS[character]], Vector2(center_x, h * 0.37), int(22 * scale_factor), Color(accent, text_alpha))
	FightHud.stamp(self, CombatModel.CHARACTERS[character].to_upper(), Vector2(center_x, h * 0.47), int(76 * scale_factor), accent, text_alpha)
	centered(FighterSelectPortrait.LINES[character], Vector2(center_x, h * 0.59), int(27 * scale_factor), Color(accent, text_alpha))
	draw_line(Vector2(w * 0.10, h * 0.63), Vector2(w * (0.10 + 0.36 * reveal), h * 0.63), Color(accent, text_alpha), 3 * scale_factor)
	centered("Enter / A: skip introductions", Vector2(w * 0.5, h * 0.94), int(18 * scale_factor), GuildTheme.MUTED)

func draw_opening(scale_factor: float) -> void:
	var w := size.x
	var h := size.y
	if phase == "release":
		var curtain := 1.0 - smoothstep(0.0, motion.duration(0.22), elapsed)
		if practice:
			draw_rect(Rect2(Vector2.ZERO, size), Color(Color("081218"), curtain))
			return
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.045, 0.055, 0.48 * curtain))
		draw_rect(Rect2(0, 0, w, h * 0.10), Color(0.03, 0.07, 0.09, curtain))
		draw_rect(Rect2(0, h * 0.90, w, h * 0.10), Color(0.03, 0.07, 0.09, curtain))
		var end := release_seconds()
		var opacity := 1.0 - smoothstep(end - motion.duration(0.37), end, elapsed)
		var expansion := 1.0 if motion.reduced else 1.0 + 0.06 * (1.0 - smoothstep(0.0, motion.duration(0.20), elapsed))
		FightHud.stamp(self, str(MatchCeremony.script().releaseCall).to_upper(), Vector2(w * 0.5, h * 0.46), int(78 * scale_factor * expansion), GuildTheme.BRASS, opacity, true)
		return
	var duration: float = MatchCeremony.script().beatSeconds[beat]
	var reveal := 1.0 if phase == "ready" else smoothstep(0.0, motion.duration(0.20), elapsed)
	var fade := 1.0 if phase == "ready" or (online and beat == 2) else 1.0 - smoothstep(duration - motion.duration(0.15), duration, elapsed)
	var opacity := minf(reveal, fade)
	var veil := lerpf(1.0, 0.48, smoothstep(0.0, motion.duration(0.3), elapsed)) if beat == 0 else 0.48
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.045, 0.055, veil))
	draw_rect(Rect2(0, 0, w, h * 0.10), Color("081218"))
	draw_rect(Rect2(0, h * 0.90, w, h * 0.10), Color("081218"))
	var text: String = MatchCeremony.round_call(round_number) if beat == 2 else MatchCeremony.script().opening[beat]
	var font_size := 82 if beat == 2 else 44
	var y := h * 0.49 + motion.distance(12.0) * (1.0 - reveal)
	FightHud.stamp(self, text.to_upper() if beat == 2 else text, Vector2(w * 0.5, y - 22 * scale_factor), int(font_size * scale_factor), GuildTheme.BRASS, opacity)
	if phase == "ready":
		centered(waiting_text, Vector2(w * 0.5, h * 0.64), int(20 * scale_factor), GuildTheme.MUTED)

func draw_intermission(scale_factor: float) -> void:
	var w := size.x
	var h := size.y
	var reveal := 1.0 if phase == "round_wait" else smoothstep(0.0, motion.duration(0.22), elapsed)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.045, 0.055, 0.78 * reveal))
	var title := "EVEN GROUND" if score_winner == 2 else str(CombatModel.CHARACTERS[characters[score_winner]]).to_upper() + " CLAIMS THE SCRUM"
	FightHud.stamp(self, title, Vector2(w * 0.5, h * 0.32), int(48 * scale_factor), GuildTheme.BRASS if score_winner == 2 else FightHud.PLAYER_COLORS[score_winner], reveal)
	centered("%d  —  %d" % [score_points[0], score_points[1]], Vector2(w * 0.5, h * 0.52), int(86 * scale_factor), Color(GuildTheme.BRASS, reveal))
	var note := "DRAW · REPLAY " if score_winner == 2 else "UP NEXT · "
	centered(note + next_call, Vector2(w * 0.5, h * 0.65), int(26 * scale_factor), Color(GuildTheme.IVORY, reveal))
	if phase == "round_wait": centered("Waiting for your rival…", Vector2(w * 0.5, h * 0.75), int(20 * scale_factor), GuildTheme.MUTED)
