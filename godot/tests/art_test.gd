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
		for phase in ["active", "windup", "block"]:
			var sheet := FighterArt.sheet(c, phase)
			var path: String = FighterArt.DIRECTORY + sheet.file
			check(FileAccess.get_sha256(path) == sheet.sha256, "Artwork checksum changed without metadata update: " + path)
			var source := Image.new()
			var image_error := source.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
			check(image_error == OK, "Could not decode source atlas: " + path)
			check(source != null and source.get_size() == Vector2i(1536, 1024), "Unexpected atlas dimensions: " + path)
			if source == null: continue
			# Empty corners and inter-row space catch opaque/partly opaque background failures.
			for point in [Vector2i(0, 0), Vector2i(1535, 0), Vector2i(0, 1023), Vector2i(500, 510)]:
				check(source.get_pixelv(point).a < 0.03, "Atlas background is not transparent: " + path)
			check(sheet.frames.size() == (12 if phase == "active" else 6), "Missing poses: " + path)
			for pose in sheet.frames.size():
				var texture := FighterArt.texture(c, phase, pose)
				var bounds: Array = sheet.frames[pose].bounds
				check(bounds[2] - bounds[0] > 30 and bounds[3] - bounds[1] > 80, "Empty/tiny pose: " + path)
				check(texture.region.position.x >= 0 and texture.region.end.x <= source.get_width(), "Atlas region outside image")
				check(sheet.frames[pose].pivot[1] > 0 and sheet.frames[pose].pivot[1] <= 512, "Invalid foot pivot")
	print("Godot sprite catalog: ", failures, " failures; six fighters, 144 source poses, alpha, regions, provenance")
	quit(1 if failures else 0)
