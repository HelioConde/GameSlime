class_name SlimeWorker
extends CharacterBody2D

signal command_changed(worker: SlimeWorker, mode: int)
signal task_changed(worker: SlimeWorker, task: TaskData)
signal energy_changed(worker: SlimeWorker, energy: float)

@export var move_speed: float = 92.0
@export var follow_distance: float = 44.0
@export var work_duration: float = 1.2
@export var task_search_interval: float = 0.45
@export var max_energy: float = 100.0
@export var work_energy_per_second: float = 2.0
@export var rest_energy_per_second: float = 12.0

var energy: float = 100.0
var command_mode: int = GameEnums.SlimeCommandMode.AUTO
var base_core: BaseCore
var current_task: TaskData
var follow_target: Node2D
var command_target_position: Vector2
var assigned_zone_center: Vector2
var assigned_zone_radius: float = 0.0
var selected: bool = false

var _task_search_cooldown: float = 0.0
var _work_elapsed: float = 0.0

func _ready() -> void:
	add_to_group("slime_worker")
	energy = max_energy
	call_deferred("_register_with_nearest_base")
	queue_redraw()

func _physics_process(delta: float) -> void:
	match command_mode:
		GameEnums.SlimeCommandMode.AUTO:
			_tick_auto(delta)
		GameEnums.SlimeCommandMode.FOLLOW:
			_tick_follow()
		GameEnums.SlimeCommandMode.WAIT:
			_stop()
		GameEnums.SlimeCommandMode.MOVE_TO:
			_tick_move_to()
		GameEnums.SlimeCommandMode.FORCE_TASK:
			_tick_task(delta)
		GameEnums.SlimeCommandMode.ASSIGNED_ZONE:
			_tick_auto(delta, true)
		GameEnums.SlimeCommandMode.REST:
			_tick_rest(delta)

func set_command(mode: int) -> void:
	if command_mode == mode:
		return

	if current_task != null and mode not in [
		GameEnums.SlimeCommandMode.AUTO,
		GameEnums.SlimeCommandMode.FORCE_TASK,
		GameEnums.SlimeCommandMode.ASSIGNED_ZONE,
	]:
		TaskManager.release_task(current_task, self)
		_set_current_task(null)

	command_mode = mode
	command_changed.emit(self, command_mode)
	queue_redraw()

func assign_forced_task(task: TaskData) -> bool:
	if current_task != null:
		TaskManager.release_task(current_task, self)
		_set_current_task(null)

	if not TaskManager.claim_task(task, self):
		return false

	_set_current_task(task)
	command_mode = GameEnums.SlimeCommandMode.FORCE_TASK
	command_changed.emit(self, command_mode)
	return true

func set_selected(value: bool) -> void:
	selected = value
	queue_redraw()

func _tick_auto(delta: float, restrict_to_zone: bool = false) -> void:
	if base_core == null:
		_register_with_nearest_base()
		_stop()
		return

	if not base_core.is_position_inside(global_position):
		_move_towards(base_core.global_position)
		return

	if current_task != null:
		if restrict_to_zone and assigned_zone_radius > 0.0:
			if assigned_zone_center.distance_to(current_task.position) > assigned_zone_radius:
				TaskManager.release_task(current_task, self)
				_set_current_task(null)
				return
		_tick_task(delta)
		return

	_task_search_cooldown -= delta
	if _task_search_cooldown > 0.0:
		_stop()
		return

	_task_search_cooldown = task_search_interval
	var candidate: TaskData = TaskManager.find_best_task_for(self, base_core.base_radius * 2.0)
	if candidate == null:
		_stop()
		return

	if restrict_to_zone and assigned_zone_radius > 0.0:
		if assigned_zone_center.distance_to(candidate.position) > assigned_zone_radius:
			_stop()
			return

	if TaskManager.claim_task(candidate, self):
		_set_current_task(candidate)

func _tick_follow() -> void:
	if follow_target == null or not is_instance_valid(follow_target):
		set_command(GameEnums.SlimeCommandMode.AUTO)
		return

	if global_position.distance_to(follow_target.global_position) <= follow_distance:
		_stop()
		return

	_move_towards(follow_target.global_position)

