extends Control

const Arena = preload("res://scripts/arena.gd")
const SAVE_PATH := "user://moves.json"
const ACCENT := GuildTheme.BRASS
const MUTED := GuildTheme.MUTED
var fighter_inputs := FighterInputs.new()
var application_focused := true
var model := CombatModel.new()
var connection := NativePeer.new()
var characters := [5, 4]
var held := {}
var paused := false
var show_boxes := true
var history: Array[String] = []
var last_raw := 0
var arena: Control
var input_label: Label
var action_label: Label
var editor_status: Label
var net_status: Label
var trial_status: Label
var mode: OptionButton
var dummy: OptionButton
var edit_character: OptionButton
var edit_move: OptionButton
var fields := {}
var buffer_fields: Array[SpinBox] = []
var momentum_fields := {}
var recovery_fields := {}
var combo_fields := {}
var movement_fields := {}
var jump_fields := {}
var tuning_fields := {}
var training_momentum: OptionButton
var kit_button: Button
var editor_title: Label
var routes: Label
var pause_button: Button
var locked_buttons: Array[Button] = []
var file_dialog: FileDialog
var importing := false
var address: LineEdit
var port: SpinBox
var leave_button: Button
var menus: GameMenus
var match_entry: MatchEntry
var pause_tableau: PauseTableau
var round_number := 1
var match_score := MatchScore.new()
var round_resolved := false
var entry_accept_released := false
var screen := "home"
var activity := "development"
var pending_activity := "development"
var selection_return := "home"
var sides_return := "matches"
var input_release_required := false
var motion := MenuMotion.new()
var layer_tween: Tween
var layer_target := "menus"
var play_root: Control
var play_margins: MarginContainer
var play_header: HBoxContainer
var editor_shell: PanelContainer
var toolbar: HBoxContainer
var practice: HBoxContainer
var diagnostics: VBoxContainer
var inputs: HBoxContainer
var keyboard_hint: Label
var activity_title: Label
var activity_subtitle: Label
var activity_badge: Label
var sprite_button: Button
var fighter_button: Button
var lab := TrainingLab.new()
var lab_window: Window
var timeline: FrameTimeline
var lab_status: Label
var combat_audio := CombatAudio.new()
var fighter_music := FighterMusic.new()
var super_freeze: SuperFreeze
var super_preview_player := -1
var super_preview_tick := 0
var super_preview_duration := SuperFreeze.DEFAULT_TICKS
var super_preview_background: Texture2D

func _ready() -> void:
	name = "FightGuild"
	add_child(combat_audio)
	add_child(fighter_music)
	motion.load_preferences()
	build_theme()
	build_interface()
	add_child(fighter_inputs)
	fighter_inputs.changed.connect(refresh_input_hint)
	fighter_inputs.controller_lost.connect(on_controller_lost)
	refresh_input_hint()
	connection.manual_presentation = true
	add_child(connection)
	connection.status_changed.connect(func(message: String): net_status.text = message)
	connection.match_preparing.connect(on_network_preparing)
	connection.countdown_started.connect(func(): match_entry.begin_opening())
	connection.match_started.connect(on_network_started)
	connection.match_ended.connect(on_network_ended)
	if not OS.get_cmdline_user_args().has("--test"):
		load_workshop_draft()
	if FileAccess.file_exists(SAVE_PATH) and not OS.get_cmdline_user_args().has("--test"):
		var error := model.load_file(SAVE_PATH)
		editor_status.text = "Loaded your saved move set." if error.is_empty() else error
	populate_editor()
	show_screen("home")
	if OS.get_cmdline_user_args().has("--verify-build"):
		call_deferred("verify_build")

func load_workshop_draft() -> void:
	var batch: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	if not batch is Dictionary or not batch.get("file") is String:
		editor_status.text = "Workshop batch could not be read."
		return
	var error := model.load_file("res://data/workshop/" + batch.file)
	editor_status.text = error if not error.is_empty() else str(batch.label) + " · work in progress"
	if error.is_empty():
		populate_editor()
		reset_round()

func verify_build() -> void:
	var verification = load("res://scripts/build_verification.gd").new()
	await verification.run(get_tree(), self)

func build_theme() -> void:
	theme = GuildTheme.stock()

func label(parent: Node, text: String, font_size: int = 13, color: Color = GuildTheme.IVORY) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", maxi(17, font_size))
	if font_size >= 22: node.add_theme_font_override("font", GuildTheme.SEMIBOLD)
	node.add_theme_color_override("font_color", color)
	parent.add_child(node)
	return node

func button(parent: Node, text: String, action: Callable, lock_during_online: bool = false, family: String = "secondary") -> Button:
	var node := Button.new()
	node.text = text
	GuildTheme.apply(node, family)
	node.pressed.connect(action)
	node.pressed.connect(release_focus_from_ui)
	parent.add_child(node)
	if lock_during_online:
		locked_buttons.append(node)
	return node

func option(parent: Node, caption: String, values: Array, selected: int = 0) -> OptionButton:
	var column := VBoxContainer.new()
	parent.add_child(column)
	if not caption.is_empty(): label(column, caption, 11, MUTED)
	var node := OptionButton.new()
	node.custom_minimum_size.y = 38
	for value in values: node.add_item(str(value))
	node.selected = selected
	column.add_child(node)
	return node

func row(parent: Node) -> HBoxContainer:
	var node := HBoxContainer.new()
	parent.add_child(node)
	return node

func panel(parent: Node) -> VBoxContainer:
	var shell := PanelContainer.new()
	parent.add_child(shell)
	var column := VBoxContainer.new()
	shell.add_child(column)
	return column

