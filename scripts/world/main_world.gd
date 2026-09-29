extends Node2D

const GRASS_ATLAS: Texture2D = preload("res://assets/sprout_lands/tiles/grass_tiles.png")
const GRASS_SOURCE := Rect2(0, 64, 16, 16)
const WORLD_TILE_SIZE := 32

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	_draw_grass_background()


func _draw_grass_background() -> void:
	for y in range(0, 720, WORLD_TILE_SIZE):
		for x in range(0, 1280, WORLD_TILE_SIZE):
			draw_texture_rect_region(
				GRASS_ATLAS,
				Rect2(x, y, WORLD_TILE_SIZE, WORLD_TILE_SIZE),
				GRASS_SOURCE
			)
