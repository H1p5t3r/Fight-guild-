extends SceneTree

var model := CombatModel.new()
var connection := NativePeer.new()
var elapsed := 0.0
var succeeded := false
var grace := 0.0
var started := false

func _initialize() -> void:
	call_deferred("start")

func start() -> void:
	root.add_child(connection)
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		quit(1)
		return
	var result := connection.begin(model, args[0] == "host", "127.0.0.1", int(args[1]), 0 if args[0] == "host" else 1, false)
	if result != OK:
		printerr("Cannot start network test: ", error_string(result))
		quit(1)
		return
	started = true

func _physics_process(delta: float) -> bool:
	if not started: return false
	elapsed += delta
	if connection.active:
		connection.tick(RollbackSession.scripted_input(model.frame(), connection.player))
	if connection.verified_through >= 180 and not succeeded:
		succeeded = true
		print("PASS native ENet peer ", connection.player, " verified frame ", connection.verified_through, " / rollbacks ", connection.session.rollbacks)
	if succeeded:
		grace += delta
		if grace > 1.0:
			connection.close()
			quit(0)
	elif elapsed > 20.0 or not connection.error.is_empty():
		printerr("Native ENet peer failed: ", connection.error, " at frame ", model.frame())
		connection.close()
		quit(1)
	return false
