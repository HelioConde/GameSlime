class_name PlayerController
extends CharacterBody2D

signal feedback_requested(text: String)

@export var move_speed: float = 165.0
@export var acceleration: float = 1050.0
@export var deceleration: float = 1350.0
@export_range(0.25, 1.0, 0.05) var charge_move_multiplier: float = 0.80

@onready var energy: EnergyComponent = $Energy
@onready var tools: ToolController = $ToolController

var facing: Vector2i = Vector2i.DOWN
var farm_field: FarmField

func _ready() -> void:
	add_to_group("player")
	call_deferred("_find_world_systems")
	queue_redraw()

func _physics_process(delta: float) -> void:
	if farm_field == null:
		_find_world_systems()

	var input_direction := _read_movement_input()
	if input_direction != Vector2.ZERO:
		_update_facing(input_direction)

	var speed_multiplier := charge_move_multiplier if tools.is_charging else 1.0
	var target_velocity := input_direction.normalized() * move_speed * speed_multiplier
	var rate := acceleration if input_direction != Vector2.ZERO else deceleration
	velocity = velocity.move_toward(target_velocity, rate * delta)

	tools.update_charge(delta)
	move_and_slide()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				tools.begin_charge()
			else:
				_release_tool()
			get_viewport().set_input_as_handled()
			return

		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_interact()
			get_viewport().set_input_as_handled()
			return

	if not (event is InputEventKey) or event.echo:
		return

	if event.pressed:
		match event.physical_keycode:
			KEY_SPACE:
				tools.begin_charge()
			KEY_E:
				_interact()
			KEY_1:
				tools.select_tool(ToolController.ToolType.HOE)
			KEY_2:
				tools.select_tool(ToolController.ToolType.WATERING_CAN)
	else:
		if event.physical_keycode == KEY_SPACE:
			_release_tool()

func restore_after_sleep() -> void:
	energy.restore_full()

func get_target_cells() -> Array[Vector2i]:
	if farm_field == null:
		return []

	var origin := farm_field.world_to_cell(global_position)
	var stage := tools.charge_stage if tools.is_charging else 0
	var raw_cells := GridTargeting.get_tool_cells(origin, facing, stage)
	return farm_field.filter_valid_cells(raw_cells)

func _release_tool() -> void:
	if not tools.is_charging:
		return

	var result := tools.release_charge()
	if result.is_empty() or farm_field == null:
		return

	var tool := int(result["tool"])
	var stage := int(result["stage"])
	var origin := farm_field.world_to_cell(global_position)
	var cells := farm_field.filter_valid_cells(
		GridTargeting.get_tool_cells(origin, facing, stage)
	)

	if cells.is_empty():
		feedback_requested.emit("Nenhum tile valido.")
		return

	var energy_cost := tools.get_energy_cost(stage)
	if not energy.can_spend(energy_cost):
		feedback_requested.emit("Energia insuficiente.")
		return

	var affected := 0
	match tool:
		ToolController.ToolType.HOE:
			affected = farm_field.apply_hoe(cells)
		ToolController.ToolType.WATERING_CAN:
			affected = farm_field.apply_water(cells)

	if affected <= 0:
		feedback_requested.emit("Nada para fazer aqui.")
		return

	energy.spend(energy_cost)

func _interact() -> void:
	for node in get_tree().get_nodes_in_group("sleep_spot"):
		var sleep_spot := node as SleepSpot
		if sleep_spot != null and sleep_spot.can_interact(global_position):
			var sleep_message := sleep_spot.interact(self)
			if not sleep_message.is_empty():
				feedback_requested.emit(sleep_message)
				return

	if farm_field == null:
		return

	var origin := farm_field.world_to_cell(global_position)
	var target_cells := GridTargeting.get_tool_cells(origin, facing, 0)
	if target_cells.is_empty():
		return

	var message := farm_field.interact_cell(target_cells[0])
	if not message.is_empty():
		feedback_requested.emit(message)

func _read_movement_input() -> Vector2:
	var direction := Vector2.ZERO

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0

	return direction

func _update_facing(direction: Vector2) -> void:
	if absf(direction.x) > absf(direction.y):
		facing = Vector2i.RIGHT if direction.x > 0.0 else Vector2i.LEFT
	elif not is_zero_approx(direction.y):
		facing = Vector2i.DOWN if direction.y > 0.0 else Vector2i.UP

func _find_world_systems() -> void:
	farm_field = get_tree().get_first_node_in_group("farm_field") as FarmField

func _draw() -> void:
	_draw_player()
	_draw_tool_preview()

func _draw_player() -> void:
	draw_circle(Vector2(0, -13), 8.0, Color(0.94, 0.78, 0.59))
	draw_rect(Rect2(-8, -5, 16, 22), Color(0.34, 0.58, 0.92), true)
	draw_rect(Rect2(-8, 9, 6, 12), Color(0.20, 0.24, 0.35), true)
	draw_rect(Rect2(2, 9, 6, 12), Color(0.20, 0.24, 0.35), true)

	var facing_line := Vector2(facing) * 18.0
	draw_line(Vector2.ZERO, facing_line, Color(1.0, 0.93, 0.47), 2.0)

func _draw_tool_preview() -> void:
	if farm_field == null:
		return

	var preview_color := Color(0.75, 0.48, 0.22, 0.30)
	if tools.selected_tool == ToolController.ToolType.WATERING_CAN:
		preview_color = Color(0.29, 0.69, 1.0, 0.30)

	for cell in get_target_cells():
		var center_global := farm_field.cell_to_world(cell)
		var center_local := to_local(center_global)
		var size := Vector2(farm_field.cell_size, farm_field.cell_size)
		var rect := Rect2(center_local - size * 0.5, size)
		draw_rect(rect, preview_color, true)
		draw_rect(rect, preview_color.lightened(0.35), false, 2.0)
