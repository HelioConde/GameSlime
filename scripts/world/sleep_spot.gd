class_name SleepSpot
extends Node2D

@export var interaction_radius: float = 58.0

func _ready() -> void:
	add_to_group("sleep_spot")
	queue_redraw()

func can_interact(player_position: Vector2) -> bool:
	return global_position.distance_to(player_position) <= interaction_radius

func interact(player: PlayerController) -> String:
	if player == null or not can_interact(player.global_position):
		return ""

	GameClock.sleep_and_start_next_day()
	player.restore_after_sleep()
	return "Voce dormiu. Dia %d comecou." % GameClock.day

func _draw() -> void:
	draw_rect(Rect2(-26, -16, 52, 32), Color(0.40, 0.25, 0.16), true)
	draw_rect(Rect2(-22, -13, 44, 26), Color(0.92, 0.84, 0.62), true)
	draw_rect(Rect2(-20, -11, 14, 10), Color(0.96, 0.95, 0.85), true)
	draw_rect(Rect2(-26, -16, 52, 32), Color(0.13, 0.09, 0.06), false, 2.0)
