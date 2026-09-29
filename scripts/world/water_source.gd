class_name WaterSource
extends Node2D

@export var interaction_radius: float = 72.0

func _ready() -> void:
	add_to_group("water_source")
	queue_redraw()

func can_interact(player_position: Vector2) -> bool:
	return global_position.distance_to(player_position) <= interaction_radius

func interact(player: PlayerController) -> String:
	if player == null or not can_interact(player.global_position):
		return ""

	player.refill_watering_can()
	return "Regador cheio."

func _draw() -> void:
	draw_circle(Vector2.ZERO, 34.0, Color(0.16, 0.49, 0.73, 0.95))
	draw_circle(Vector2.ZERO, 29.0, Color(0.23, 0.67, 0.93, 0.95))
	draw_arc(Vector2.ZERO, 35.0, 0.0, TAU, 32, Color(0.10, 0.25, 0.34), 3.0)
	draw_arc(Vector2.ZERO, 20.0, 0.2, 2.9, 18, Color(0.68, 0.91, 1.0, 0.55), 2.0)
