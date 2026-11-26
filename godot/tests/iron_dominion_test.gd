extends SceneTree

var failures:=0
var checks:=0
func check(value:bool,message:String)->void:
	checks+=1
	if not value:failures+=1;printerr("Iron Dominion: "+message)
func _initialize()->void:call_deferred("run")

func run()->void:
	var model:=CombatModel.new()
	var batch:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	check(model.load_file("res://data/workshop/"+str(batch.file)).is_empty(),"Data import")
	var fingerprint:=model.fingerprint()
	var arena=load("res://scripts/arena.gd").new();arena.size=Vector2(1280,720);root.add_child(arena)
	await process_frame
	var spec:=SuperAnimation.profile(0,31);var seen:={}
	check(FighterArt.sheet(0,spec.phase).frames.size()==20,"Missing body keys")
	for owner in 2:
		for facing in [-1,1]:
			for receiver in 6:
				model.reset([0,receiver] if owner==0 else [receiver,0])
				model.core.preview_place(owner,50000-facing*6000,0,10000)
				model.core.preview_place(1-owner,50000+facing*6000,0,0)
				model.core.preview_begin(owner,31)
				var sounds:=[];var pair_seen:=false
				for tick in 270:
					var state:=model.state();var saved:PackedByteArray=model.core.snapshot()
					arena.refresh(model,state,false,false)
					check(model.core.snapshot()==saved,"Presentation mutated simulation")
					var cue:=SuperAnimation.selection(model,state,owner)
					if not cue.is_empty():
						seen[int(cue.pose)]=true
						check(is_equal_approx(arena.sprites[owner].scale.y,150.0/445.0*arena.size.x/1000.0*arena.camera_zoom),"Anatomical scale changed")
						if str(cue.stage)=="paired":
							pair_seen=true
							check(arena.sprites[1-owner].get_meta("reaction_family")==("air" if int(state.players[1-owner].y)>0 else "chest"),"Captured receiver returned to neutral")
							if int(state.pairClock) in [40,70]:
								check(int(cue.pose)==(6 if int(state.pairClock)==40 else 10),"Shield strike missed saved impact beat")
								var family:="air" if int(state.players[1-owner].y)>0 else "chest"
								var recoil:=CombatReactions.frame_for(receiver,family,2)
								var rect:Array=recoil.region
								check(arena.sprites[1-owner].texture.region==Rect2(rect[0],rect[1],rect[2],rect[3]),"Receiver recoil missed native contact")
							var pose:=int(cue.pose)
							arena.refresh(model,state,false,true)
							check(int(arena.sprites[owner].get_meta("pose"))==pose,"Pause changed exposure")
					model.step(0,0)
					for event in model.cues.events_at(model.frame()-1):
						if event.has("sound"):sounds.append(event.sound)
				check(pair_seen and int(model.state().players[1-owner].health)==720,"Confirmed damage changed")
				check(sounds.size()==4,"Missing or repeated authored impact sounds")
	check(seen.size()==20,"Not all 20 drawings exposed")
	for blocking in [false,true]:
		model.reset([0,4]);model.core.preview_place(0,44000 if blocking else 26000,0,10000);model.core.preview_place(1,56000 if blocking else 90000,0,0)
		model.core.preview_begin(0,31)
		for tick in 200:
			var state:=model.state();var cue:=SuperAnimation.selection(model,state,0)
			check(state.pairKind==0,"Block/whiff entered cinematic")
			if not cue.is_empty():check(str(cue.stage) not in ["paired","connected"],"Block/whiff played confirmed sequence")
			model.step(0,2 if blocking else 0)
			check(not model.cues.events_at(model.frame()-1).any(func(c:Dictionary)->bool:return c.has("sound")),"Block/whiff played confirmed impact audio")
		check(int(model.state().players[1].health)==(992 if blocking else 1000),"Block/whiff damage changed")
	check(model.fingerprint()==fingerprint,"Move data changed")
	# Editing duration must keep poses and sounds on the native rounded impacts.
	for duration in [91,100,120]:
		var data:=model.data();data.characters[0].moves[31].grabFrames=duration
		check(model.load_data(data).is_empty(),"Edited duration import")
		model.reset([0,4]);model.core.preview_place(0,44000,0,10000);model.core.preview_place(1,56000,0,0);model.core.preview_begin(0,31)
		var sounds:=0
		for tick in 300:
			var state:=model.state()
			if int(state.pairKind)==8 and int(state.pairClock) in [duration*45/100,duration*78/100]:
				var cue:=SuperAnimation.selection(model,state,0)
				check(int(cue.pose)==(6 if int(state.pairClock)==duration*45/100 else 10),"Edited duration desynchronized strike")
			model.step(0,0)
			for event in model.cues.events_at(model.frame()-1):
				if event.has("sound"):sounds+=1
		check(sounds==4 and int(model.state().players[1].health)==720,"Edited duration changed sound count/damage")
	arena.queue_free();await process_frame
	print("Iron Dominion animation: %d checks / %d failures"%[checks,failures])
	quit(1 if failures else 0)
