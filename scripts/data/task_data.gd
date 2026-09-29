class_name TaskData
extends RefCounted

var id: StringName
var type: int
var position: Vector2
var priority: int
var state: int = GameEnums.TaskState.PENDING
var target: Node2D
var assigned_slime: Node2D
var created_at_msec: int

func _init(
	task_type: int,
	task_position: Vector2,
	task_priority: int = 0,
	task_target: Node2D = null
) -> void:
	id = StringName("%s_%s" % [Time.get_ticks_msec(), randi()])
	type = task_type
	position = task_position
	priority = task_priority
	target = task_target
	created_at_msec = Time.get_ticks_msec()

func is_available() -> bool:
	return state == GameEnums.TaskState.PENDING and assigned_slime == null
