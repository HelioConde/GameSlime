extends Node2D

const GRASS_ATLAS: Texture2D = preload("res://assets/sprout_lands/tiles/grass_tiles.png")
const GRASS_SOURCE := Rect2(0, 64, 16, 16)
const WORLD_TILE_SIZE := 32

func _ready() -> void:
	queue_redraw()

	if not GameClock.day_started.is_connected(_on_day_started):
		GameClock.day_started.connect(_on_day_started)

	call_deferred("_load_saved_game")

func _load_saved_game() -> void:
	var loaded := SaveManager.load_game()
	if loaded:
		return

	# A missing/corrupt/incompatible save must still produce a playable world.
	# Daily patches normally wait for SaveManager when a save file exists.
	for node in get_tree().get_nodes_in_group("daily_resource_patch"):
		var patch := node as DailyResourcePatch
		if patch != null:
			patch.ensure_resources()

func _on_day_started(_day: int) -> void:
	# Natural 02:00 rollover does not pass through SleepSpot. Schedule a save
	# after every day-start callback has restored player/world state.
	call_deferred("_autosave_new_day")

func _autosave_new_day() -> void:
	SaveManager.save_game()

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
