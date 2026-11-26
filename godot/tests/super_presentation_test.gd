extends SceneTree

var failures:=0
var checks:=0
var title:="Super"
func check(value:bool,message:String)->void:
	checks+=1
	if not value:failures+=1;printerr(title+": "+message)
func _initialize()->void:call_deferred("run")

func run()->void:
	var args:=OS.get_cmdline_user_args()
	var character:=int(args[args.find("--character")+1]) if args.has("--character") else 1
	var slot:=int(args[args.find("--slot")+1]) if args.has("--slot") else 12
	title=CombatSupers.title(character,slot)
	var model:=CombatModel.new()
	var batch:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	check(model.load_file("res://data/workshop/"+str(batch.file)).is_empty(),"Data import")
	var fingerprint:=model.fingerprint();var move:=model.move(character,slot)
	var arena=load("res://scripts/arena.gd").new();arena.size=Vector2(1280,720);root.add_child(arena)
	await process_frame
	var spec:=SuperAnimation.profile(character,slot);var seen:={}
	var body:=FighterArt.sheet(character,spec.phase)
	for owner in 2:
		for facing in [-1,1]:
			for receiver in 6:
				model.reset([character,receiver] if owner==0 else [receiver,character])
				model.core.preview_place(owner,50000-facing*6000,0,10000)
				model.core.preview_place(1-owner,50000+facing*6000,0,0)
				check(model.core.preview_begin(owner,slot)==1,"Super activation rejected")
				var sounds:=[];var paired:=false;var restored:=PackedByteArray();var replay_hash:=0
				for tick in 300:
					var state:=model.state();var saved:PackedByteArray=model.core.snapshot()
					arena.refresh(model,state,false,false)
					check(model.core.snapshot()==saved,"Presentation mutated gameplay")
					var cue:=SuperAnimation.selection(model,state,owner)
					if not cue.is_empty():
						seen[int(cue.pose)]=true
						if character==4 and slot==14:
							if str(cue.stage)=="paired" or str(cue.stage)=="connected":
								check(int(cue.facing)==facing,"Side-switch art reversed twice")
							if str(cue.stage)=="connected":
								check((int(state.players[1-owner].x)-int(state.players[owner].x))*facing<0,"Undertow lost side switch")
						check(is_equal_approx(arena.sprites[owner].scale.y,150.0/float(body.body_height)*arena.size.x/1000.0*arena.camera_zoom),"Anatomical scale changed")
						if str(cue.stage)=="paired":
							paired=true
							if int(state.pairClock) in [int(state.pairTicks)*45/100,int(state.pairTicks)*78/100]:
								check(int(cue.pose)==(6 if int(state.pairClock)==int(state.pairTicks)*45/100 else 10),"Authored impact missed saved beat")
							arena.refresh(model,state,false,true)
							check(int(arena.sprites[owner].get_meta("pose"))==int(cue.pose),"Pause changed exposure")
						if str(cue.stage)=="connected" and int(cue.tick)==0 and int(state.hitstop)>0 and spec.has("finish_receiver"):
							check(arena.sprites[1-owner].get_meta("reaction_family")==spec.finish_receiver,"Final contact lost receiver reaction")
							if character==5 and slot==12:
								check(int(state.players[1-owner].bleedTime)>0 and int(state.players[1-owner].bleedSource)>0,"Bloodletting finish lost owned bleed")
								check(int(state.players[1-owner].knockdown)==2,"Bloodletting finish lost hard knockdown")
					if tick==80:restored=saved
					if tick==110:replay_hash=model.state_hash()
					model.step(0,0)
					for event in model.cues.events_at(model.frame()-1):
						if event.has("sound"):sounds.append(event.sound)
				check(paired and int(model.state().players[1-owner].health)==1000-int(move.damage),"Single confirmed damage changed")
				check(sounds.size()==spec.sounds.size(),"Missing/repeated authored impact audio")
				if character==3:check(int(model.state().players[owner].stance)==1,"Tapper super lost stance finish")
				check(model.core.restore(restored),"Snapshot restore")
				for tick in 30:model.step(0,0)
				check(model.state_hash()==replay_hash,"Presentation caused replay divergence")
	for blocking in [false,true]:
		model.reset([character,4]);model.core.preview_place(0,44000 if blocking else 15000,0,10000);model.core.preview_place(1,56000 if blocking else 90000,0,0)
		model.core.preview_begin(0,slot)
		var block_poses:=[]
		for tick in 220:
			var state:=model.state();var cue:=SuperAnimation.selection(model,state,0)
			check(state.pairKind==0,"Block/whiff entered a successful cinematic")
			if not cue.is_empty():
				seen[int(cue.pose)]=true
				check(str(cue.stage) not in ["paired","connected"],"Block/whiff played confirmed sequence")
			model.step(0,2 if blocking else 0)
			if character==3 and slot==31 and blocking:
				for event in model.cues.events_at(model.frame()-1):
					if int(event.kind)==2:
						var contact:=SuperAnimation.selection(model,model.state(),0)
						block_poses.append(int(contact.pose))
			check(not model.cues.events_at(model.frame()-1).any(func(c:Dictionary)->bool:return c.has("sound")),"Block/whiff played confirmed impact audio")
		if character==3 and slot==12:check(int(model.state().players[0].stance)==0,"Last Orders entered stance on miss/block")
		var damage:=1000-int(model.state().players[1].health)
		check(damage>0 and damage<int(move.damage) if blocking else damage==0,"Block/whiff damage rule changed")
		if character==3 and slot==31:
			check(int(model.state().players[0].stance)==1,"Whiskey Chaser lost Dempsey stance")
			if blocking:check(damage==15 and block_poses==[1,6,10],"Three blocked hooks lost pose/contact alignment: "+str(block_poses))
	check(seen.size()==body.frames.size(),"Not every hit/block/whiff drawing was exposed")
	check(model.fingerprint()==fingerprint,"Art changed move data")
	for duration in [int(spec.pair_ticks)+1,int(spec.pair_ticks)+10,mini(120,int(spec.pair_ticks)+30)]:
		var data:=model.data();data.characters[character].moves[slot].grabFrames=duration
		check(model.load_data(data).is_empty(),"Edited duration import")
		model.reset([character,4]);model.core.preview_place(0,44000,0,10000);model.core.preview_place(1,56000,0,0);model.core.preview_begin(0,slot)
		var sounds:=0
		for tick in 330:
			var state:=model.state()
			if int(state.pairKind)==8 and int(state.pairClock) in [duration*45/100,duration*78/100]:
				var cue:=SuperAnimation.selection(model,state,0)
				check(int(cue.pose)==(6 if int(state.pairClock)==duration*45/100 else 10),"Edited duration desynchronized strike")
			model.step(0,0)
			for event in model.cues.events_at(model.frame()-1):
				if event.has("sound"):sounds+=1
		check(sounds==spec.sounds.size() and int(model.state().players[1].health)==1000-int(move.damage),"Edited duration changed sounds/damage")
	arena.queue_free();await process_frame
	print(title+" animation: %d checks / %d failures"%[checks,failures])
	quit(1 if failures else 0)
