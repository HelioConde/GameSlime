extends Node

signal task_created(task: TaskData)
signal task_claimed(task: TaskData, slime: Node2D)
signal task_started(task: TaskData, slime: Node2D)
signal task_completed(task: TaskData, slime: Node2D)
signal task_released(task: TaskData)

var _tasks: Array[TaskData] = []

func create_task(
	task_type: int,
	position: Vector2,
	priority: int = 0,
	target: Node2D = null
) -> TaskData:
	var task := TaskData.new(task_type, position, priority, target)
	_tasks.append(task)
	task_created.emit(task)
	return task

func get_tasks() -> Array:
	return _tasks.duplicate()

func find_best_task_for(slime: Node2D, max_distance: float = 100000.0) -> TaskData:
	var best_task: TaskData = null
	var best_score := -INF

	for task in _tasks:
		if not task.is_available():
			continue

		var distance := slime.global_position.distance_to(task.position)
		if distance > max_distance:
			continue

		var score := float(task.priority) * 1000.0 - distance
		if score > best_score:
			best_score = score
			best_task = task

	return best_task

func claim_task(task: TaskData, slime: Node2D) -> bool:
	if task == null or not task.is_available():
		return false

	task.state = GameEnums.TaskState.CLAIMED
	task.assigned_slime = slime
	task_claimed.emit(task, slime)
	return true

func start_task(task: TaskData, slime: Node2D) -> void:
	if task == null or task.assigned_slime != slime:
		return
	task.state = GameEnums.TaskState.RUNNING
	task_started.emit(task, slime)

func complete_task(task: TaskData, slime: Node2D) -> void:
	if task == null or task.assigned_slime != slime:
		return
	task.state = GameEnums.TaskState.COMPLETED
	task_completed.emit(task, slime)

func release_task(task: TaskData, slime: Node2D = null) -> void:
	if task == null:
		return
	if slime != null and task.assigned_slime != slime:
		return
	if task.state == GameEnums.TaskState.COMPLETED:
		return

	task.state = GameEnums.TaskState.PENDING
	task.assigned_slime = null
	task_released.emit(task)

func cleanup_finished() -> void:
	_tasks = _tasks.filter(func(task: TaskData) -> bool:
		return task.state != GameEnums.TaskState.COMPLETED and task.state != GameEnums.TaskState.CANCELED
	)
