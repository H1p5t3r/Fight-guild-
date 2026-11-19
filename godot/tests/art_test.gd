extends SceneTree

var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr(message)

func _initialize() -> void:
	var fighters: Array = FighterArt.catalog().fighters
	check(fighters.size() == CombatModel.CHARACTERS.size(), "Roster artwork is incomplete")
	for c in fighters.size():
		check(fighters[c].name == CombatModel.CHARACTERS[c], "Artwork belongs to a different roster slot")
		if fighters[c].has("projectile"):
			var projectile: Dictionary = fighters[c].projectile
			var projectile_path: String = FighterArt.DIRECTORY + projectile.file
			check(FileAccess.get_sha256(projectile_path) == projectile.sha256, "Projectile art provenance is stale")
			var projectile_image := Image.new()
			check(projectile_image.load_png_from_buffer(FileAccess.get_file_as_bytes(projectile_path)) == OK, "Cannot decode projectile art")
			var r: Array = projectile.region
			check(r[0] >= 0 and r[1] >= 0 and r[0] + r[2] <= projectile_image.get_width() and r[1] + r[3] <= projectile_image.get_height(), "Projectile crop outside source")
		if fighters[c].has("hook_weapon"):
			var weapon: Dictionary = fighters[c].hook_weapon
			var path: String = FighterArt.DIRECTORY + weapon.file
			check(FileAccess.get_sha256(path) == weapon.sha256, "Spear layer provenance is stale")
			var source := Image.new()
			check(source.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK, "Cannot decode spear layer")
			check(source.get_size() == Vector2i(weapon.size[0], weapon.size[1]) and source.get_pixel(0, 0).a == 0.0, "Invalid spear dimensions/alpha")
		for phase in FighterArt.phase_names(c):
			var sheet := FighterArt.sheet(c, phase)
			var path: String = FighterArt.DIRECTORY + sheet.file
			check(FileAccess.get_sha256(path) == sheet.sha256, "Artwork checksum changed without metadata update: " + path)
			var source := Image.new()
			var image_error := source.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
			check(image_error == OK, "Could not decode source atlas: " + path)
			var dimensions: Array = sheet.get("size", [1536, 1024])
			check(source != null and source.get_size() == Vector2i(dimensions[0], dimensions[1]), "Unexpected atlas dimensions: " + path)
			if source == null: continue
			# Layouts may differ (v2 active sheets are 4x3). Validate declared gutters,
			# not the old six-column sheet's hard-coded inter-row coordinate.
			var samples: Array = sheet.get("transparent_samples", fighters[c].get("transparent_samples", [[0, 0], [1535, 0], [0, 1023], [500, 510]]))
			for sample in samples:
				var point := Vector2i(sample[0], sample[1])
				check(source.get_pixelv(point).a < 0.03, "Atlas background is not transparent: " + path)
			var signatures: int = 32 if c == 3 else 24 if c == 2 else 20 if c == 4 else 4
			var count: int = {"active": 12, "windup": 6, "block": 6, "signature_windup": signatures, "signature_active": signatures, "ready": 1, "walk": 8, "run": 8, "stance": 4, "knockdown": 6, "knockdown_back": 6, "idle": 4, "crouch_idle": 4, "back_walk": 8, "attack_animation": 116 if c == 5 else 26 if c == 4 else 32, "backdash": 6}[phase]
			check(sheet.frames.size() == count, "Missing poses: " + path)
			for pose in sheet.frames.size():
				var frame_size := source.get_size()
				if sheet.frames[pose].has("file"):
					var alternate: String = FighterArt.DIRECTORY + sheet.frames[pose].file
					check(FileAccess.get_sha256(alternate) == sheet.frames[pose].sha256, "Swing frame checksum is stale: " + alternate)
					var alternate_image := Image.new()
					check(alternate_image.load_png_from_buffer(FileAccess.get_file_as_bytes(alternate)) == OK, "Cannot decode swing frame")
					var expected_size: Array = sheet.frames[pose].get("source_size", dimensions)
					frame_size = Vector2i(expected_size[0], expected_size[1])
					check(alternate_image.get_size() == frame_size and alternate_image.get_pixel(0, 0).a < 0.03, "Invalid swing atlas dimensions/alpha")
				var texture := FighterArt.texture(c, phase, pose)
				var bounds: Array = sheet.frames[pose].bounds
				check(bounds[2] - bounds[0] > 30 and bounds[3] - bounds[1] > 80, "Empty/tiny pose: " + path)
				check(texture.region.position.x >= 0 and texture.region.end.x <= frame_size.x, "Atlas region outside image")
				check(texture.region.position.y >= 0 and texture.region.end.y <= frame_size.y, "Atlas row outside image")
				check(bounds[0] >= 0 and bounds[1] >= 0 and bounds[2] <= texture.get_width() and bounds[3] <= texture.get_height(), "Pose bounds outside frame")
				check(texture.get_size() == Vector2(sheet.frames[pose].region[2], sheet.frames[pose].region[3]), "Atlas trim changed logical sprite size")
				check(sheet.frames[pose].pivot[1] > 0 and sheet.frames[pose].pivot[1] <= source.get_height(), "Invalid foot pivot")
	var smoke: Dictionary = fighters[2].idle_smoke
	check(FileAccess.get_sha256(FighterArt.DIRECTORY + smoke.file) == smoke.sha256, "Rear vapor provenance is stale")
	var sprite := Sprite2D.new()
	for phase in ["idle", "crouch_idle"]:
		for facing in [-1, 1]:
			for tick in [0, 15, 40, 79, 80]:
				FighterArt.apply(sprite, 2, phase, (tick / 20) % 4, 1, facing, tick)
				for layer in 2:
					var vapor := sprite.get_node("IdleSmoke%d" % layer) as Sprite2D
					check(vapor.visible and vapor.show_behind_parent, "Vapor must stay behind its fighter")
					check(vapor.texture.atlas != null, "Missing imported vapor texture")
					check(vapor.texture == FighterArt.texture(2, "idle_smoke", (tick / 10 + layer) % 8), "Vapor ignored the saved clock")
	var movement: Dictionary = fighters[2].movement_smoke
	check(FileAccess.get_sha256(FighterArt.DIRECTORY + movement.file) == movement.sha256, "Movement vapor provenance is stale")
	for phase in ["walk", "back_walk", "run"]:
		for facing in [-1, 1]:
			for tick in [0, 15, 40, 79, 80]:
				FighterArt.apply(sprite, 2, phase, 0, 1, facing, tick)
				var interval: int = movement.presentations[phase].get("frame_ticks", movement.frame_ticks)
				for layer in 2:
					var vapor := sprite.get_node("IdleSmoke%d" % layer) as Sprite2D
					check(vapor.visible and vapor.show_behind_parent, "Movement vapor must stay behind its fighter")
					check(vapor.texture == FighterArt.texture(2, "movement_smoke", (tick / interval + layer) % 8), "Movement vapor ignored saved clock/cadence")
					check(signf(sprite.scale.x) == facing, "Retreat changed body facing")
					check(signf(vapor.scale.x) == (-1 if phase == "back_walk" else 1), "Retreat vapor must trail on the opposite side")
	FighterArt.apply(sprite, 2, "signature_active", 0, 1, 1, 10)
	check(not sprite.get_node("IdleSmoke0").visible and not sprite.get_node("IdleSmoke1").visible, "Idle vapor leaked into an attack")
	FighterArt.apply(sprite, 5, "ready", 0, 1, 1, 10)
	check(not sprite.get_node("IdleSmoke0").visible, "Idle vapor leaked into another fighter")
	for phase in ["backdraft_fx", "sword_fx"]:
		for pose in 4:
			check(FighterArt.texture(2, phase, pose).atlas != null, "Missing attack effect")
	for facing in [-1, 1]:
		for pose in [2, 3, 4, 5]:
			FighterArt.apply(sprite, 2, "attack_animation", pose, 1, facing)
			var layer := sprite.get_node("AttackEffect") as Sprite2D
			check(layer.visible and layer.show_behind_parent, "Backdraft must stay behind its owner")
			check(signf(sprite.scale.x) == facing, "Effect owner facing changed")
		FighterArt.apply(sprite, 2, "signature_active", 22, 1, facing)
		check(sprite.get_node("AttackEffect").visible and not sprite.get_node("AttackEffect").show_behind_parent, "Sword must sweep across the front")
		FighterArt.apply(sprite, 2, "idle", 0, 1, facing, 0)
		check(not sprite.get_node("AttackEffect").visible, "Attack effect leaked into idle")
	for age in [0, 6, 12, 18]:
		check(FighterArt.projectile_art(2, 14, 36-age, age) == FighterArt.projectile_art(2, 25, 120-age, age), "Near/far pillars must use identical art at the same age")
	check(FighterArt.projectile_art(2, 21, 20).file == "smoke-v1/projectile.png", "j.D lost its ember")
	var sweep: Dictionary = fighters[5].sweep_fx
	check(FileAccess.get_sha256(FighterArt.DIRECTORY + sweep.file) == sweep.sha256, "Sweep effect provenance is stale")
	for pose in 4:
		check(FighterArt.texture(5, "sweep_fx", pose).atlas != null, "Missing generated knife arc")
	for facing in [-1, 1]:
		var keys: Array = fighters[5].attack_animation.frames
		for index in keys.size():
			var key: Dictionary = keys[index]
			if key.action_id != "2S": continue
			FighterArt.apply(sprite, 5, "attack_animation", index, 1, facing)
			var arc := sprite.get_node("AttackEffect") as Sprite2D
			check(arc.visible == key.has("effect"), "Knife arc leaked outside its authored frames")
			if not key.has("effect"): continue
			check(not arc.show_behind_parent, "Knife arc must sweep across the foreground")
			var box: Array = key.effect.box
			var near := sprite.transform * (arc.transform * Vector2.ZERO)
			var far := sprite.transform * (arc.transform * arc.texture.get_size())
			check(near.is_equal_approx(Vector2(box[0] * facing, -box[3])), "Knife arc origin differs from strike corridor")
			check(far.is_equal_approx(Vector2(box[2] * facing, -box[1])), "Knife arc reach differs from strike corridor")
			if key.action_frame >= 12 and key.action_frame <= 15:
				check(is_equal_approx(arc.modulate.a, 1.0), "Active knife edge must stay visible")
		FighterArt.apply(sprite, 5, "ready", 0, 1, facing)
		check(not sprite.get_node("AttackEffect").visible, "Knife arc leaked into ready stance")
	sprite.free()
	print("Godot sprite catalog: ", failures, " failures; six fighters, 655 body keys, alpha, regions, provenance and idle/movement vapor")
	quit(1 if failures else 0)