func build_interface() -> void:
	play_root = Control.new()
	play_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(play_root)
	play_root.visible = false
	play_root.modulate.a = 0.0
	MenuMotion.interactive(play_root, false)
	var margins := MarginContainer.new()
	play_margins = margins
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]: margins.add_theme_constant_override("margin_" + edge, 16)
	play_root.add_child(margins)
	var root := VBoxContainer.new()
	margins.add_child(root)
	var header := row(root)
	play_header = header
	var brand := label(header, "FG   FIGHT GUILD", 23, ACCENT)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	activity_badge = label(header, "DEVELOPMENT", 11, MUTED)
	fighter_button = button(header, "Fighter select", func(): choose_activity(activity), true)
	sprite_button = button(header, "Sprite review", show_sprite_review)
	button(header, "Controls", show_controls)
	button(header, "Menu · Esc", open_pause)
	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(content)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(left)
	activity_title = label(left, "Find the fight.", 31)
	activity_subtitle = label(left, "Play a route. Tune a move. Run it back.", 13, MUTED)
	toolbar = row(left)
	mode = option(toolbar, "", ["Training", "Local versus"])
	mode.item_selected.connect(func(_i: int): reset_round(); dummy.disabled = mode.selected == 1; training_momentum.disabled = mode.selected == 1)
	dummy = option(toolbar, "", ["Stand", "Guard all", "Crouch guard", "Practice sequence", "Faultless guard", "Attack loop", "Guard → reversal", "Player 2 controls"])
	dummy.tooltip_text = "Attack loop repeats Hs. Guard → reversal buffers an enabled grounded special as blockstun ends, preferring moves marked for reversal timing."
	button(toolbar, "Hitboxes", func(): show_boxes = not show_boxes)
	pause_button = button(toolbar, "Pause", func(): paused = not paused; pause_button.text = "Resume" if paused else "Pause", true)
	button(toolbar, "+1 frame", advance_one, true)
	button(toolbar, "Reset", reset_round, true)
	practice = row(left)
	training_momentum = option(practice, "", ["Start Momentum: 0%", "Start Momentum: 50%", "Start Momentum: 100%"])
	training_momentum.item_selected.connect(func(_i: int): reset_round())
	button(practice, "Record", record_exchange, true)
	button(practice, "Stop", func(): lab.stop(), true)
	button(practice, "Replay", func(): replay_exchange(false), true)
	button(practice, "Frame lab", open_frame_lab, true)
	var super_menu := MenuButton.new()
	super_menu.text = "Super cut-in"
	super_menu.tooltip_text = "Preview the freeze presentation only. F8: P1 · Shift+F8: P2. No attack or Momentum cost."
	GuildTheme.apply(super_menu, "secondary")
	super_menu.get_popup().add_item("Preview Player 1 · F8", 0)
	super_menu.get_popup().add_item("Preview Player 2 · Shift+F8", 1)
	super_menu.get_popup().id_pressed.connect(preview_super_freeze)
	practice.add_child(super_menu)
	locked_buttons.append(super_menu)
	arena = Arena.new()
	left.add_child(arena)
	super_freeze = SuperFreeze.new()
	arena.add_child(super_freeze)
	arena.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed: release_focus_from_ui())
	inputs = row(left)
	input_label = label(inputs, "INPUT HISTORY   —", 12, ACCENT)
	input_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_label = label(inputs, "READY", 12, MUTED)
	keyboard_hint = label(left, "WASD move · J / K / L / I / O attack · Space dash · Back + Q FD", 11, MUTED)
	keyboard_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	editor_shell = PanelContainer.new()
	editor_shell.custom_minimum_size.x = 352
	content.add_child(editor_shell)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	editor_shell.add_child(scroll)
	var editor := VBoxContainer.new()
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(editor)
	label(editor, "MAKE IT YOURS", 10, MUTED)
	label(editor, "Move editor", 25)
	label(editor, "Apply a change, reset, and test it immediately.", 11, MUTED)
	var pickers := row(editor)
	edit_character = option(pickers, "Character", CombatModel.CHARACTERS, 5)
	edit_move = option(pickers, "Move", CombatModel.MOVE_IDS)
	edit_character.item_selected.connect(func(_i: int): populate_editor())
	edit_move.item_selected.connect(func(_i: int): populate_editor())
	editor_title = label(editor, "5P / NORMAL", 22, ACCENT)
	kit_button = button(editor, "Body keys, paired captures & kit routes", show_kit_editor, true)
	label(editor, "FRAME DATA", 11, MUTED)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	editor.add_child(grid)
	for spec in [["startup","Startup",2,120,1],["active","Active",1,120,1],["recovery","Recovery",0,180,1],["damage","Damage",0,1000,1],["hitstun","Hitstun",0,180,1],["blockstun","Blockstun",0,180,1],["hitstop","Hitstop",0,30,1],["advance","Advance (px)",-100,100,100],["hitboxBack","Hitbox back (px)",-500,500,100],["reach","Hitbox front (px)",1,500,100],["bottom","Bottom (px)",-500,500,100],["height","Height (px)",1,500,100],["chipDamage","Chip damage",0,1000,1],["counterHitstun","Counter +stun",0,60,1],["counterHitstop","Counter +stop",0,30,1]]:
		add_field(grid, spec)
	var timing_panel := VBoxContainer.new()
	editor.add_child(timing_panel)
	timing_panel.visible = false
	button(editor, "Cancels, scaling & landing ▾", func(): timing_panel.visible = not timing_panel.visible)
	var timing_grid := GridContainer.new()
	timing_grid.columns = 2
	timing_panel.add_child(timing_grid)
	for spec in [["normalCancelStart","Normal open f",1,420,1],["normalCancelEnd","Normal close f",0,420,1],["specialCancelStart","Special open f",1,420,1],["specialCancelEnd","Special close f",0,420,1],["jumpCancelStart","Jump open f",1,420,1],["jumpCancelEnd","Jump close f",0,420,1],["followCancelStart","Follow-up open f",1,420,1],["followCancelEnd","Follow-up close f",0,420,1],["cancelOn","Cancel events mask",0,7,1],["starterProration","Starter %",0,100,1],["comboScaling","Scaling cost %",0,100,1],["minimumDamage","Minimum damage %",0,100,1],["landingRecovery","Landing recovery f",0,120,1],["attackLevel","Attack level",-1,4,1],["counterTier","Counter tier",-1,3,1],["counterVulnerable","Counter phases mask",0,7,1],["counterFreezeFrames","Counter freeze f (-1: add)",-1,60,1],["counterSlowFrames","Counter half-speed f",0,120,1]]:
		add_field(timing_grid, spec)
	var timing_note := label(timing_panel, "Windows use completed move frames; close 0 = end of move. Cancel events: hit 1 + block 2 + whiff 4. Routes still apply. Counter phases: startup 1 + active 2 + recovery 4. Preset −1 keeps custom values.", 11, MUTED)
	timing_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button(timing_panel, "Use selected timing presets", apply_timing_presets)
	var mechanic_panel := VBoxContainer.new()
	editor.add_child(mechanic_panel)
	mechanic_panel.visible = false
	button(editor, "Drive / stance behavior ▾", func(): mechanic_panel.visible = not mechanic_panel.visible)
	var mechanic_grid := GridContainer.new()
	mechanic_grid.columns = 2
	mechanic_panel.add_child(mechanic_grid)
	var mechanic_rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/mechanic_fields.json"))
	var stance_rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/stance_fields.json"))
	for entry in stance_rows: mechanic_rows.append([entry.key, entry.label, entry.default, entry.min, entry.max, entry.help])
	for row in mechanic_rows:
		var scale := 100 if row[0] in ["driveDistance", "tetherSpeed", "variantRange", "tetherRange", "tetherGap", "variantSpeed", "variantLift", "proximityRange", "startupTravel", "diveSpeedX", "diveSpeedY", "groundBounce", "wallBounce"] else 1
		add_field(mechanic_grid, [row[0], row[1], float(row[3]) / scale, float(row[4]) / scale, scale])
		fields[row[0]].control.tooltip_text = row[5]
	var mechanic_note := label(mechanic_panel, "Mechanic: 0 off · 1 legacy tether · 2 bleed/cash-out · 3 attach line · 4 pull · 5 Break Step. Break Step: active = burst frames; recovery = landing. One use per string, normal gets extra blockstun + full velocity. Pull ignores guard, keeps a free target actionable, and pauses existing hitstun/blockstun until it ends. Speeds are px/f, range is px; timing is frames. Getting hit clears your statuses. Cash-out KD: 0 none, 1 soft, 2 hard.", 11, MUTED)
	mechanic_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label(editor, "HIT REACTIONS", 11, MUTED)
	var reactions := GridContainer.new()
	reactions.columns = 2
	reactions.add_theme_constant_override("h_separation", 10)
	reactions.add_theme_constant_override("v_separation", 8)
	editor.add_child(reactions)
	for spec in [["pushback","Legacy / throw ground px",0,200,100],["airPushback","Legacy / throw air px",0,200,100],["blockPushback","Block pushback px",0,200,100],["launch","Ground launch px/f",0,30,100],["airLaunch","Air launch px/f",-30,30,100],["knockdownFrames","Down duration f",1,180,1],["wakeupFrames","Wakeup duration f",0,60,1],["throwRange","Throw reach px",0,200,100]]:
		add_field(reactions, spec)
	var combo_meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/combo_physics.json"))
	for spec in combo_meta.moves:
		add_field(reactions, [spec.key, spec.label, float(spec.min) / spec.scale, float(spec.max) / spec.scale, spec.scale])
		fields[spec.key].control.tooltip_text = spec.help
	var knockdown := option(reactions, "Knockdown", ["None", "Soft · on back", "Hard · face down"])
	fields.knockdown = {"control": knockdown, "scale": 1}
	var reaction_note := label(editor, "Launch: upward speed; air launch may be negative. Modern hit knockback uses velocity and drag; legacy mode uses a 6-frame distance budget; wall impact damage equals the arriving horizontal speed. Soft knockdowns lie on the back; hard knockdowns lie face down. Both get up in place. 2S is a low hard-knockdown sweep with punishable block recovery. 4P+K / 6P+K cause hard knockdown.", 11, MUTED)
	reaction_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var guard_break := CheckBox.new()
	guard_break.text = "Guard break on block"
	guard_break.tooltip_text = "Uses this move's blockstun. Defender cannot backdash or retain blockstun throw immunity."
	editor.add_child(guard_break)
	fields.guardBreak = {"control": guard_break, "scale": 1}
	var reversal := CheckBox.new()
	reversal.text = "Eligible for reversal timing"
	reversal.tooltip_text = "Starting this move on the first actionable frame after stun or wakeup earns REVERSAL. Uses the button buffer; grants no invulnerability."
	editor.add_child(reversal)
	fields.reversalEligible = {"control": reversal, "scale": 1}
	label(editor, "CANCEL BEHAVIOR", 11, MUTED)
	var checks := GridContainer.new()
	checks.columns = 2
	editor.add_child(checks)
	for pair in [["enabled","Move enabled"],["followHit","Follow-up needs hit"],["specialCancel","Special cancel"],["jumpCancel","Jump cancel"],["whiffCancel","Whiff cancel"],["selfCancel","Allow self route"]]:
		var check := CheckBox.new()
		check.text = pair[1]
		check.add_theme_font_size_override("font_size", 17)
		checks.add_child(check)
		fields[pair[0]] = {"control": check, "scale": 1}
	routes = label(editor, "", 11, MUTED)
	routes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var advanced := VBoxContainer.new()
	editor.add_child(advanced)
	advanced.visible = false
	button(editor, "Input & advanced rules ▾", func(): advanced.visible = not advanced.visible)
	var advanced_grid := GridContainer.new()
	advanced_grid.columns = 2
	advanced.add_child(advanced_grid)
	for spec in [["artPose","Artwork pose (0–32)",0,32,1],["followFrom","Follow source slot",-1,CombatModel.MOVE_IDS.size()-1,1],["followFrom2","Second source slot",-1,CombatModel.MOVE_IDS.size()-1,1],["travelSpeed","Active travel px/f",-20,20,100],["inertiaPercent","Carry speed %",0,200,1],["pullFrames","Pull duration f",0,60,1],["pullGap","Pull extra gap px",0,100,100],["hitAngle","Hit slope −1/0/+1",-1,1,1],["button","Button (0–4)",0,4,1],["category","Kind (0–4)",0,4,1],["direction","Direction (1–9)",1,9,1],["motion","Motion (214 / 236 / 623 / 63214 / 214214 / 236236)",0,236236,1],["air","Air (0/1)",0,1,1],["hitLevel","Guard level (0–2)",0,2,1],["normalRoutes","Normal mask",-1,31,1],["commandRoutes","Command mask",-1,31,1]]:
		add_field(advanced_grid, spec)
	var note := label(advanced, "Kind: 0 normal, 1 command, 2 special, 3 Drive, 4 throw. Button: P=0 K=1 S=2 Hs=3 D=4. Masks: −1 unified; P=1 K=2 S=4 Hs=8 D=16. Follow source −1 disables the route. Signature slots: 15 up slash, 25 spiral, 26 mid, 27 low, 28/29 hooks, 30/31 stabs. Hook slope ±1 travels at 45°; height is its thickness. Art pose 0 uses button art.", 10, MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for key in ["button", "category", "mechanic"]:
		fields[key].control.value_changed.connect(refresh_startup_limits)
	button(editor, "Apply & reset", apply_move, true, "essential")
	var saves := row(editor)
	button(saves, "Save locally", func(): var error := model.save_file(SAVE_PATH); editor_status.text = "Saved to " + SAVE_PATH if error.is_empty() else error)
	button(saves, "Export", func(): show_file(false))
	button(saves, "Import", func(): show_file(true), true)
	button(editor, "Load latest workshop batch", load_workshop_draft, true)
	button(editor, "Restore default move set", func(): model.restore_defaults(); populate_editor(); reset_round(); editor_status.text = "Defaults restored. Save locally to keep them.", true, "danger")
	editor_status = label(editor, "Provisional tuning · grabs ≥ 2f · P normals ≥ 3f · others ≥ 5f · weapons have no hurtbox", 11, ACCENT)
	editor_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label(editor, "INPUT BUFFER", 11, MUTED)
	var buffer_grid := GridContainer.new()
	buffer_grid.columns = 3
	editor.add_child(buffer_grid)
	for i in 3:
		var column := VBoxContainer.new()
		buffer_grid.add_child(column)
		label(column, ["Buttons", "Motion", "Step gap"][i], 11, MUTED)
		var spin := SpinBox.new()
		spin.min_value = [1,3,1][i]
		spin.max_value = [12,30,12][i]
		column.add_child(spin)
		buffer_fields.append(spin)
	button(editor, "Apply buffer & reset", apply_buffer, true, "essential")
	label(editor, "Strive parity is still to be measured.", 10, MUTED)
	var momentum_panel := VBoxContainer.new()
	editor.add_child(momentum_panel)
	momentum_panel.visible = false
	button(editor, "Momentum & Faultless Defense ▾", func(): momentum_panel.visible = not momentum_panel.visible)
	var meter_grid := GridContainer.new()
	meter_grid.columns = 2
	momentum_panel.add_child(meter_grid)
	for spec in [["movementGain", "Approach % / px", 0, 1, 100], ["attackGain", "Hit % / damage", 0, 1, 100], ["blockedAttackGain", "Attack blocked % / dmg", 0, 1, 100], ["damageTakenGain", "Damage taken % / dmg", 0, 1, 100], ["guardGain", "Guard % / damage", 0, 1, 100], ["specialGain", "Special / Drive %", 0, 100, 100], ["fdDrain", "FD % / frame", 0.01, 10, 100], ["fdBlockCost", "FD % / contact", 0, 100, 100], ["fdDamageCost", "FD % / damage", 0, 1, 100], ["fdPushPercent", "FD pushback %", 100, 1000, 1]]:
		var column := VBoxContainer.new()
		meter_grid.add_child(column)
		label(column, spec[1], 10, MUTED)
		var spin := SpinBox.new()
		spin.min_value = spec[2]
		spin.max_value = spec[3]
		spin.step = 0.01 if spec[4] == 100 else 1
		column.add_child(spin)
		momentum_fields[spec[0]] = {"control": spin, "scale": spec[4]}
	button(momentum_panel, "Apply Momentum & reset", apply_momentum, true, "essential")
	var meter_note := label(momentum_panel, "Provisional rates. FD prevents chip and increases pushback. Negative Penalty is deferred.", 11, MUTED)
	meter_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var recovery_panel := VBoxContainer.new()
	editor.add_child(recovery_panel)
	recovery_panel.visible = false
	button(editor, "Combo gravity & walls ▾", func(): recovery_panel.visible = not recovery_panel.visible)
	var recovery_grid := GridContainer.new()
	recovery_grid.columns = 2
	recovery_panel.add_child(recovery_grid)
	for spec in [["gravityAfter","Legacy unscaled hits",0,100,1],["gravityStep","Legacy gravity +% / hit",0,100,1],["gravityCap","Gravity cap %",100,400,1],["wallThreshold","Wall health (velocity units)",1,10000,1],["wallSplatFrames","Splat duration f",1,180,1],["wallBreakFrames","Break transition f",30,300,1],["wallBreakDamage","Break bonus damage",0,1000,1],["positiveFrames","Positive duration f",0,1800,1],["positiveGainPercent","Positive gain %",100,300,1],["positiveRegen","Positive regen % / f",0,1,100]]:
		var column := VBoxContainer.new()
		recovery_grid.add_child(column)
		label(column, spec[1], 10, MUTED)
		var spin := SpinBox.new()
		spin.min_value = spec[2]
		spin.max_value = spec[3]
		spin.step = 0.01 if spec[4] == 100 else 1
		column.add_child(spin)
		recovery_fields[spec[0]] = {"control": spin, "scale": spec[4]}
	label(recovery_panel, "COMBO PHYSICS · ALL FIGHTERS", 11, MUTED)
	for spec in combo_meta.rules:
		var column := VBoxContainer.new()
		recovery_panel.add_child(column)
		label(column, spec.label, 10, MUTED)
		var spin := SpinBox.new()
		spin.min_value = spec.min
		spin.max_value = spec.max
		spin.step = 1
		spin.tooltip_text = spec.help
		column.add_child(spin)
		combo_fields[spec.key] = spin
	var recovery_note := label(recovery_panel, "Modern physics scales push speed, positive launch and ground bounce with combo decay. General gravity starts at the decay threshold; repeated-move gravity is independent. Mode 0 retains the legacy hit-count rules. Each wall loses health only from hitstun impacts: 100 velocity units = 1 px/f. Depleting it primes the NEXT hitstun impact to splat. Strike the splat to break; an expired splat falls into soft recovery. Wall breaks return to neutral with a Momentum gain bonus.", 11, MUTED)
	recovery_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button(recovery_panel, "Apply recovery & reset", apply_recovery, true, "essential")
	var tuning_panel := VBoxContainer.new()
	editor.add_child(tuning_panel)
	tuning_panel.visible = false
	button(editor, "Defense, landing & wall tuning ▾", func(): tuning_panel.visible = not tuning_panel.visible)
	var tuning_grid := GridContainer.new()
	tuning_grid.columns = 2
	tuning_panel.add_child(tuning_grid)
	for spec in [["fdAirDrain","Air FD % / frame",0.01,10,100],["fdLevelCost","FD % / attack level",0,10,100],["throwGraceFrames","Throw protection f",0,30,1],["airLandingFrames","Recovered air landing f",0,120,1],["repeatAfter","Repeat penalty from use",0,100,1],["repeatGravityStep","Repeat gravity +%",0,100,1]]:
		var column := VBoxContainer.new()
		tuning_grid.add_child(column)
		label(column, spec[1], 10, MUTED)
		var spin := SpinBox.new()
		spin.min_value = spec[2]
		spin.max_value = spec[3]
		spin.step = 0.01 if spec[4] == 100 else 1
		column.add_child(spin)
		tuning_fields[spec[0]] = {"control": spin, "scale": spec[4]}
	for spec in [["cornerPushTransfer","Ordinary corner pushback"],["blockCarryover","Carry guard through blockstun"]]:
		var toggle := CheckBox.new()
		toggle.text = spec[1]
		tuning_panel.add_child(toggle)
		tuning_fields[spec[0]] = {"control": toggle, "scale": 1}
	for spec in [["prejumpFrames", "Jump startup f", 30], ["emptyLandingFrames", "Empty jump landing f", 120]]:
		var column := VBoxContainer.new()
		tuning_grid.add_child(column)
		label(column, spec[1], 10, MUTED)
		var spin := SpinBox.new()
		spin.min_value = 0
		spin.max_value = spec[2]
		column.add_child(spin)
		jump_fields[spec[0]] = spin
	var tuning_note := label(tuning_panel, "No timed blocking bonus. Guard break bypasses carryover and throw protection. Jump startup is throw-immune but cannot guard strikes. In modern physics, repeated moves add gravity from the configured use count, including early in a combo.", 11, MUTED)
	tuning_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button(tuning_panel, "Apply tuning & reset", apply_tuning, true, "essential")
	var movement_panel := VBoxContainer.new()
	editor.add_child(movement_panel)
	movement_panel.visible = false
	button(editor, "Run, step dash & inertia ▾", func(): movement_panel.visible = not movement_panel.visible)
	var movement_grid := GridContainer.new()
	movement_grid.columns = 2
	movement_panel.add_child(movement_grid)
	var forward_style := option(movement_grid, "Forward movement", ["Run", "Step dash", "Hover dash", "Teleport"])
	movement_fields.forwardStyle = {"control": forward_style, "scale": 1}
	for spec in [["walkSpeed","Walk px/f",0.01,10,100],["runSpeed","Run cap px/f",0.01,20,100],["runAcceleration","Run accel px/f²",0.01,10,100],["stepSpeed","Step px/f",0.01,20,100],["stepFrames","Step duration f",1,60,1],["backSpeed","Backdash px/f",0.01,20,100],["backFrames","Backdash duration f",1,60,1],["attackFriction","Attack drag px/f²",0,5,100],["airDashPauseFrames","Air dash pause f",1,30,1],["airBackdashPauseFrames","Air backdash pause f",1,30,1]]:
		var column := VBoxContainer.new()
		movement_grid.add_child(column)
		label(column, spec[1], 10, MUTED)
		var spin := SpinBox.new()
		spin.min_value = spec[2]
		spin.max_value = spec[3]
		spin.step = 0.01 if spec[4] == 100 else 1
		column.add_child(spin)
		movement_fields[spec[0]] = {"control": spin, "scale": spec[4]}
	var movement_note := label(movement_panel, "Selected fighter only. 66 or Dash starts forward movement. Hold forward or Dash to keep running; back + Dash steps backward. Attacks retain velocity and slow by attack drag. Active travel adds the move's own speed. Air dashes stop all velocity and pause before their full burst duration starts.", 11, MUTED)
	movement_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button(movement_panel, "Apply movement & reset", apply_movement, true, "essential")
	diagnostics = VBoxContainer.new()
	editor.add_child(diagnostics)
	var network := panel(diagnostics)
	network.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label(network, "Rollback workbench", 17)
	var test_row := VBoxContainer.new()
	network.add_child(test_row)
	button(test_row, "Run latency check", run_trial)
	trial_status = label(test_row, "6–9 frames of delay", 11, MUTED)
	var route_panel := panel(diagnostics)
	label(route_panel, "Unified gatlings", 17)
	label(route_panel, "P → P / K\nK → jump / command\nc.S → f.S / 2S / jump / Hs / command\nf.S → jump / Hs / command\n2S → Hs / command / special\nHs → command", 12, MUTED)
	label(route_panel, "All attacks → same-button command", 10, ACCENT)
	build_dialogs()
	build_frame_lab()
	pause_tableau = PauseTableau.new()
	add_child(pause_tableau)
	menus = GameMenus.new()
	menus.motion = motion
	add_child(menus)
	menus.action_requested.connect(menu_action)
	address = menus.address
	port = menus.port
	net_status = menus.status
	leave_button = menus.buttons.cancel_connection
	lock_online(false)
	match_entry = MatchEntry.new()
	match_entry.motion = motion
	add_child(match_entry)
	match_entry.intros_finished.connect(func():
		if connection.active: connection.finish_intros()
		else: match_entry.begin_opening())
	match_entry.opening_finished.connect(func():
		if connection.active: connection.finish_countdown()
		else: release_match())
	match_entry.intermission_finished.connect(func():
		if connection.active: connection.finish_intermission()
		else: next_scrum())
	match_entry.canceled.connect(cancel_match_entry)
	match_entry.failed.connect(entry_failed)

func add_field(parent: Node, spec: Array) -> void:
	var column := VBoxContainer.new()
	parent.add_child(column)
	label(column, spec[1], 10, MUTED)
	var spin := SpinBox.new()
	spin.min_value = spec[2]
	spin.max_value = spec[3]
	spin.step = 0.01 if spec[4] == 100 else 1.0
	spin.custom_minimum_size.x = 92
	column.add_child(spin)
	fields[spec[0]] = {"control": spin, "scale": spec[4]}

func build_frame_lab() -> void:
	lab_window = Window.new()
	lab_window.visible = false
	lab_window.title = "Training · frame lab"
	lab_window.size = Vector2i(940, 350)
	lab_window.min_size = Vector2i(790, 330)
	lab_window.close_requested.connect(func(): lab_window.hide(); release_focus_from_ui())
	add_child(lab_window)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 12)
	lab_window.add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)
	timeline = FrameTimeline.new()
	timeline.lab = lab
	column.add_child(timeline)
	lab_status = label(column, lab.message, 16)
	lab_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var controls := row(column)
	button(controls, "+1 tick", advance_one)
	button(controls, "Replay both", func(): replay_exchange(false))
	button(controls, "Replay P2 dummy", func(): replay_exchange(true))
	button(controls, "Resume", func(): lab_window.hide(); paused = false; pause_button.text = "Pause")
	label(column, "Opening this view pauses play. Record P2 with ‘Player 2 controls’; dummy replay leaves P1 live.", 12, MUTED)

