class_name Farmhouse
extends Node2D

const ROOF_ATLAS: Texture2D = preload("res://assets/sprout_lands/buildings/wooden_house_roof.png")
const WALL_ATLAS: Texture2D = preload("res://assets/sprout_lands/buildings/wooden_house_walls.png")
const DOOR_ATLAS: Texture2D = preload("res://assets/sprout_lands/buildings/door_animation.png")

const WALL_BLOCK_SOURCE := Rect2(0, 0, 32, 48)
const WINDOW_SOURCE := Rect2(48, 0, 32, 32)
const ROOF_SOURCE := Rect2(48, 16, 64, 64)
const DOOR_SOURCE := Rect2(0, 0, 16, 32)

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	_draw_wall_body()
	_draw_roof()
	_draw_windows()
	_draw_door()

func _draw_wall_body() -> void:
	for index in range(3):
		var destination := Rect2(
			Vector2(-96 + index * 64, -48),
			Vector2(64, 96)
		)
		draw_texture_rect_region(WALL_ATLAS, destination, WALL_BLOCK_SOURCE)

func _draw_roof() -> void:
	draw_texture_rect_region(
		ROOF_ATLAS,
		Rect2(Vector2(-112, -132), Vector2(224, 128)),
		ROOF_SOURCE
	)

func _draw_windows() -> void:
	draw_texture_rect_region(
		WALL_ATLAS,
		Rect2(Vector2(-78, -24), Vector2(48, 48)),
		WINDOW_SOURCE
	)
	draw_texture_rect_region(
		WALL_ATLAS,
		Rect2(Vector2(30, -24), Vector2(48, 48)),
		WINDOW_SOURCE
	)

func _draw_door() -> void:
	draw_texture_rect_region(
		DOOR_ATLAS,
		Rect2(Vector2(-16, 0), Vector2(32, 64)),
		DOOR_SOURCE
	)
