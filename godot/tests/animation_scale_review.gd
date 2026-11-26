extends SceneTree

# Render source drawings at one world zoom. Never fit a pose to its tile:
# head/torso/limb proportions must be compared with the reference beside it.
var tile_size := Vector2(500, 340)
var zoom := 1.55
var floor_y := 312.0
var center_ratio := 0.4
var page: Control

func _initialize() -> void: call_deferred("run")

func reference_phase(character: int) -> String:
	return "ready" if character in [3,5] else "idle"

func tile(character: int, phase: String, pose: int, column: int, row: int, title: String) -> void:
	var box := Control.new()
	box.position=Vector2(column*tile_size.x,row*tile_size.y+48)
	box.size=tile_size;box.clip_contents=true;page.add_child(box)
	var floor_line:=ColorRect.new();floor_line.color=Color("48535e")
	floor_line.position=Vector2(0,floor_y);floor_line.size=Vector2(tile_size.x,1);box.add_child(floor_line)
	var label:=Label.new();label.position=Vector2(10,5);label.text=title
	label.add_theme_font_size_override("font_size",18);box.add_child(label)
	var sprite:=Sprite2D.new();sprite.position=Vector2(tile_size.x*center_ratio,floor_y);box.add_child(sprite)
	FighterArt.apply(sprite,character,phase,pose,zoom,1)
	for child in sprite.get_children():
		if child is Sprite2D:child.hide()
	var info:=FighterArt.sheet(character,phase)
	var note:=Label.new();note.position=Vector2(10,floor_y+3)
	note.text="%s  #%d  /  H %s"%[phase,pose,str(info.frames[pose].get("body_height",info.body_height))]
	note.add_theme_font_size_override("font_size",14);box.add_child(note)

func run() -> void:
	var args:=OS.get_cmdline_user_args()
	# Wide strike silhouettes need room around the same fixed-scale body.
	# Widen the cells instead of fitting each pose to its bounds.
	var review_size:=Vector2i(1800,1600) if args.has("--catalog") else Vector2i(2500,1750)
	root.content_scale_size=review_size;root.size=review_size
	var selected_character:=int(args[args.find("--character")+1]) if args.has("--character") else -1
	var selected_phase:=str(args[args.find("--phase")+1]) if args.has("--phase") else ""
	var output:=str(args[args.find("--output")+1])
	DirAccess.make_dir_recursive_absolute(output)
	var bg:=ColorRect.new();bg.color=Color("171c22");bg.size=Vector2(review_size);root.add_child(bg)
	if args.has("--catalog"):
		tile_size=Vector2(225,240);zoom=1.1;floor_y=215;center_ratio=0.48
		for character in 6:
			if selected_character>=0 and character!=selected_character:continue
			var fighter:Dictionary=FighterArt.catalog().fighters[character]
			var cells:=[];var seen:={}
			for phase in fighter:
				var sheet:Variant=fighter[phase]
				if not sheet is Dictionary or not sheet.has("frames") or not sheet.has("body_height"):continue
				if str(phase).ends_with("_fx") or phase in ["idle_smoke","movement_smoke"]:continue
				for pose in sheet.frames.size():
					var frame:Dictionary=sheet.frames[pose]
					var key:=str(frame.get("file",sheet.file))+str(frame.region)
					if seen.has(key):continue
					seen[key]=true;cells.append([phase,pose])
			for start in range(0,cells.size(),42):
				page=Control.new();root.add_child(page)
				var heading:=Label.new();heading.position=Vector2(12,8)
				heading.text="%s / ALL UNIQUE BODY CELLS / %d-%d / FIXED WORLD SCALE"%[fighter.name,start,mini(start+42,cells.size())-1]
				heading.add_theme_font_size_override("font_size",23);page.add_child(heading)
				for row in 6:tile(character,reference_phase(character),0,0,row,"IDLE REFERENCE")
				for index in mini(42,cells.size()-start):
					var item:Array=cells[start+index]
					tile(character,str(item[0]),int(item[1]),index%7+1,index/7,"CELL %d"%(start+index))
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output+"/%d-catalog-%03d.png"%[character,start])
				page.queue_free();await process_frame
		print("Animation scale review complete");quit();return
	for character in 6:
		if selected_character>=0 and character!=selected_character:continue
		var fighter:Dictionary=FighterArt.catalog().fighters[character]
		for slot in fighter.get("super_presentations",{}):
			var spec:Dictionary=fighter.super_presentations[slot]
			var phase:=str(spec.phase)
			if not selected_phase.is_empty() and phase!=selected_phase:continue
			var frames:Array=FighterArt.sheet(character,phase).frames
			var rows:=maxi(5,ceili(frames.size()/4.0))
			review_size=Vector2i(2500,48+rows*int(tile_size.y))
			root.content_scale_size=review_size;root.size=review_size;bg.size=Vector2(review_size)
			page=Control.new();root.add_child(page)
			var heading:=Label.new();heading.position=Vector2(12,8)
			heading.text="%s / %s / FIXED WORLD ZOOM / EFFECTS HIDDEN"%[fighter.name,phase]
			heading.add_theme_font_size_override("font_size",24);page.add_child(heading)
			for row in rows:
				tile(character,reference_phase(character),0,0,row,"APPROVED IDLE")
			for index in frames.size():
				tile(character,phase,index,index%4+1,index/4,"KEY %02d"%index)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output+"/"+str(character)+"-"+phase+".png")
			page.queue_free();await process_frame
	print("Animation scale review complete")
	quit()
