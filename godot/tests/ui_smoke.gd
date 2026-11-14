extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var verification = load("res://scripts/build_verification.gd").new()
	await verification.run(self)