func open_frame_lab() -> void:
	if connection.active or activity not in ["training", "development"]: return
	cancel_super_freeze_preview()
	paused = true
	pause_button.text = "Resume"
	lab_window.popup_centered()
	timeline.queue_redraw()

func record_exchange() -> void:
	if connection.active or screen != "play" or activity not in ["training", "development"]: return
	cancel_super_freeze_preview()
	lab_window.hide()
	lab.start_recording(model)
	paused = false
	pause_button.text = "Pause"

func replay_exchange(dummy_only: bool) -> void:
	if connection.active or screen != "play" or activity not in ["training", "development"]: return
	cancel_super_freeze_preview()
	if not lab.start_replay(model, dummy_only): return
	lab_window.hide()
	var state := model.state()
	for p in 2:
		characters[p] = int(state.players[p].character)
	held.clear()
	history.clear()
	last_raw = 0
	paused = false
	pause_button.text = "Pause"

func build_dialogs() -> void:
	file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.json ; Fight Guild move data"])
	file_dialog.size = Vector2i(800, 560)
	add_child(file_dialog)
	file_dialog.file_selected.connect(func(path: String):
		var error := model.load_file(path) if importing else model.save_file(path)
		editor_status.text = error if not error.is_empty() else "Move set imported." if importing else "Move set exported."
		if importing and error.is_empty(): populate_editor(); reset_round())

