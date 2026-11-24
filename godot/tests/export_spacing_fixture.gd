extends SceneTree

# Export through the real import/migration path, so the native audit uses the
# current Workshop batch rather than approximating it from starter tables.
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("Pass the output configuration path")
		quit(1)
		return
	var batch: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/workshop/current.json"))
	var model := CombatModel.new()
	var error := model.load_file("res://data/workshop/" + str(batch.file))
	if not error.is_empty():
		printerr(error)
		quit(1)
		return
	var file := FileAccess.open(args[0], FileAccess.WRITE)
	if file == null:
		printerr("Cannot open audit configuration output")
		quit(1)
		return
	file.store_buffer(model.core.configuration().to_byte_array())
	print("Exported current Workshop configuration: ", batch.file)
	quit()
