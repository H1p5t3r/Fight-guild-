extends SceneTree

var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func begin(model: CombatModel, character: int, move: int, air: bool = false) -> void:
	model.reset([character, 4 if character != 4 else 5])
	model.core.preview_place(0,35000,14000 if air else 0,10000)
	model.core.preview_place(1,65000,0,10000)
	check(model.core.preview_begin(0,move), "Could not start test move %d/%d" % [character,move])
func cues(model: CombatModel) -> Array: return CombatOverhead.describe(model,model.state())

func run() -> void:
	var model := CombatModel.new()
	var batch: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	check(model.load_file("res://data/workshop/" + str(batch.file)).is_empty(), "Current combat data did not load")
	var atlas: Texture2D = load(CombatOverhead.DIRECTORY + str(CombatOverhead.catalog.file))
	for name in CombatOverhead.catalog.frames:
		check(Rect2(Vector2.ZERO,atlas.get_size()).encloses(CombatOverhead.texture(name).region), "Overhead art leaves its atlas: " + str(name))
	check(cues(model).is_empty(), "Neutral shows a warning")
	# Every currently authored overhead, including all six fighters' jump-ins.
	var total := 0
	for c in CombatModel.CHARACTERS.size():
		for m in CombatModel.MOVE_IDS.size():
			var move := model.move(c,m)
			if move.enabled == 0 or move.hitLevel != 2: continue
			begin(model,c,m,move.air != 0)
			model.step(256 if move.actionType == 5 else 0,0)
			check(not cues(model).is_empty(), "Authored overhead missing its startup cue: %s/%s" % [CombatModel.CHARACTERS[c],CombatModel.MOVE_IDS[m]])
			total += 1
	check(total >= 30, "Overhead coverage unexpectedly shrank")
	for m in [0,6,23,24]:
		begin(model,5,m)
		check(cues(model).is_empty(), "Mid, low or throw mislabelled as overhead")
	# The guard level remains data-driven; no list of fighter/button exceptions.
	begin(model,1,15)
	var base := (CombatModel.MOVE_IDS.size() + 15) * CombatModel.FIELDS.size()
	var level := base + CombatModel.FIELDS.find("hitLevel")
	model.config[level] = 0
	check(cues(model).is_empty(), "An edited mid retained an overhead warning")
	model.config[level] = 2
	check(not cues(model).is_empty(), "An edited overhead did not regain its warning")
	# Even an edited high flag must not label a non-blockable action high.
	for example in [[5,23],[5,13],[4,22],[1,13],[0,13]]:
		begin(model,example[0],example[1])
		var at: int = (example[0] * CombatModel.MOVE_IDS.size() + example[1]) * CombatModel.FIELDS.size() + CombatModel.FIELDS.find("hitLevel")
		var old := model.config[at]; model.config[at] = 2
		check(cues(model).is_empty(), "Throw, wound capture, pull, dash or shield stance suggests high guard")
		model.config[at] = old
	begin(model,1,15)
	var arena = load("res://scripts/arena.gd").new(); root.add_child(arena); arena.size = Vector2(1280,720)
	var snapshot := model.core.snapshot()
	var before := model.state_hash()
	arena.refresh(model,model.state(),false,false)
	var placed: Array = arena.overhead_cues.duplicate(true)
	arena.refresh(model,model.state(),false,true)
	check(arena.overhead_cues == placed and model.state_hash() == before, "Repaint/pause advanced the cue or changed combat")
	for tick in 9: model.step(0,0)
	var expected := cues(model)
	check(model.core.restore(snapshot), "Overhead snapshot restore failed")
	for tick in 9: model.step(0,0)
	check(cues(model) == expected, "Rollback/replay changed warning timing")
	var quiet := CombatOverhead.describe(model,model.state(),true)
	check(quiet.size() == 1 and quiet[0].flash == 0 and quiet[0].reduced and quiet[0].key == 1, "Reduced motion hides the tell or retains a bright flash")
	for tick in 22: model.step(0,0)
	check(cues(model).is_empty(), "Recovery retained a warning")
	begin(model,2,13)
	for tick in 22: model.step(256,0)
	check(model.state().players[0].guardButton != 0 and not cues(model).is_empty(), "Held charge loses the warning at its uncharged startup")
	# Interruption must clear the warning immediately, not play a detached tail.
	begin(model,1,15)
	model.core.preview_place(0,47000,0,10000); model.core.preview_place(1,53000,0,10000)
	model.core.preview_begin(1,0)
	for tick in 12: model.step(0,0)
	check(model.state().players[0].stun > 0 and cues(model).is_empty(), "Interrupted overhead left an amber tell")
	begin(model,5,26)
	model.core.preview_begin(0,0)
	check(cues(model).is_empty(), "Replacing an overhead with a mid leaves a stale cue")
	var state := model.state(); state.wallBreakTime = 10
	check(CombatOverhead.describe(model,state).is_empty(), "Wall travel shows a warning")
	model.reset()
	check(cues(model).is_empty(), "Round reset left a warning")
	arena.queue_free(); await process_frame
	print("Overhead warning: %d checks / %d failures; %d authored overheads covered" % [checks,failures,total])
	quit(1 if failures else 0)