func menu_action(action: String) -> void:
	match action:
		"matches": show_screen("matches")
		"local", "online", "training", "development": choose_activity(action)
		"confirm_fighters": confirm_selection()
		"confirm_sides": confirm_sides()
		"back": menu_back()
		"controls", "pause_controls": show_controls()
		"sound", "pause_sound": show_sound_settings()
		"motion":
			motion.toggle_reduced()
			menus.update_motion_label()
			finish_menu_motion()
		"quit": get_tree().quit()
		"resume": show_screen("play")
		"restart", "rematch":
			if action == "rematch":
				match_score.reset()
				round_number = 1
			reset_round()
			begin_match_entry(true)
		"change_fighters", "results_fighters": choose_activity(activity)
		"pause_home", "results_home": go_home()
		"host": start_network(true)
		"join": start_network(false)
		"cancel_connection": cancel_connection()
		"return_lobby":
			cancel_connection()
			show_screen("online")

func show_screen(next: String) -> void:
	if next != "play": cancel_super_freeze_preview()
	var previous := screen
	screen = next
	held.clear()
	release_focus_from_ui()
	var playing := next in ["play", "entry"]
	menus.set_active(not playing)
	if not playing: menus.show_page(next, previous == "play")
	elif next == "play": input_release_required = has_gameplay_input_held()
	if playing and previous == "pause": menus.pause_commands.depart()
	var target := "play" if playing else "menus"
	if target == layer_target:
		if motion.instant: finish_menu_motion()
		elif not changing_layers(): settle_layers()
		return
	layer_target = target
	if layer_tween: layer_tween.kill()
	MenuMotion.interactive(play_root, false)
	if motion.instant:
		settle_layers()
		return
	play_root.visible = true
	menus.visible = true
	if playing and previous != "pause": pause_tableau.visible = false
	layer_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if next == "pause" or (previous == "pause" and playing):
		# The captured frame is identical to the last live frame. Ink comes up
		# directly on the fighters, with no blackout, camera cut or replacement pose.
		play_root.visible = false
		pause_tableau.visible = true
		layer_tween.tween_property(pause_tableau, "amount", 0.0 if playing else 1.0, motion.duration(0.28))
	layer_tween.tween_property(play_root, "modulate:a", 1.0 if playing else 0.0, motion.duration(0.28))
	layer_tween.tween_property(menus, "modulate:a", 0.0 if playing else 1.0, motion.duration(0.28))
	layer_tween.chain().tween_callback(settle_layers)

func changing_layers() -> bool:
	return layer_tween != null and layer_tween.is_running()

func settle_layers() -> void:
	var playing := screen in ["play", "entry"]
	play_root.visible = playing
	play_root.modulate.a = 1.0 if playing else 0.0
	menus.visible = not playing
	menus.modulate.a = 0.0 if playing else 1.0
	pause_tableau.visible = not playing and menus.pause_mix > 0.001 and pause_tableau.captured_frame >= 0
	if screen == "pause": pause_tableau.amount = 1.0
	MenuMotion.interactive(play_root, screen == "play")
	if screen == "play":
		held.clear()
		input_release_required = has_gameplay_input_held()

func finish_menu_motion() -> void:
	if layer_tween: layer_tween.kill()
	settle_layers()
	menus.finish_motion()

func wait_for_menu_motion() -> void:
	while changing_layers() or menus.is_animating():
		await get_tree().process_frame

func wait_for_match_entry() -> void:
	while screen == "entry" or match_entry.phase == "release":
		await get_tree().process_frame
	await wait_for_menu_motion()

func begin_match_entry(repeated: bool = false) -> void:
	round_resolved = false
	entry_accept_released = not Input.is_action_pressed("ui_accept")
	show_screen("entry")
	var state := model.state()
	var chosen := [state.players[0].character, state.players[1].character]
	match_entry.begin(chosen, round_number, activity in ["training", "development"], connection.active, repeated)

func next_scrum() -> void:
	round_number = match_score.next_number()
	reset_round()
	begin_match_entry(true)

func finish_scrum(state: Dictionary) -> void:
	if round_resolved: return
	if connection.active:
		if not connection.confirm_result(): return
	elif not match_score.record(int(state.winner)): return
	round_resolved = true
	if match_score.finished():
		match_entry.cancel()
		menus.configure_results(state, connection.active, MatchCeremony.round_call(round_number), match_score.wins)
		show_screen("results")
	else:
		show_screen("entry")
		match_entry.begin_intermission(int(state.winner), match_score.wins, MatchCeremony.round_call(match_score.next_number()))

func release_match() -> void:
	match_entry.release()
	held.clear()
	show_screen("play")

func cancel_match_entry() -> void:
	if screen != "entry": return
	match_entry.cancel()
	if connection.active:
		cancel_connection()
		show_screen("online")
	else:
		selection_return = "sides" if activity == "local" else "home"
		pending_activity = activity
		menus.configure_selection(activity, characters)
		show_screen("fighters")

func entry_failed(message: String) -> void:
	cancel_match_entry()
	if activity == "online": net_status.text = message
	else: menus.selection.instruction.text = message

func choose_activity(which: String) -> void:
	if connection.active: return
	if which == "local" and screen != "sides":
		sides_return = screen
		menus.sides.configure(fighter_inputs, characters)
		show_screen("sides")
		return
	pending_activity = which
	selection_return = screen
	menus.configure_selection(which, characters)
	show_screen("fighters")

func confirm_sides() -> void:
	if screen != "sides" or not menus.sides.apply(): return
	choose_activity("local")

func confirm_selection() -> void:
	if connection.active: return
	for p in 2:
		characters[p] = menus.selection.chosen[p]
	if screen == "fighters":
		activity = pending_activity
		configure_activity()
		if activity == "online":
			menus.online_fighter.text = CombatModel.CHARACTERS[characters[0]] + "  ·  Motion inputs"
			net_status.text = "Choose Host or Join to begin."
			show_screen("online")
			return
	match_score.reset()
	round_number = 1
	reset_round()
	begin_match_entry()

func configure_activity() -> void:
	var development := activity == "development"
	var practice_mode := activity in ["training", "development"]
	play_header.visible = practice_mode
	for edge in ["left", "right", "top", "bottom"]:
		play_margins.add_theme_constant_override("margin_" + edge, 16 if practice_mode else 0)
	editor_shell.visible = development
	sprite_button.visible = development
	diagnostics.visible = development
	toolbar.visible = practice_mode
	practice.visible = practice_mode
	inputs.visible = practice_mode
	keyboard_hint.visible = practice_mode
	mode.get_parent().visible = development
	fighter_button.visible = practice_mode
	activity_title.visible = false
	activity_subtitle.visible = false
	activity_title.text = "Build your next route." if activity == "training" else "Find the fight."
	activity_subtitle.text = "Practice attacks, defense and timing. Reset as often as you need." if activity == "training" else "Play a route. Tune a move. Run it back."
	activity_badge.text = {"local":"LOCAL VERSUS", "online":"ONLINE VERSUS", "training":"TRAINING", "development":"DEVELOPMENT / COMBAT LAB"}[activity]
	mode.select(0 if practice_mode else 1)
	show_boxes = development
	lock_online(connection.active)

