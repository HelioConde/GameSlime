extends Node2D

const GRASS_ATLAS: Texture2D = preload("res://assets/sprout_lands/tiles/grass_tiles.png")
const GRASS_SOURCE := Rect2(0, 64, 16, 16)
const WORLD_TILE_SIZE := 32

@onready var day_night_tint: CanvasModulate = $DayNightTint

func _ready() -> void:
	queue_redraw()

	if not GameClock.day_started.is_connected(_on_day_started):
		GameClock.day_started.connect(_on_day_started)
	if not GameClock.time_changed.is_connected(_on_time_changed):
		GameClock.time_changed.connect(_on_time_changed)

	_update_day_night_tint()
	call_deferred("_load_saved_game")

func _process(_delta: float) -> void:
	if day_night_tint == null:
		return
	var player := get_tree().get_first_node_in_group("player") as PlayerController
	day_night_tint.visible = player == null or not _is_player_in_mine(player)

func _on_time_changed(_day: int, _hour: int, _minute: int) -> void:
	_update_day_night_tint()

func _update_day_night_tint() -> void:
	if day_night_tint == null:
		return
	day_night_tint.color = get_daylight_color(GameClock.minute_of_day)

func get_daylight_color(game_minute: int) -> Color:
	var minute := clampi(game_minute, GameClock.START_MINUTE, GameClock.END_MINUTE)
	var keyframes := [
		{"minute": 360, "color": Color(0.76, 0.82, 0.96, 1.0)},
		{"minute": 450, "color": Color(0.94, 0.94, 0.98, 1.0)},
		{"minute": 510, "color": Color.WHITE},
		{"minute": 1020, "color": Color.WHITE},
		{"minute": 1140, "color": Color(0.92, 0.82, 0.72, 1.0)},
		{"minute": 1260, "color": Color(0.66, 0.70, 0.82, 1.0)},
		{"minute": 1380, "color": Color(0.48, 0.54, 0.70, 1.0)},
		{"minute": 1560, "color": Color(0.36, 0.42, 0.60, 1.0)},
	]

	for index in range(keyframes.size() - 1):
		var left := keyframes[index] as Dictionary
		var right := keyframes[index + 1] as Dictionary
		var left_minute := int(left["minute"])
		var right_minute := int(right["minute"])
		if minute < left_minute or minute > right_minute:
			continue
		var ratio := inverse_lerp(float(left_minute), float(right_minute), float(minute))
		var left_color: Color = left.get("color", Color.WHITE)
		var right_color: Color = right.get("color", Color.WHITE)
		return left_color.lerp(right_color, ratio)

	var last_keyframe := keyframes[keyframes.size() - 1] as Dictionary
	return last_keyframe.get("color", Color.WHITE)

func _is_player_in_mine(player: PlayerController) -> bool:
	for node in get_tree().get_nodes_in_group("mine_area"):
		var mine := node as MineArea
		if mine != null and mine.contains_position(player.global_position):
			return true
	return false

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

	for node in get_tree().get_nodes_in_group("regrowing_resource_patch"):
		var patch := node as RegrowingResourcePatch
		if patch != null:
			patch.refresh_for_day(GameClock.day, true)

func _on_day_started(_day: int) -> void:
	# Natural 02:00 rollover does not pass through SleepSpot. Schedule a save
	# after every day-start callback has restored player/world state.
	call_deferred("_autosave_new_day")

func _autosave_new_day() -> void:
	if SaveManager.was_saved_at_current_clock():
		return
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