func _tick_move_to() -> void:
	if global_position.distance_to(command_target_position) <= 5.0:
		_stop()
		set_command(GameEnums.SlimeCommandMode.AUTO)
		return
	_move_towards(command_target_position)

func _tick_task(delta: float) -> void:
	if current_task == null:
		if command_mode == GameEnums.SlimeCommandMode.FORCE_TASK:
			set_command(GameEnums.SlimeCommandMode.AUTO)
		return

	if current_task.state == GameEnums.TaskState.COMPLETED:
		_set_current_task(null)
		if command_mode == GameEnums.SlimeCommandMode.FORCE_TASK:
			set_command(GameEnums.SlimeCommandMode.AUTO)
		return

	if global_position.distance_to(current_task.position) > 8.0:
		_work_elapsed = 0.0
		_move_towards(current_task.position)
		return

	_stop()
	if current_task.state != GameEnums.TaskState.RUNNING:
		TaskManager.start_task(current_task, self)

	_work_elapsed += delta
	_set_energy(energy - work_energy_per_second * delta)

	if _work_elapsed >= work_duration:
		var finished := current_task
		TaskManager.complete_task(finished, self)
		_set_current_task(null)
		_work_elapsed = 0.0
		if command_mode == GameEnums.SlimeCommandMode.FORCE_TASK:
			set_command(GameEnums.SlimeCommandMode.AUTO)

func _tick_rest(delta: float) -> void:
	_stop()
	_set_energy(energy + rest_energy_per_second * delta)
	if energy >= max_energy:
		set_command(GameEnums.SlimeCommandMode.AUTO)

func _move_towards(point: Vector2) -> void:
	var direction := global_position.direction_to(point)
	velocity = direction * move_speed
	move_and_slide()

func _stop() -> void:
	velocity = Vector2.ZERO
	move_and_slide()

func _set_current_task(task: TaskData) -> void:
	current_task = task
	task_changed.emit(self, current_task)
	queue_redraw()

func _set_energy(value: float) -> void:
	var next_energy := clampf(value, 0.0, max_energy)
	if is_equal_approx(next_energy, energy):
		return
	energy = next_energy
	energy_changed.emit(self, energy)
	queue_redraw()
	if energy <= 0.0 and command_mode != GameEnums.SlimeCommandMode.REST:
		set_command(GameEnums.SlimeCommandMode.REST)

func _register_with_nearest_base() -> void:
	if base_core != null:
		return

	var best_base: BaseCore = null
	var best_distance := INF

	for node in get_tree().get_nodes_in_group("base_core"):
		var candidate := node as BaseCore
		if candidate == null:
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			best_base = candidate

	if best_base != null:
		best_base.register_slime(self)

func _draw() -> void:
	var body_color := Color(0.32, 0.92, 0.56, 0.96)
	if command_mode == GameEnums.SlimeCommandMode.REST:
		body_color = Color(0.36, 0.64, 0.86, 0.96)

	draw_circle(Vector2.ZERO, 15.0, body_color)
	draw_circle(Vector2(-5.0, -3.0), 2.2, Color(0.05, 0.08, 0.06))
	draw_circle(Vector2(5.0, -3.0), 2.2, Color(0.05, 0.08, 0.06))
	draw_line(Vector2(-4.0, 5.0), Vector2(4.0, 5.0), Color(0.05, 0.08, 0.06), 1.5)

	var energy_ratio := energy / max_energy
	draw_rect(Rect2(-16.0, -24.0, 32.0, 4.0), Color(0.08, 0.11, 0.09, 0.9))
	draw_rect(Rect2(-16.0, -24.0, 32.0 * energy_ratio, 4.0), Color(0.98, 0.86, 0.28, 0.95))

	if selected:
		draw_arc(Vector2.ZERO, 21.0, 0.0, TAU, 32, Color(1.0, 0.95, 0.4, 1.0), 2.5)