func open_pause() -> void:
	if screen != "play" or has_open_dialog(): return
	# The viewport still contains the last drawn cut-in until the next render.
	# Use the pre-freeze image when canceling into the pause tableau.
	var frozen_background := super_preview_background if super_preview_player >= 0 else null
	cancel_super_freeze_preview()
	pause_tableau.capture(arena, model.state(), model.frame())
	if frozen_background != null: pause_tableau.background.texture = frozen_background
	menus.configure_pause(connection.active, model.state())
	show_screen("pause")
	menus.pause_commands.focal_point = pause_tableau.focal_point

func menu_back() -> void:
	match screen:
		"entry": cancel_match_entry()
		"matches": show_screen("home")
		"sides": show_screen(sides_return)
		"fighters": show_screen(selection_return)
		"online":
			cancel_connection()
			selection_return = "matches"
			menus.configure_selection("online", characters)
			pending_activity = "online"
			show_screen("fighters")
		"pause": show_screen("play")

func go_home() -> void:
	match_entry.cancel()
	cancel_connection()
	show_screen("home")

func cancel_connection() -> void:
	connection.close()
	lock_online(false)
	net_status.text = "Connection closed. Choose Host or Join when ready."
	if screen == "online": menus.focus_page("online")

func on_network_preparing() -> void:
	activity = "online"
	configure_activity()
	match_score = connection.score
	history.clear()
	last_raw = 0
	paused = false
	round_number = match_score.next_number()
	begin_match_entry(connection.generation > 1)

func on_network_started() -> void:
	release_match()

func on_network_ended() -> void:
	match_entry.cancel()
	lock_online(false)
	if activity == "online": show_screen("online")

func has_gameplay_input_held() -> bool:
	return Input.is_action_pressed("ui_accept") or fighter_inputs.any_held()

func refresh_input_hint() -> void:
	keyboard_hint.text = fighter_inputs.keyboard_hint(0)
	held.clear()
	if screen == "play": input_release_required = true

func on_controller_lost(player: int) -> void:
	held.clear()
	input_release_required = true
	if screen == "play" and not has_open_dialog():
		open_pause()
		menus.pause_note.text = "Player %d controller disconnected. Reconnect it or choose Controls." % (player + 1)
		if connection.active: menus.pause_note.text += " The online match continues."

func show_sprite_review(clip: int = 0) -> void:
	held.clear()
	var dialog := AcceptDialog.new()
	dialog.theme = GuildTheme.stock()
	dialog.title = "Sprite & collision review"
	dialog.ok_button_text = "Back to combat lab"
	add_child(dialog)
	var layout := VBoxContainer.new()
	dialog.add_child(layout)
	var pickers := HBoxContainer.new()
	layout.add_child(pickers)
	var fighter_picker := option(pickers, "Fighter", CombatModel.CHARACTERS)
	var button_picker := option(pickers, "Button", CombatModel.BUTTONS)
	var clip_picker := option(pickers, "Clip", ["Attack", "Negative / even block", "Positive block", "Guard break", "Ready", "Walk", "Jump", "Hit reaction", "Crouch", "Legacy guard", "Dedicated move", "Run / step dash", "Rolling stance", "Soft knockdown / get up", "Hard knockdown / get up", "Backward walk", "2Hs / full animation", "Backdash"])
	clip_picker.select(clampi(clip, 0, 17))
	var signature_picker := option(pickers, "Signature", ["1", "2", "3", "4"])
	fighter_picker.select(edit_character.selected)
	var options := row(layout)
	var collision_toggle := CheckBox.new()
	collision_toggle.text = "Collision boxes"
	collision_toggle.button_pressed = true
	options.add_child(collision_toggle)
	var mirror_toggle := CheckBox.new()
	mirror_toggle.text = "Face left"
	options.add_child(mirror_toggle)
	var loop_toggle := CheckBox.new()
	loop_toggle.text = "Play loop"
	loop_toggle.button_pressed = true
	options.add_child(loop_toggle)
	var frame_picker := option(options, "Frame", ["1", "2", "3", "4", "5", "6", "7", "8"])
	var pair := HBoxContainer.new()
	layout.add_child(pair)
	var previews: Array[FighterPreview] = []
	var captions: Array[Label] = []
	for phase in ["WINDUP", "ACTIVE"]:
		var column := VBoxContainer.new()
		pair.add_child(column)
		captions.append(label(column, phase, 16, ACCENT))
		var preview := FighterPreview.new()
		preview.custom_minimum_size = Vector2(330, 360)
		preview.combat_model = model
		column.add_child(preview)
		previews.append(preview)
	var stats := label(layout, "", 12, ACCENT)
	var loop_ticks := [0]
	var update := func(_index: int = 0):
		clip_picker.set_item_disabled(10, fighter_picker.selected < 2)
		clip_picker.set_item_disabled(11, fighter_picker.selected < 2)
		if clip_picker.selected == 10 and fighter_picker.selected < 2: clip_picker.select(0)
		if clip_picker.selected == 11 and fighter_picker.selected < 2: clip_picker.select(0)
		clip_picker.set_item_disabled(15, fighter_picker.selected not in [2, 4])
		if clip_picker.selected == 15 and fighter_picker.selected not in [2, 4]: clip_picker.select(0)
		clip_picker.set_item_disabled(17, fighter_picker.selected != 4)
		if clip_picker.selected == 17 and fighter_picker.selected != 4: clip_picker.select(0)
		clip_picker.set_item_disabled(12, fighter_picker.selected != 3)
		if clip_picker.selected == 12 and fighter_picker.selected != 3: clip_picker.select(0)
		clip_picker.set_item_disabled(16, fighter_picker.selected not in [2, 4])
		if clip_picker.selected == 16 and fighter_picker.selected not in [2, 4]: clip_picker.select(0)
		var attack_clip: bool = clip_picker.selected == 16
		var locomotion: bool = fighter_picker.selected >= 2 and clip_picker.selected in [5, 11, 12, 15, 17]
		var recovery_clip: bool = clip_picker.selected in [13, 14]
		var idle_clip: bool = (fighter_picker.selected == 2 and clip_picker.selected in [4, 8]) or (fighter_picker.selected == 4 and clip_picker.selected == 4)
		var frame_count: int = 6 if recovery_clip or clip_picker.selected == 17 else 4 if clip_picker.selected == 12 or idle_clip else 8
		loop_toggle.visible = locomotion or recovery_clip or idle_clip or attack_clip
		frame_picker.visible = locomotion or recovery_clip or idle_clip or attack_clip
		for frame in frame_picker.item_count: frame_picker.set_item_disabled(frame, frame >= frame_count)
		if frame_picker.selected >= frame_count: frame_picker.select(0)
		button_picker.disabled = clip_picker.selected != 0
		signature_picker.visible = clip_picker.selected == 10
		var signature_slots: Array = [25, 15, 26, 27] if fighter_picker.selected == 5 else [28, 29, 30, 31]
		if fighter_picker.selected == 2:
			signature_slots = [0,1,32,2,3,4,5,6,7,22,8,11,43,13,44,17,18,19,20,21,14,25,15,16]
		if fighter_picker.selected == 3:
			signature_slots = [0,1,32,2,3,4,5,6,7,22,8,9,11,17,18,19,19,20,21,33,34,13,24,41,35,36,37,38,39,40,40,22]
		if fighter_picker.selected == 4:
			signature_slots = [28,29,30,31,0,1,32,2,3,4,5,6,7,17,18,19,20,8,9,11]
		var selected_pose := clampi(signature_picker.selected, 0, signature_slots.size() - 1)
		signature_picker.clear()
		for i in signature_slots.size():
			var atlas: Dictionary = FighterArt.sheet(fighter_picker.selected, "signature_active") if fighter_picker.selected >= 2 else {}
			if not atlas.is_empty(): signature_picker.add_item(atlas.frames[i].get("name", CombatModel.MOVE_IDS[signature_slots[i]]))
			else: signature_picker.add_item(CombatModel.MOVE_IDS[signature_slots[i]])
		signature_picker.select(selected_pose)
		var slot: int = 7 if attack_clip else signature_slots[signature_picker.selected] if clip_picker.selected == 10 else [0, 1, 2, 3, 13][button_picker.selected]
		var move := model.move(fighter_picker.selected, slot)
		stats.text = "%df startup · %df active · %df recovery · %d damage · %+df on block (final hit)" % [move.startup, move.active, move.recovery, move.damage, CombatModel.block_advantage(move)] if clip_picker.selected in [0, 10] else "Body hurtboxes follow the displayed pose. Pushboxes keep a stable body width."
		for i in 2:
			previews[i].show_collision = collision_toggle.button_pressed
			previews[i].facing = -1 if mirror_toggle.button_pressed else 1
			previews[i].move_slot = slot
			if attack_clip:
				var frame := (frame_picker.selected + i) % 8
				captions[i].text = FighterArt.sheet(fighter_picker.selected, "attack_animation").frames[frame].name
				previews[i].present(fighter_picker.selected, "attack_animation", frame, previews[i].facing)
			elif idle_clip:
				var idle_phase := "idle" if clip_picker.selected == 4 else "crouch_idle"
				var frame := (frame_picker.selected + i) % frame_count
				var ticks: int = frame * 20 + (loop_ticks[0] % 20 if loop_toggle.button_pressed else 0)
				captions[i].text = "%s · FRAME %d / 4" % [FighterArt.sheet(fighter_picker.selected, idle_phase).frames[frame].name.to_upper(), frame + 1]
				previews[i].present(fighter_picker.selected, idle_phase, frame, previews[i].facing, ticks)
			elif recovery_clip:
				var recovery_phase := "knockdown_back" if clip_picker.selected == 13 else "knockdown"
				var frame := (frame_picker.selected + i) % frame_count
				var pose_name: String = FighterArt.sheet(fighter_picker.selected, recovery_phase).frames[frame].name
				captions[i].text = "%s · FRAME %d / %d" % [pose_name.to_upper(), frame + 1, frame_count]
				previews[i].present(fighter_picker.selected, recovery_phase, frame, previews[i].facing)
			elif locomotion:
				var motion_phase := "backdash" if clip_picker.selected == 17 else "stance" if clip_picker.selected == 12 else "run" if clip_picker.selected == 11 else "back_walk" if clip_picker.selected == 15 else "walk"
				var frame := (frame_picker.selected + i) % frame_count
				captions[i].text = "%s · FRAME %d / %d" % [motion_phase.to_upper(), frame + 1, frame_count]
				var interval := 5 if clip_picker.selected == 11 else 10
				# Vapor has its own cadence; keep its clock continuous when the
				# shorter run-body sequence wraps back to its first drawing.
				var ticks: int = loop_ticks[0] + i * interval if loop_toggle.button_pressed else frame * interval
				previews[i].present(fighter_picker.selected, motion_phase, frame, previews[i].facing, ticks)
			elif clip_picker.selected == 4 and fighter_picker.selected >= 3:
				captions[i].text = "STALKER" if fighter_picker.selected == 5 else "SHOULDER REST" if fighter_picker.selected == 4 else "TAPPER READY"
				previews[i].present(fighter_picker.selected, "ready", 0, previews[i].facing)
			elif clip_picker.selected == 10:
				captions[i].text = ["WINDUP", "ACTIVE"][i]
				previews[i].present(fighter_picker.selected, ["signature_windup", "signature_active"][i], signature_picker.selected, previews[i].facing)
			elif clip_picker.selected == 0:
				captions[i].text = ["WINDUP", "ACTIVE"][i]
				previews[i].present(fighter_picker.selected, (["signature_windup", "signature_active"] if move.artPose > 0 else ["windup", "active"])[i], move.artPose - 1 if move.artPose > 0 else button_picker.selected + 1, previews[i].facing)
			elif clip_picker.selected <= 3:
				captions[i].text = ["CONTACT", "SETTLE / HOLD"][i]
				previews[i].present(fighter_picker.selected, "block", (clip_picker.selected - 1) * 2 + i, previews[i].facing)
			else:
				var pose_pair: Array = [[0, 0], [6, 7], [8, 8], [9, 9], [11, 11], [10, 10]][clip_picker.selected - 4]
				captions[i].text = "READY / WINDUP BASE" if clip_picker.selected == 4 and i == 1 else clip_picker.get_item_text(clip_picker.selected).to_upper()
				previews[i].present(fighter_picker.selected, "windup" if clip_picker.selected == 4 and i == 1 else "active", pose_pair[i], previews[i].facing)
			if collision_toggle.button_pressed:
				var hurt: PackedInt32Array = model.core.pose_boxes(fighter_picker.selected, FighterArt.PHASES.find(previews[i].phase), previews[i].pose)
				captions[i].text += " · %d/4 hurtboxes" % (hurt.size() / 4)
	fighter_picker.item_selected.connect(update)
	button_picker.item_selected.connect(update)
	clip_picker.item_selected.connect(update)
	signature_picker.item_selected.connect(update)
	collision_toggle.toggled.connect(func(_value: bool): update.call())
	mirror_toggle.toggled.connect(func(_value: bool): update.call())
	frame_picker.item_selected.connect(func(index: int): loop_toggle.button_pressed = false; update.call(index))
	var loop_timer := Timer.new()
	dialog.add_child(loop_timer)
	loop_timer.wait_time = 1.0 / 60.0
	loop_timer.timeout.connect(func():
		if not loop_toggle.visible or not loop_toggle.button_pressed: return
		loop_ticks[0] += 1
		var idle_clip: bool = (fighter_picker.selected == 2 and clip_picker.selected in [4, 8]) or (fighter_picker.selected == 4 and clip_picker.selected == 4)
		if idle_clip:
			frame_picker.select(FighterArt.idle_pose(fighter_picker.selected, loop_ticks[0]) if clip_picker.selected == 4 else (loop_ticks[0] / 20) % 4)
			update.call()
		elif clip_picker.selected == 17:
			var duration: int = maxi(1, int(model.data().characters[fighter_picker.selected].movement.backFrames) - 1)
			frame_picker.select(mini(5, int((loop_ticks[0] % duration) * 5 / maxi(1, duration - 1))))
			update.call()
		elif fighter_picker.selected == 2 and clip_picker.selected in [5, 11, 15]:
			var interval := 5 if clip_picker.selected == 11 else 10
			if loop_ticks[0] % interval == 0: frame_picker.select((frame_picker.selected + 1) % 8)
			update.call()
		elif loop_ticks[0] % (3 if clip_picker.selected == 11 else 5) == 0:
			var frame_count: int = 6 if clip_picker.selected in [13, 14] else 4 if clip_picker.selected == 12 else 8
			frame_picker.select((frame_picker.selected + 1) % frame_count)
			update.call())
	loop_timer.start()
	update.call()
	label(layout, "Hurt: legs · torso + arms · head · optional extension. Maximum 4 per pose.\nCyan: hurt · green: push · orange: hit. Weapons excluded. Startup minimum: throws 2f; P normals 3f; other attacks 5f.", 12, MUTED)
	dialog.canceled.connect(func(): close_dialog(dialog))
	dialog.confirmed.connect(func(): close_dialog(dialog))
	dialog.popup_centered(Vector2i(760, 600))

