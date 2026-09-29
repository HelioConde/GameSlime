extends Node2D

func _ready() -> void:
	TaskManager.task_created.connect(_on_task_changed)
	TaskManager.task_claimed.connect(_on_task_claimed)
	TaskManager.task_completed.connect(_on_task_completed)

	TaskManager.create_task(GameEnums.TaskType.CHOP, Vector2(760, 330), 1)
	TaskManager.create_task(GameEnums.TaskType.MINE, Vector2(520, 430), 1)
	TaskManager.create_task(GameEnums.TaskType.HARVEST, Vector2(650, 500), 2)
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _on_task_changed(_task: TaskData) -> void:
	queue_redraw()

func _on_task_claimed(_task: TaskData, _slime: Node2D) -> void:
	queue_redraw()

func _on_task_completed(_task: TaskData, _slime: Node2D) -> void:
	queue_redraw()

func _draw() -> void:
	for x in range(0, 1281, 32):
		draw_line(Vector2(x, 0), Vector2(x, 720), Color(0.13, 0.19, 0.15, 0.4), 1.0)
	for y in range(0, 721, 32):
		draw_line(Vector2(0, y), Vector2(1280, y), Color(0.13, 0.19, 0.15, 0.4), 1.0)

	for task_variant in TaskManager.get_tasks():
		var task := task_variant as TaskData
		if task == null:
			continue
		if task.state in [GameEnums.TaskState.COMPLETED, GameEnums.TaskState.CANCELED]:
			continue

		var color := Color(0.95, 0.77, 0.25, 0.95)
		if task.state == GameEnums.TaskState.CLAIMED:
			color = Color(0.42, 0.78, 1.0, 0.95)
		elif task.state == GameEnums.TaskState.RUNNING:
			color = Color(0.42, 1.0, 0.63, 0.95)

		draw_circle(task.position, 8.0, color)
		draw_arc(task.position, 12.0, 0.0, TAU, 20, Color(color, 0.45), 2.0)
