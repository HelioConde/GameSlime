class_name BaseCore
extends Node2D

signal slime_registered(slime: SlimeWorker)
signal slime_unregistered(slime: SlimeWorker)
signal level_changed(new_level: int)

@export var base_radius: float = 280.0
@export var base_level: int = 1
@export var base_id: StringName = &"home_base"
@export var starting_slime_capacity: int = 3

var registered_slimes: Array[SlimeWorker] = []
var registered_structures: Array[Node2D] = []

@onready var storage_network: StorageNetwork = $StorageNetwork

func _ready() -> void:
	add_to_group("base_core")
	queue_redraw()

func get_slime_capacity() -> int:
	return starting_slime_capacity + max(base_level - 1, 0)

func can_register_slime() -> bool:
	return registered_slimes.size() < get_slime_capacity()

func register_slime(slime: SlimeWorker) -> bool:
	if slime in registered_slimes:
		return true
	if not can_register_slime():
		return false

	registered_slimes.append(slime)
	slime.base_core = self
	slime_registered.emit(slime)
	return true

func unregister_slime(slime: SlimeWorker) -> void:
	if not registered_slimes.erase(slime):
		return
	if slime.base_core == self:
		slime.base_core = null
	slime_unregistered.emit(slime)

func is_position_inside(world_position: Vector2) -> bool:
	return global_position.distance_to(world_position) <= base_radius

func set_base_level(value: int) -> void:
	var new_level := max(value, 1)
	if new_level == base_level:
		return
	base_level = new_level
	level_changed.emit(base_level)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, base_radius, Color(0.16, 0.42, 0.27, 0.12))
	draw_arc(Vector2.ZERO, base_radius, 0.0, TAU, 96, Color(0.37, 0.86, 0.52, 0.55), 2.0)
	draw_circle(Vector2.ZERO, 24.0, Color(0.22, 0.72, 0.43, 0.9))
	draw_circle(Vector2.ZERO, 11.0, Color(0.67, 1.0, 0.77, 0.95))
