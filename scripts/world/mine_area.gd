class_name MineArea
extends Node2D

@export var mine_size: Vector2 = Vector2(720, 620)

func _ready() -> void:
	add_to_group("mine_area")
	z_index = -4
	queue_redraw()

func contains_position(world_position: Vector2) -> bool:
	var local := to_local(world_position)
	var half := mine_size * 0.5
	return (
		local.x >= -half.x
		and local.x <= half.x
		and local.y >= -half.y
		and local.y <= half.y
	)

func _draw() -> void:
	var half := mine_size * 0.5
	var floor_rect := Rect2(-half, mine_size)

	draw_rect(floor_rect, Color(0.085, 0.09, 0.095), true)

	# Rocky floor patches.
	for x in range(int(-half.x) + 36, int(half.x) - 20, 72):
		for y in range(int(-half.y) + 40, int(half.y) - 20, 64):
			var offset := Vector2(
				float((x * 13 + y * 7) % 17) - 8.0,
				float((x * 5 + y * 11) % 13) - 6.0
			)
			draw_circle(Vector2(x, y) + offset, 2.0, Color(0.17, 0.18, 0.19, 0.72))

	# Cave walls.
	var wall_color := Color(0.18, 0.19, 0.20)
	var edge_color := Color(0.28, 0.29, 0.30)
	draw_rect(Rect2(-half.x, -half.y, mine_size.x, 30), wall_color, true)
	draw_rect(Rect2(-half.x, half.y - 30, mine_size.x, 30), wall_color, true)
	draw_rect(Rect2(-half.x, -half.y, 30, mine_size.y), wall_color, true)
	draw_rect(Rect2(half.x - 30, -half.y, 30, mine_size.y), wall_color, true)

	draw_line(Vector2(-half.x + 30, -half.y + 30), Vector2(half.x - 30, -half.y + 30), edge_color, 2.0)
	draw_line(Vector2(-half.x + 30, half.y - 30), Vector2(half.x - 30, half.y - 30), edge_color, 2.0)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(-70, -half.y + 55),
		"MINA RASA",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18,
		Color(0.66, 0.68, 0.70)
	)