func show_controls() -> void:
	held.clear()
	var dialog := preload("res://scripts/controls_guide.gd").new()
	dialog.controls = fighter_inputs
	dialog.accent = menus.palette.accent
	var previous := get_viewport().gui_get_focus_owner()
	if previous != null: dialog.set_meta("return_focus", weakref(previous))
	add_child(dialog)
	dialog.confirmed.connect(func(): close_dialog(dialog))
	dialog.canceled.connect(func(): close_dialog(dialog))
	dialog.popup_centered(Vector2i(900, 600))

func show_sound_settings() -> void:
	held.clear()
	var dialog := AcceptDialog.new()
	var previous := get_viewport().gui_get_focus_owner()
	if previous != null: dialog.set_meta("return_focus", weakref(previous))
	dialog.theme = InkMenu.theme(menus.palette.accent)
	dialog.title = "Sound & music"
	# Checkboxes keep a transparent background even in their checked state.
	for color in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color", "font_focus_color"]:
		dialog.theme.set_color(color, "CheckBox", InkMenu.PAPER)
	dialog.set_meta("music_settings", true)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	dialog.add_child(layout)
	var music_toggle := CheckBox.new()
	music_toggle.name = "MusicEnabled"
	music_toggle.text = "Fighter themes"
	music_toggle.button_pressed = fighter_music.enabled
	layout.add_child(music_toggle)
	music_toggle.toggled.connect(fighter_music.set_enabled)
	var music_caption := label(layout, "Music volume: %d%%" % (fighter_music.volume * 100), 17)
	var music_slider := HSlider.new()
	music_slider.name = "MusicVolume"
	music_slider.min_value = 0
	music_slider.max_value = 100
	music_slider.value = fighter_music.volume * 100
	music_slider.custom_minimum_size = Vector2(540, 36)
	music_slider.accessibility_name = "Music volume"
	layout.add_child(music_slider)
	music_slider.value_changed.connect(func(value: float):
		fighter_music.set_volume(value / 100.0)
		music_caption.text = "Music volume: %d%%" % value)
	var theme_picker := OptionButton.new()
	theme_picker.name = "MusicTheme"
	theme_picker.accessibility_name = "Match theme"
	theme_picker.add_item("Theme follows Player 1's fighter")
	theme_picker.add_item("Theme follows Player 2's fighter")
	for record in fighter_music.catalog.tracks:
		theme_picker.add_item("%s · %s" % [record.fighter, record.title])
	theme_picker.select(fighter_music.source)
	layout.add_child(theme_picker)
	var theme_caption := label(layout, "", 17, MUTED)
	theme_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Seed wrapping width before AcceptDialog measures its minimum height.
	theme_caption.custom_minimum_size = Vector2(540, 24)
	theme_caption.size.x = 540
	var update_theme := func():
		var track: Dictionary = fighter_music.track(fighter_music.selected_character())
		theme_caption.text = "%s — %s" % [track.fighter, track.title]
	update_theme.call()
	theme_picker.item_selected.connect(func(index: int):
		fighter_music.set_source(index)
		update_theme.call())
	var music_preview := Button.new()
	music_preview.name = "MusicPreview"
	music_preview.text = "Preview theme"
	music_preview.toggle_mode = true
	layout.add_child(music_preview)
	music_preview.toggled.connect(func(value: bool):
		if value: fighter_music.preview_theme()
		else: fighter_music.end_preview()
		music_preview.text = "Stop preview" if value else "Preview theme")
	layout.add_child(HSeparator.new())
	var toggle := CheckBox.new()
	toggle.text = "Sound effects"
	toggle.button_pressed = combat_audio.enabled
	layout.add_child(toggle)
	toggle.toggled.connect(func(value: bool):
		combat_audio.enabled = value
		combat_audio.save_preferences()
		if not value: combat_audio.silence())
	var caption := Label.new()
	layout.add_child(caption)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.value = combat_audio.volume * 100
	slider.custom_minimum_size = Vector2(340, 36)
	slider.accessibility_name = "Sound effects volume"
	layout.add_child(slider)
	caption.text = "Effects volume: %d%%" % slider.value
	slider.value_changed.connect(func(value: float):
		combat_audio.volume = value / 100.0
		caption.text = "Effects volume: %d%%" % value
		combat_audio.save_preferences())
	var preview_row := HBoxContainer.new()
	layout.add_child(preview_row)
	var sound_picker := OptionButton.new()
	sound_picker.accessibility_name = "Effect to preview"
	sound_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for title in ["Light punch", "Heavy knife", "Block", "Faultless Defense", "Guard break", "Armor", "Counter"]: sound_picker.add_item(title)
	sound_picker.selected = 1
	preview_row.add_child(sound_picker)
	var preview := Button.new()
	preview.text = "Preview effect"
	preview_row.add_child(preview)
	preview.pressed.connect(func():
		var option := sound_picker.selected
		combat_audio.play_cue({"kind": [1, 1, 2, 6, 5, 7, 3][option], "character": 5,
			"move": 0 if option == 0 else 3, "serial": combat_audio.played + 1, "actor": 0, "strength": 0 if option == 0 else 3}))
	add_child(dialog)
	dialog.confirmed.connect(func(): close_dialog(dialog))
	dialog.canceled.connect(func(): close_dialog(dialog))
	dialog.popup_centered(Vector2i(620, 550))

