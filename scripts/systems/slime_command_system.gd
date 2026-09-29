class_name SlimeCommandSystem
extends RefCounted

static func set_auto(worker: SlimeWorker) -> void:
	if worker != null:
		worker.set_command(GameEnums.SlimeCommandMode.AUTO)

static func follow(worker: SlimeWorker, target: Node2D) -> void:
	if worker == null:
		return
	worker.follow_target = target
	worker.set_command(GameEnums.SlimeCommandMode.FOLLOW)

static func wait(worker: SlimeWorker) -> void:
	if worker != null:
		worker.set_command(GameEnums.SlimeCommandMode.WAIT)

static func move_to(worker: SlimeWorker, position: Vector2) -> void:
	if worker == null:
		return
	worker.command_target_position = position
	worker.set_command(GameEnums.SlimeCommandMode.MOVE_TO)

static func rest(worker: SlimeWorker) -> void:
	if worker != null:
		worker.set_command(GameEnums.SlimeCommandMode.REST)

static func force_task(worker: SlimeWorker, task: TaskData) -> bool:
	if worker == null or task == null:
		return false
	return worker.assign_forced_task(task)
