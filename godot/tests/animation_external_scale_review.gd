extends SceneTree

# Review render-only atlases which are deliberately outside FighterArt's main
# collision/pose catalog. Use their actual pivots and world scale, never fit
# individual silhouettes to the page.
const ZOOM:=1.55
const TILE:=Vector2(500,340)
const FLOOR_Y:=312.0
var output:=""
var bg:ColorRect
var page:Control
var count:=0

func _initialize()->void:call_deferred("run")

func draw_tile(character:int,frame:Dictionary,directory:String,index:int,label_text:String,reference:bool=false)->void:
	var box:=Control.new();box.position=Vector2(index%5*TILE.x,index/5*TILE.y+48);box.size=TILE;box.clip_contents=true;page.add_child(box)
	var floor_line:=ColorRect.new();floor_line.color=Color("48535e");floor_line.position=Vector2(0,FLOOR_Y);floor_line.size=Vector2(TILE.x,1);box.add_child(floor_line)
	var label:=Label.new();label.position=Vector2(10,5);label.text=label_text;label.add_theme_font_size_override("font_size",18);box.add_child(label)
	var sprite:=Sprite2D.new();sprite.position=Vector2(200,FLOOR_Y);box.add_child(sprite)
	if reference:
		FighterArt.apply(sprite,character,"ready" if character in [3,5] else "idle",0,ZOOM,1)
		for child in sprite.get_children():
			if child is Sprite2D:child.hide()
	else:
		var atlas:=AtlasTexture.new();atlas.atlas=load(directory+str(frame.file));atlas.region=Rect2(frame.region[0],frame.region[1],frame.region[2],frame.region[3]);atlas.filter_clip=true
		sprite.texture=atlas;sprite.centered=false;sprite.offset=-Vector2(frame.pivot[0],frame.pivot[1]);sprite.scale=Vector2.ONE*(150.0/float(frame.body_height)*ZOOM)
		var note:=Label.new();note.position=Vector2(10,FLOOR_Y+3);note.text="H %s / %s"%[str(frame.body_height),str(frame.get("name",""))];note.add_theme_font_size_override("font_size",14);box.add_child(note)
		count+=1

func capture(character:int,tag:String,directory:String,frames:Array)->void:
	var rows:=maxi(2,ceili(frames.size()/4.0));var size:=Vector2i(2500,48+rows*340)
	root.content_scale_size=size;root.size=size;bg.size=Vector2(size)
	page=Control.new();root.add_child(page)
	var heading:=Label.new();heading.position=Vector2(12,8);heading.text="%s / %s / FIXED WORLD SCALE"%[FighterArt.catalog().fighters[character].name,tag];heading.add_theme_font_size_override("font_size",24);page.add_child(heading)
	for row in rows:draw_tile(character,{},"",row*5,"APPROVED IDLE",true)
	for index in frames.size():draw_tile(character,frames[index],directory,index/4*5+index%4+1,str(frames[index].label))
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/%d-%s.png"%[character,tag])
	page.queue_free();await process_frame

func run()->void:
	var args:=OS.get_cmdline_user_args();output=str(args[args.find("--output")+1]);DirAccess.make_dir_recursive_absolute(output)
	var selected:=int(args[args.find("--character")+1]) if args.has("--character") else -1
	bg=ColorRect.new();bg.color=Color("171c22");root.add_child(bg)
	for character in 6:
		if selected>=0 and selected!=character:continue
		var reactions:Array=[]
		for family in ["legs","chest","head","air"]:
			for key in 3:
				var frame:=CombatReactions.frame_for(character,family,[0,2,5][key]);frame.label="%s / KEY %d"%[family,key];reactions.append(frame)
		await capture(character,"reactions",CombatReactions.DIRECTORY,reactions)
		var grabs:Array=[]
		for key in 6:
			var frame:=CombatGrabs.frame_for(character,key);frame.label="GRAB / KEY %d"%key;grabs.append(frame)
		await capture(character,"grabs",CombatGrabs.DIRECTORY,grabs)
	var movement:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/fighters/movement-v1/manifest.json"))
	for name in movement.sheets:
		var character:=5 if str(name).begins_with("fillet") else 1 if str(name).begins_with("hammer") else 3
		if selected>=0 and selected!=character:continue
		var clip:Dictionary=movement.sheets[name];var frames:Array=[]
		for index in clip.frames.size():
			var frame:Dictionary=clip.frames[index].duplicate();frame.file=frame.get("file",clip.file);frame.body_height=frame.get("body_height",clip.body_height);frame.label="%s / KEY %d"%[name,index];frames.append(frame)
		await capture(character,str(name),"res://assets/fighters/movement-v1/",frames)
	print("Animation scale review complete / %d external body drawings"%count);quit()