func close_dialog(dialog: Window) -> void:
	if dialog.has_meta("music_settings"): fighter_music.end_preview()
	var previous: Control = dialog.get_meta("return_focus").get_ref() if dialog.has_meta("return_focus") else null
	dialog.queue_free()
	call_deferred("resume_after_dialog", previous)

func resume_after_dialog(previous: Control = null) -> void:
	held.clear()
	if screen == "play":
		release_focus_from_ui()
		input_release_required = has_gameplay_input_held()
	elif is_instance_valid(previous) and previous.is_visible_in_tree():
		previous.grab_focus()
	else:
		menus.focus_page(screen)

func show_file(load_mode: bool) -> void:
	if load_mode and connection.active: return
	held.clear()
	importing = load_mode
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE if importing else FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.current_file = "fight-guild-moves.json"
	file_dialog.popup_centered()

func refresh_startup_limits(_value: float = 0) -> void:
	var definition := {}
	for key in ["button", "category", "mechanic"]: definition[key] = int(fields[key].control.value)
	fields.startup.control.min_value = CombatModel.startup_minimum(definition)
	fields.variantStartup.control.min_value = CombatModel.variant_startup_minimum(definition)

func show_kit_editor() -> void:
	if connection.active: return
	held.clear()
	var dialog := KitEditor.new()
	add_child(dialog)
	dialog.confirmed.connect(func(): close_dialog(dialog))
	dialog.canceled.connect(func(): close_dialog(dialog))
	dialog.applied.connect(func(): populate_editor(); reset_round())
	dialog.open_for(model, edit_character.selected, edit_move.selected)

func populate_editor() -> void:
	var definition := model.move(edit_character.selected, edit_move.selected)
	kit_button.visible = not model.extension(edit_character.selected, -1).is_empty()
	# Set classification before timing, so switching away from a slower move
	# cannot clamp a two-frame throw while loading the controls.
	for key in ["button", "category", "mechanic"]: fields[key].control.set_value_no_signal(definition[key])
	refresh_startup_limits()
	for slot in CombatModel.MOVE_IDS.size(): edit_move.set_item_text(slot, model.move_name(edit_character.selected, slot))
	editor_title.text = model.move_name(edit_character.selected, edit_move.selected) + " / " + ["NORMAL", "COMMAND", "SPECIAL", "DRIVE", "THROW"][definition.category]
	editor_title.text += " · DISABLED" if not definition.enabled else ""
	for key in fields:
		var control: Control = fields[key].control
		if key in ["artPose", "finishArtPose"]: control.max_value = FighterArt.catalog().fighters[edit_character.selected].get("signature_active", {}).get("frames", []).size()
		if control is CheckBox: control.button_pressed = bool(definition[key])
		elif control is OptionButton: control.selected = int(definition[key])
		else: control.value = float(definition[key]) / fields[key].scale
	var destinations: Array[String] = []
	for to in CombatModel.MOVE_IDS.size():
		if model.core.can_cancel(edit_character.selected, edit_move.selected, to, true): destinations.append(model.move_name(edit_character.selected, to))
	routes.text = "On hit → " + ", ".join(destinations) + (" / jump" if definition.jumpCancel else "")
	for rule in movement_fields:
		var entry: Dictionary = movement_fields[rule]
		var value: int = model.movement(edit_character.selected)[rule]
		if entry.control is OptionButton: entry.control.selected = value
		else: entry.control.value = float(value) / entry.scale
	var data := model.data()
	for i in 3: buffer_fields[i].value = data.inputRules[CombatModel.RULES[i]]
	for rule in momentum_fields:
		momentum_fields[rule].control.value = float(data.momentumRules[rule]) / momentum_fields[rule].scale
	for rule in recovery_fields:
		recovery_fields[rule].control.value = float(data.recoveryRules[rule]) / recovery_fields[rule].scale
	for rule in combo_fields: combo_fields[rule].value = data.comboRules[rule]
	for rule in tuning_fields:
		var entry: Dictionary = tuning_fields[rule]
		if entry.control is CheckBox: entry.control.button_pressed = bool(data.tuningRules[rule])
		else: entry.control.value = float(data.tuningRules[rule]) / entry.scale
	for rule in jump_fields: jump_fields[rule].value = data.jumpRules[rule]

func apply_timing_presets() -> void:
	if connection.active: return
	var level := int(fields.attackLevel.control.value)
	if level >= 0:
		fields.hitstop.control.value = [11, 12, 13, 14, 15][level]
		fields.hitstun.control.value = [12, 14, 16, 19, 21][level]
		fields.blockstun.control.value = [9, 11, 13, 16, 18][level]
	var tier := int(fields.counterTier.control.value)
	if tier >= 0:
		fields.counterHitstun.control.value = [0, 4, 0, 0][tier]
		fields.counterHitstop.control.value = [0, 3, 0, 0][tier]
		fields.counterFreezeFrames.control.value = [-1, -1, 21, 31][tier]
		fields.counterSlowFrames.control.value = [0, 0, 25, 35][tier]
	editor_status.text = "Preset copied into timing fields. Apply the move to test it."

func apply_tuning() -> void:
	if connection.active: return
	var data := model.data()
	for key in tuning_fields:
		var entry: Dictionary = tuning_fields[key]
		data.tuningRules[key] = int(entry.control.button_pressed) if entry.control is CheckBox else roundi(entry.control.value * entry.scale)
	for key in jump_fields: data.jumpRules[key] = int(jump_fields[key].value)
	var error := model.load_data(data)
	if error.is_empty(): reset_round()
	editor_status.text = "Defense, landing and wall tuning applied." if error.is_empty() else error

func apply_move() -> void:
	if connection.active: return
	var data := model.data()
	var definition: Dictionary = data.characters[edit_character.selected].moves[edit_move.selected]
	for key in fields:
		var control: Control = fields[key].control
		definition[key] = int(control.button_pressed) if control is CheckBox else control.selected if control is OptionButton else roundi(control.value * fields[key].scale)
	var error := model.load_data(data)
	if not error.is_empty(): editor_status.text = error; return
	populate_editor()
	reset_round()
	editor_status.text = "Applied. Save locally or export to keep this set."

func apply_buffer() -> void:
	if connection.active: return
	var data := model.data()
	for i in 3: data.inputRules[CombatModel.RULES[i]] = int(buffer_fields[i].value)
	var error := model.load_data(data)
	if error.is_empty(): reset_round()
	editor_status.text = "Input settings applied." if error.is_empty() else error

func apply_momentum() -> void:
	if connection.active: return
	var data := model.data()
	for rule in momentum_fields:
		data.momentumRules[rule] = roundi(momentum_fields[rule].control.value * momentum_fields[rule].scale)
	var error := model.load_data(data)
	if error.is_empty(): reset_round()
	editor_status.text = "Momentum settings applied." if error.is_empty() else error

func apply_movement() -> void:
	if connection.active: return
	var data := model.data()
	for rule in movement_fields:
		var entry: Dictionary = movement_fields[rule]
		data.characters[edit_character.selected].movement[rule] = entry.control.selected if entry.control is OptionButton else roundi(entry.control.value * entry.scale)
	var error := model.load_data(data)
	if error.is_empty(): reset_round()
	editor_status.text = "Movement settings applied." if error.is_empty() else error

func apply_recovery() -> void:
	if connection.active: return
	var data := model.data()
	for rule in combo_fields: data.comboRules[rule] = int(combo_fields[rule].value)
	for rule in recovery_fields:
		data.recoveryRules[rule] = roundi(recovery_fields[rule].control.value * recovery_fields[rule].scale)
	var error := model.load_data(data)
	if error.is_empty(): reset_round()
	editor_status.text = "Recovery and wall settings applied." if error.is_empty() else error

func release_focus_from_ui() -> void:
	var focus := get_viewport().gui_get_focus_owner()
	if focus != null: focus.release_focus()

func is_editing() -> bool:
	return get_viewport().gui_get_focus_owner() != null or has_open_dialog()

func has_open_dialog() -> bool:
	for child in get_children():
		if child is Window and child.visible: return true
	return false

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_F8 or event.physical_keycode == KEY_F8):
		if preview_super_freeze(1 if event.shift_pressed else 0):
			get_viewport().set_input_as_handled()
			return
	if screen == "sides" and not has_open_dialog() and menus.sides.handle_input(event):
		get_viewport().set_input_as_handled()
		return
	if screen == "entry":
		if event.is_action_released("ui_accept"): entry_accept_released = true
		if event.is_action_pressed("ui_cancel"):
			cancel_match_entry()
		elif entry_accept_released and (event.is_action_pressed("ui_accept") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START)):
			match_entry.request_skip()
		if event is InputEventKey or event is InputEventJoypadButton:
			get_viewport().set_input_as_handled()
			return
	if not has_open_dialog() and not (event is InputEventKey and event.echo):
		if (event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE)) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START):
			if screen == "play": open_pause()
			else: menu_back()
			get_viewport().set_input_as_handled()
			return
		if screen != "play" and event.is_action_pressed("ui_cancel"):
			menu_back()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey:
		var code: int = event.physical_keycode if event.physical_keycode else event.keycode
		if not event.pressed: held.erase(code)
		elif application_focused and screen == "play" and super_preview_player < 0 and not changing_layers() and not input_release_required and not is_editing() and not event.echo: held[code] = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		application_focused = false
		held.clear()
		input_release_required = true
		if is_instance_valid(menus) and screen == "play" and not connection.active: open_pause()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		application_focused = true
		input_release_required = true

