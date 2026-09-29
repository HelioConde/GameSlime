class_name RegrowingResourcePatch
extends Node2D

@export var resource_scene: PackedScene
@export var resource_name_prefix: String = "WildResource"
@export var local_spawn_positions: Array[Vector2] = []
@export_range(1, 12, 1) var max_active_resources: int = 2
@export_range(1, 28, 1) var respawn_interval_days: int = 7
@export var seed_salt: int = 0

var _active_cycle: int = -1

func _ready() -> void:
	add_to_group("regrowing_resource_patch")
	if not GameClock.day_started.is_connected(_on_day_started):
		GameClock.day_started.connect(_on_day_started)

	if not SaveManager.has_save():
		call_deferred("refresh_for_day", GameClock.day, true)

func _on_day_started(day: int) -> void:
	var cycle := get_cycle_for_day(day)
	if cycle == _active_cycle:
		return
	refresh_for_day(day, true)

func get_cycle_for_day(day: int) -> int:
	var safe_day := maxi(day, 1)
	return int(floor(float(safe_day - 1) / float(maxi(respawn_interval_days, 1))))

func get_expected_names_for_day(day: int) -> Array[String]:
	var names: Array[String] = []
	for index in _get_selected_indices(day):
		names.append(_resource_name_for_index(index))
	names.sort()
	return names

func prepare_for_save_load() -> void:
	refresh_for_day(GameClock.day, true)

func refresh_for_day(day: int, replace_cycle: bool = true) -> void:
	if resource_scene == null or get_parent() == null or local_spawn_positions.is_empty():
		return

	var cycle := get_cycle_for_day(day)
	var selected_indices := _get_selected_indices(day)
	var expected_lookup: Dictionary = {}
	for index in selected_indices:
		expected_lookup[_resource_name_for_index(index)] = true

	if replace_cycle:
		for child in get_parent().get_children():
			var child_name := String(child.name)
			if not child_name.begins_with(resource_name_prefix):
				continue
			if expected_lookup.has(child_name):
				continue
			get_parent().remove_child(child)
			child.queue_free()

	for index in selected_indices:
		var child_name := _resource_name_for_index(index)
		if get_parent().has_node(NodePath(child_name)):
			continue

		var resource := resource_scene.instantiate() as Node2D
		if resource == null:
			continue

		resource.name = child_name
		resource.position = position + local_spawn_positions[index]
		get_parent().add_child(resource)

	_active_cycle = cycle

func _get_selected_indices(day: int) -> Array[int]:
	var candidates: Array[int] = []
	for index in range(local_spawn_positions.size()):
		candidates.append(index)

	var rng := RandomNumberGenerator.new()
	var cycle := get_cycle_for_day(day)
	rng.seed = int(
		104729
		+ seed_salt * 13007
		+ cycle * 7919
		+ String(resource_name_prefix).hash()
	)

	for index in range(candidates.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temp := candidates[index]
		candidates[index] = candidates[swap_index]
		candidates[swap_index] = temp

	var selected_count := mini(max_active_resources, candidates.size())
	var selected: Array[int] = []
	for index in range(selected_count):
		selected.append(candidates[index])
	selected.sort()
	return selected

func _resource_name_for_index(index: int) -> String:
	return "%s%02d" % [resource_name_prefix, index + 1]
