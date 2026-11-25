extends SceneTree

class Recorder extends CombatAudio:
	var heard: Array = []
	func play_cue(cue: Dictionary) -> void: heard.append(cue.duplicate(true))

var failures := 0
var checks := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; printerr("Sky Foundry: "+message)
func _initialize() -> void: call_deferred("run")

func run() -> void:
	var model := CombatModel.new()
	var batch: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	check(model.load_file("res://data/workshop/"+str(batch.file)).is_empty(),"Data import")
	var fingerprint := model.fingerprint()
	var arena = load("res://scripts/arena.gd").new(); arena.size=Vector2(1280,720);root.add_child(arena)
	var recorder := Recorder.new();root.add_child(recorder)
	await process_frame
	var spec := SuperAnimation.profile(0,16)
	var sheet := FighterArt.sheet(0,str(spec.phase))
	check(sheet.frames.size()==16,"Missing body drawings")
	for frame in sheet.frames:
		check(ResourceLoader.exists(FighterArt.DIRECTORY+str(frame.file)),"Missing original sheet")
		check(int(frame.body_height)==int(sheet.body_height),"Anatomical scale changes per pose")
	var seen := {}
	for owner in 2:
		for facing in [-1,1]:
			for receiver in 6:
				model.reset([0,receiver] if owner==0 else [receiver,0])
				model.core.preview_place(owner,50000-facing*5000,0,10000)
				model.core.preview_place(1-owner,50000+facing*5000,16000,0)
				model.core.preview_begin(owner,16)
				var pair_seen := false
				var sounds := []
				var replay_snapshot := PackedByteArray()
				var replay_hash := 0
				for tick in 260:
					var state := model.state()
					var before: PackedByteArray = model.core.snapshot()
					arena.refresh(model,state,false,false)
					check(model.core.snapshot()==before,"Rendering changed gameplay")
					var cue := SuperAnimation.selection(model,state,owner)
					if not cue.is_empty():
						seen[int(cue.pose)]=true
						check(int(arena.sprites[owner].get_meta("pose"))==int(cue.pose),"Wrong exposure")
						var world_scale: float = arena.size.x/1000.0*arena.camera_zoom
						check(is_equal_approx(arena.sprites[owner].scale.y,150.0/float(sheet.body_height)*world_scale),"Body resized between states")
						if str(cue.stage)=="paired":
							pair_seen=true
							var victim: Sprite2D = arena.sprites[1-owner]
							var frame: Dictionary = FighterArt.sheet(receiver,"knockdown_back").frames[0]
							var anchor := Vector2(frame.pivot[0],lerpf(frame.bounds[1],frame.bounds[3],0.82))
							var support := victim.position+((anchor+victim.offset)*victim.scale).rotated(victim.rotation)
							check(support.distance_to(SuperAnimation.grip(arena.sprites[owner],0))<0.01,"Receiver detached from supporting hand")
							var old_position := victim.position
							arena.refresh(model,state,false,true)
							check(victim.position.is_equal_approx(old_position),"Pause/repaint advances attachment")
							var depth: int = arena.foreground_player(state)
							check(arena.sprites[depth].get_index()>arena.sprites[1-depth].get_index(),"Capture depth incorrect")
					if tick==80: replay_snapshot=before
					if tick==110: replay_hash=model.state_hash()
					model.step(0,0)
					for event in model.cues.events_at(model.frame()-1):
						if event.has("sound"): sounds.append(event.sound)
				check(pair_seen and int(model.state().players[1-owner].health)==667,"Capture or single 333-damage finish changed")
				check(sounds.size()==3 and sounds[0].ends_with("clamp.wav") and sounds[1].ends_with("lift.wav") and sounds[2].ends_with("fall.wav"),"Repeated or missing cinematic sound cues")
				check(model.core.restore(replay_snapshot),"Snapshot restore")
				for tick in 30: model.step(0,0)
				check(model.state_hash()==replay_hash,"Resimulation diverged")
	check(seen.size()==16,"Not all authored body drawings appeared")
	# Grounded and out-of-range targets must never see the successful lift/slam.
	for target_y in [0,40000]:
		model.reset([0,4]);model.core.preview_place(0,40000,0,10000);model.core.preview_place(1,85000,target_y,0)
		model.core.preview_begin(0,16)
		for tick in 130:
			var state:=model.state();var cue:=SuperAnimation.selection(model,state,0)
			check(state.pairKind==0,"Miss captured target")
			if not cue.is_empty():check(cue.stage not in ["paired","connected"] and int(cue.pose) not in range(2,14),"Whiff played a successful throw")
			model.step(0,0)
			check(not model.cues.events_at(model.frame()-1).any(func(c:Dictionary)->bool:return c.has("sound")),"Miss played capture audio")
		check(model.state().players[1].health==1000,"Miss dealt damage")
	# Audio remains behind confirmation and is not replayed by pause or seeks.
	model.reset([0,4]);model.core.preview_place(0,40000,0,10000);model.core.preview_place(1,47000,16000,0);model.core.preview_begin(0,16)
	var before_capture: PackedByteArray
	for tick in 59:
		if tick==58:before_capture=model.core.snapshot()
		model.step(0,0)
	recorder.consume(model,-1,true)
	check(recorder.heard.is_empty(),"Unconfirmed capture played audio")
	check(model.core.restore(before_capture),"Capture snapshot restore")
	model.step(0,0)
	recorder.consume(model,model.frame()-1,true)
	check(recorder.heard.filter(func(c:Dictionary)->bool:return c.has("sound")).size()==1,"Corrected capture sound missing or duplicated")
	var count := recorder.heard.size()
	for tick in 4:recorder.consume(model,model.frame()-1,true)
	check(recorder.heard.size()==count,"Repeated confirmation replayed audio")
	var freeze := SuperFreeze.new();root.add_child(freeze)
	freeze.present(0,1,20,54,"Sky Foundry")
	check(freeze.custom_portrait,"Dedicated face missing")
	var texture := freeze.portrait
	freeze.present(0,-1,40,54,"Sky Foundry")
	check(freeze.portrait==texture,"Mirroring/closing changed portrait")
	freeze.present(0,1,20,54,"Iron Dominion")
	check(not freeze.custom_portrait,"Sky Foundry portrait leaked to another super")
	check(model.fingerprint()==fingerprint,"Presentation changed move data")
	freeze.queue_free();recorder.queue_free();arena.queue_free();await process_frame
	print("Sky Foundry animation: %d checks / %d failures" % [checks,failures])
	quit(1 if failures else 0)
