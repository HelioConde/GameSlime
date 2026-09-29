class_name WaterSource
extends Node2D

const WATER_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprout_lands/tiles/water_1.png"),
	preload("res://assets/sprout_lands/tiles/water_2.png"),
	preload("res://assets/sprout_lands/tiles/water_3.png"),
	preload("res://assets/sprout_lands/tiles/water_4.png"),
]

@export var interaction_radius: float = 72.0
@export var animation_fps: float = 5.0

@onready var visual: Sprite2D = $Visual

var _animation_time: float = 0.0

func _ready() -> void:
	add_to_group("water_source")
	_update_frame()

func _process(delta: float) -> void:
	_animation_time += delta
	_update_frame()

func can_interact(player_position: Vector2) -> bool:
	return global_position.distance_to(player_position) <= interaction_radius

func interact(player: PlayerController) -> String:
	if player == null or not can_interact(player.global_position):
		return ""

	player.refill_watering_can()
	Sfx.play_cue(&"water")
	return "Regador cheio."

func _update_frame() -> void:
	if visual == null or WATER_FRAMES.is_empty():
		return

	var frame_index := int(floor(_animation_time * animation_fps)) % WATER_FRAMES.size()
	visual.texture = WATER_FRAMES[frame_index]
