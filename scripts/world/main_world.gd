extends Node2D

const GRASS_ATLAS: Texture2D = preload("res://assets/sprout_lands/tiles/grass_tiles.png")
const GRASS_SOURCE := Rect2(0, 64, 16, 16)
const WORLD_TILE_SIZE := 32

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	_draw_grass_background()

	# Temporary farmhouse silhouette until building tiles are integrated.
	draw_rect(Rect2(290, 110, 180, 130), Color(0.46, 0.31, 0.20), true)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(270, 115),
			Vector2(380, 45),
			Vector2(490, 115),
		]),
		Color(0.56, 0.20, 0.16)
	)
	draw_rect(Rect2(358, 170, 44, 70), Color(0.24, 0.14, 0.10), true)

func _draw_grass_background() -> void:
	for y in range(0, 720, WORLD_TILE_SIZE):
		for x in range(0, 1280, WORLD_TILE_SIZE):
			draw_texture_rect_region(
				GRASS_ATLAS,
				Rect2(x, y, WORLD_TILE_SIZE, WORLD_TILE_SIZE),
				GRASS_SOURCE
			)
