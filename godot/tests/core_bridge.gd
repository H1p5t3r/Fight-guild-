extends SceneTree

func _initialize() -> void:
	var failures := 0
	var core := FightCore.new()
	var independent := FightCore.new()
	var initial_hash: int = independent.checksum()
	core.step(16, 0)
	if independent.checksum() != initial_hash or core.read_value(0, 4) != 0:
		failures += 1
	var saved: PackedByteArray = core.snapshot()
	core.step(0, 2)
	var expected: int = core.checksum()
	if not core.restore(saved):
		failures += 1
	core.step(0, 2)
	if core.checksum() != expected or core.restore(PackedByteArray([1, 2])):
		failures += 1
	var config: PackedInt32Array = core.configuration()
	config[8] = 177
	if not core.configure(config) or independent.configuration()[8] == 177:
		failures += 1
	config[-1] = 0
	if core.configure(config) or core.configuration()[8] != 177:
		failures += 1
	var path := OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ""
	if not FileAccess.file_exists(path):
		printerr("Native trace is missing: run scripts/test-godot.sh")
		quit(1)
		return
	core.restore_defaults()
	core.reset(0, 1, false, false)
	var trace := FileAccess.open(path, FileAccess.READ)
	var frames := 0
	while not trace.eof_reached():
		var line := trace.get_line().strip_edges()
		if line.is_empty():
			continue
		var values := line.split(" ")
		core.step(int(values[0]), int(values[1]))
		if core.checksum() != int(values[2]):
			printerr("Native/Godot divergence at frame ", frames)
			failures += 1
			break
		frames += 1
	if frames != 1200:
		failures += 1
	print("Godot native bridge: ", frames, " parity frames; ", failures, " failures")
	quit(1 if failures else 0)