func read_input(player: int) -> int:
	if not application_focused or screen != "play" or super_preview_player >= 0 or changing_layers() or input_release_required or is_editing(): return 0
	return fighter_inputs.sample(player, held)

func preview_super_freeze(player: int, ticks: int = SuperFreeze.DEFAULT_TICKS) -> bool:
	if connection.active or activity not in ["training", "development"] or screen != "play" or changing_layers() or has_open_dialog() or super_preview_player >= 0: return false
	if player not in [0, 1]: return false
	var state := model.state()
	if int(state.winner) >= 0 or int(state.wallBreakTime) > 0 or int(state.superFreezeTime) > 0: return false
	release_focus_from_ui()
	held.clear()
	input_release_required = true
	super_preview_player = player
	super_preview_tick = 0
	super_preview_duration = clampi(ticks, 24, 180)
	if DisplayServer.get_name() != "headless":
		var image := get_viewport().get_texture().get_image()
		if image != null and not image.is_empty(): super_preview_background = ImageTexture.create_from_image(image)
	super_freeze.reduced_motion = motion.reduced
	var fighter: Dictionary = state.players[player]
	super_freeze.present(int(fighter.character), int(fighter.facing), 0, super_preview_duration)
	return true

func cancel_super_freeze_preview() -> void:
	if super_preview_player >= 0:
		held.clear()
		input_release_required = true
	super_preview_player = -1
	super_preview_tick = 0
	super_preview_background = null
	if is_instance_valid(super_freeze): super_freeze.clear()

func tick_super_freeze_preview() -> void:
	# Preview owns only a presentation clock. No core tick means health, motion,
	# buffers, projectiles, hitstop and status durations all remain unchanged.
	super_preview_tick += 1
	if super_preview_tick >= super_preview_duration:
		cancel_super_freeze_preview()
		return
	var fighter: Dictionary = model.state().players[super_preview_player]
	super_freeze.present(int(fighter.character), int(fighter.facing), super_preview_tick, super_preview_duration)

func reset_round() -> void:
	cancel_super_freeze_preview()
	lab.stop()
	lab.clear_trace()
	if connection.active: return
	round_resolved = false
	model.reset(characters)
	if mode.selected == 0:
		for p in 2: model.core.set_training_momentum(p, [0, 5000, 10000][training_momentum.selected])
	held.clear()
	history.clear()
	last_raw = 0
	paused = false
	pause_button.text = "Pause"
	release_focus_from_ui()

func advance_one() -> void:
	if connection.active or screen != "play" or super_preview_player >= 0 or changing_layers() or activity not in ["training", "development"]: return
	release_focus_from_ui()
	paused = true
	pause_button.text = "Resume"
	simulate_local()

func dummy_reversal_input(fighter: Dictionary, away: int) -> int:
	var guard := away | 4
	var selected: Dictionary = {}
	for slot in CombatModel.MOVE_IDS.size():
		var action: Dictionary = model.move(fighter.character, slot)
		if not action.enabled or action.air or action.category != 2 or action.stanceRequired == 2 or action.actionType == 1: continue
		if int(action.actionType) in [8, 13, 14, 15] and int(fighter.momentum) < 6667: continue
		if selected.is_empty() or action.reversalEligible > selected.reversalEligible: selected = action
	if selected.is_empty(): return guard
	var digits: String = str(selected.motion if selected.motion else selected.direction)
	var index: int = digits.length() - int(fighter.stun)
	if index < 0 or index >= digits.length(): return guard
	var direction: int = int(digits[index])
	var column: int = (direction - 1) % 3 - 1
	var bits: int = (4 if direction <= 3 else 8 if direction >= 7 else 0)
	if column != 0: bits |= away if column < 0 else (1 if away == 2 else 2)
	if fighter.stun == 1: bits |= (16 << int(selected.button))
	return bits

func simulate_local() -> void:
	var a := read_input(0)
	var b := read_input(1)
	if mode.selected == 0:
		var state := model.state()
		var away := 2 if state.players[1].x > state.players[0].x else 1
		if dummy.selected == 5:
			b = 128 if state.players[1].move < 0 and state.players[1].stun == 0 else 0
		elif dummy.selected == 6:
			b = away | 4
			if state.hitstop == 0: b = dummy_reversal_input(state.players[1], away)
		elif dummy.selected != 7:
			b = [0, away, away | 4, RollbackSession.scripted_input(model.frame(), 1), away | 4 | 2048][dummy.selected]
	var raw := lab.inputs(a, b) if activity in ["training", "development"] else Vector2i(a, b)
	var before := model.state()
	model.step(raw.x, raw.y)
	if activity in ["training", "development"]: lab.observe(model, before, raw)
	record_input(raw.x)

func record_input(raw: int) -> void:
	if raw != 0 and raw != last_raw:
		var facing := model.core.read_value(connection.player if connection.active else 0, 2)
		var x := (int(bool(raw & 2)) - int(bool(raw & 1))) * facing
		var y := int(bool(raw & 8)) - int(bool(raw & 4))
		var notation: String = ["", "↙", "↓", "↘", "←", "·", "→", "↖", "↑", "↗"][5 + x + y * 3]
		for b in 5:
			if raw & (16 << b): notation += CombatModel.BUTTONS[b]
		if raw & 512: notation += " Dash"
		if raw & 1024: notation += " *"
		if raw & 2048: notation += " FD"
		history.append(notation)
		if history.size() > 8: history.pop_front()
	last_raw = raw

func _physics_process(_delta: float) -> void:
	if input_release_required and not has_gameplay_input_held(): input_release_required = false
	if connection.active:
		var raw := read_input(0)
		connection.tick(raw)
		record_input(raw)
	elif super_preview_player >= 0:
		if screen == "play" and not has_open_dialog(): tick_super_freeze_preview()
	elif screen == "play" and not changing_layers() and not paused and not has_open_dialog():
		simulate_local()

func _process(_delta: float) -> void:
	if screen not in ["play", "entry"] and not changing_layers():
		pause_tableau.visible = menus.pause_mix > 0.001 and pause_tableau.captured_frame >= 0
	var state := model.state()
	var confirmed := model.frame() - 1
	var music_active := screen in ["entry", "play", "pause", "results"] or (screen == "fighters" and selection_return == "pause")
	fighter_music.update_context(music_active, [state.players[0].character, state.players[1].character],
		screen == "pause" or paused or has_open_dialog(), application_focused and get_window().has_focus())
	if connection.active and connection.session != null:
		confirmed = mini(confirmed, mini(connection.session.confirmed[0], connection.session.confirmed[1]))
	# Let the finishing impact ring out across the result/intermission transition.
	var sound_active: bool = screen == "play" or (state.winner >= 0 and screen in ["entry", "results"])
	combat_audio.consume(model, confirmed, sound_active and not paused and not has_open_dialog() and get_window().has_focus())
	arena.round_label = MatchCeremony.round_call(round_number)
	arena.score = match_score.wins
	arena.presentation_active = screen in ["entry", "results"]
	arena.diagnostics = activity in ["training", "development"]
	arena.feedback.reduced_motion = motion.reduced
	if match_entry.phase != "loading": arena.refresh(model, state, show_boxes, paused or int(state.superFreezeTime) > 0)
	if super_preview_player < 0:
		if screen == "play" and int(state.superFreezeTime) > 0:
			var actor: Dictionary = state.players[int(state.superFreezeActor)]
			super_freeze.reduced_motion = motion.reduced
			super_freeze.present(int(actor.character), int(actor.facing), int(state.superFreezeDuration) - int(state.superFreezeTime), int(state.superFreezeDuration), CombatSupers.title(int(actor.character), int(actor.lastMove)))
		else: super_freeze.clear()
	if screen in ["play", "pause"] and activity in ["local", "online"] and state.winner >= 0:
		finish_scrum(state)
	input_label.text = "INPUT HISTORY   " + ("   ".join(history) if not history.is_empty() else "—")
	var fighter: Dictionary = state.players[connection.player if connection.active else 0]
	action_label.text = "READY" if fighter.lastMove < 0 else model.move_name(fighter.character, fighter.lastMove) + (" / CONTACT" if fighter.contact else "")
	if lab.recording_now: action_label.text = "REC · %d / 1800f" % lab.recording.size()
	elif lab.playback: action_label.text = "REPLAY · %d / %df" % [lab.cursor, lab.recording.size()]
	lab_status.text = lab.message
	if lab_window.visible: timeline.queue_redraw()

func run_trial() -> void:
	var result := RollbackSession.trial(model.data())
	trial_status.text = "PASS · %d corrections · %08x" % [result.rollbacks, result.hash] if result.get("pass", false) else "FAIL: " + str(result)

func start_network(host: bool) -> void:
	if connection.active or screen != "online": return
	if not host and address.text.strip_edges().is_empty():
		net_status.text = "Enter the host address before joining."
		address.grab_focus()
		return
	# SpinBox updates its text on a later frame; only commit text the user is editing.
	if port.get_line_edit().has_focus(): port.apply()
	var result := connection.begin(model, host, address.text.strip_edges(), int(port.value), characters[0])
	if result != OK: net_status.text = "Could not open connection: " + error_string(result); return
	lock_online(true)
	paused = false
	held.clear()
	menus.focus_page("online")

func lock_online(locked: bool) -> void:
	for control in locked_buttons: control.disabled = locked
	for field in fields.values():
		if field.control is SpinBox: field.control.editable = not locked
		else: field.control.disabled = locked
	for spin in buffer_fields: spin.editable = not locked
	for field in momentum_fields.values(): field.control.editable = not locked
	for field in recovery_fields.values(): field.control.editable = not locked
	for spin in jump_fields.values(): spin.editable = not locked
	for field in tuning_fields.values():
		if field.control is CheckBox: field.control.disabled = locked
		else: field.control.editable = not locked
	for field in movement_fields.values():
		if field.control is OptionButton: field.control.disabled = locked
		else: field.control.editable = not locked
	mode.disabled = locked
	training_momentum.disabled = locked or mode.selected == 1
	dummy.disabled = locked or mode.selected == 1
	menus.set_connecting(locked)
