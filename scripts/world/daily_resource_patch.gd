class_name DailyResourcePatch
extends Node2D

@export var resource_scene: PackedScene
@export var resource_name_prefix: String = "Resource"
@export var local_spawn_positions: Array[Vector2] = []

func _ready() -> void:
	GameClock.day_started.connect(_on_day_started)
	call_deferred("_ensure_resources")

func _on_day_started(_day: int) -> void:
	call_deferred("_ensure_resources")

func _ensure_resources() -> void:
	if resource_scene == null:
		return

	for index in range(local_spawn_positions.size()):
		var child_name := "%s%02d" % [resource_name_prefix, index + 1]
		if get_parent().has_node(NodePath(child_name)):
			continue

		var resource := resource_scene.instantiate() as Node2D
		if resource == null:
			continue

		resource.name = child_name
		resource.position = position + local_spawn_positions[index]
		get_parent().add_child(resource)
