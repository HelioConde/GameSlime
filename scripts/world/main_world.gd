extends Node2D

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.16, 0.31, 0.17), true)

	for x in range(0, 1281, 32):
		draw_line(Vector2(x, 0), Vector2(x, 720), Color(0.12, 0.24, 0.13, 0.16), 1.0)
	for y in range(0, 721, 32):
		draw_line(Vector2(0, y), Vector2(1280, y), Color(0.12, 0.24, 0.13, 0.16), 1.0)

	draw_rect(Rect2(290, 110, 180, 130), Color(0.46, 0.31, 0.20), true)
	draw_polygon(
		PackedVector2Array([Vector2(270, 115), Vector2(380, 45), Vector2(490, 115)]),
		PackedColorArray([Color(0.56, 0.20, 0.16)])
	)
	draw_rect(Rect2(358, 170, 44, 70), Color(0.24, 0.14, 0.10), true)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(448, 176),
		"Horta de prototipo",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18,
		Color(0.92, 0.95, 0.82)
	)
