class_name PlayerController
extends CharacterBody2D

signal slime_selected(slime: SlimeWorker)

@export var move_speed: float = 180.0
@export var selection_radius: float = 42.0

var selected_slime: SlimeWorker

func _ready() -> void:
	add_to_group("player")
	queue_redraw()

func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0

	velocity = direction.normalized() * move_speed
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_select_slime_at(get_global_mouse_position())
			get_viewport().set_input_as_handled()
		return

	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	match event.physical_keycode:
		KEY_ESCAPE:
			_set_selected_slime(null)
		KEY_G:
			SlimeCommandSystem.set_auto(selected_slime)
		KEY_F:
			SlimeCommandSystem.follow(selected_slime, self)
		KEY_H:
			SlimeCommandSystem.wait(selected_slime)
		KEY_R:
			SlimeCommandSystem.rest(selected_slime)
		KEY_M:
			SlimeCommandSystem.move_to(selected_slime, get_global_mouse_position())
		KEY_T:
			_force_best_task()
		KEY_1:
			_create_task(GameEnums.TaskType.CHOP)
		KEY_2:
			_create_task(GameEnums.TaskType.MINE)
		KEY_3:
			_create_task(GameEnums.TaskType.HARVEST)
		KEY_4:
			_create_task(GameEnums.TaskType.PLANT)
		KEY_5:
			_create_task(GameEnums.TaskType.HAUL)
		KEY_6:
			_create_task(GameEnums.TaskType.BUILD)

func _select_slime_at(world_position: Vector2) -> void:
	var best: SlimeWorker = null
	var best_distance := selection_radius

	for node in get_tree().get_nodes_in_group("slime_worker"):
		var slime := node as SlimeWorker
		if slime == null:
			continue
		var distance := slime.global_position.distance_to(world_position)
		if distance <= best_distance:
			best = slime
			best_distance = distance

	_set_selected_slime(best)

func _set_selected_slime(slime: SlimeWorker) -> void:
	if selected_slime != null:
		selected_slime.set_selected(false)

	selected_slime = slime

	if selected_slime != null:
		selected_slime.set_selected(true)

	slime_selected.emit(selected_slime)

func _force_best_task() -> void:
	if selected_slime == null:
		return
	var task: TaskData = TaskManager.find_best_task_for(selected_slime)
	if task != null:
		SlimeCommandSystem.force_task(selected_slime, task)

func _create_task(task_type: int) -> void:
	TaskManager.create_task(task_type, get_global_mouse_position(), 1)

func _draw() -> void:
	draw_rect(Rect2(-9.0, -12.0, 18.0, 24.0), Color(0.38, 0.68, 1.0, 0.95))
	draw_circle(Vector2(0.0, -16.0), 7.0, Color(0.95, 0.81, 0.65, 1.0))
