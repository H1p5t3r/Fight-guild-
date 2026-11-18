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
			var signatures: int = 32 if c == 3 else 20 if c == 2 else 4
			var count: int = {"active": 12, "windup": 6, "block": 6, "signature_windup": signatures, "signature_active": signatures, "ready": 1, "walk": 8, "run": 8, "stance": 4}[phase]
			check(sheet.frames.size() == count, "Missing poses: " + path)
			for pose in sheet.frames.size():
				if sheet.frames[pose].has("file"):
					var alternate: String = FighterArt.DIRECTORY + sheet.frames[pose].file
					check(FileAccess.get_sha256(alternate) == sheet.frames[pose].sha256, "Swing frame checksum is stale: " + alternate)
					var alternate_image := Image.new()
					check(alternate_image.load_png_from_buffer(FileAccess.get_file_as_bytes(alternate)) == OK, "Cannot decode swing frame")
					check(alternate_image.get_size() == source.get_size() and alternate_image.get_pixel(0, 0).a < 0.03, "Invalid swing atlas dimensions/alpha")
				var texture := FighterArt.texture(c, phase, pose)
				var bounds: Array = sheet.frames[pose].bounds
				check(bounds[2] - bounds[0] > 30 and bounds[3] - bounds[1] > 80, "Empty/tiny pose: " + path)
				check(texture.region.position.x >= 0 and texture.region.end.x <= source.get_width(), "Atlas region outside image")
				check(texture.region.position.y >= 0 and texture.region.end.y <= source.get_height(), "Atlas row outside image")
				check(bounds[0] >= 0 and bounds[1] >= 0 and bounds[2] <= texture.get_width() and bounds[3] <= texture.get_height(), "Pose bounds outside frame")
				check(texture.get_size() == Vector2(sheet.frames[pose].region[2], sheet.frames[pose].region[3]), "Atlas trim changed logical sprite size")
				check(sheet.frames[pose].pivot[1] > 0 and sheet.frames[pose].pivot[1] <= source.get_height(), "Invalid foot pivot")
	print("Godot sprite catalog: ", failures, " failures; six fighters, 319 source poses, alpha, regions, provenance")
	quit(1 if failures else 0)
