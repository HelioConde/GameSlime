extends Control

var _phase: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _process(delta: float) -> void:
	_phase += delta
	queue_redraw()

func _draw() -> void:
	if _is_player_inside_mine():
		return

	match WeatherManager.current_weather:
		WeatherManager.Weather.CLOUDY:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.10, 0.13, 0.16, 0.10), true)
		WeatherManager.Weather.RAIN:
			_draw_rain()
		WeatherManager.Weather.SNOW:
			_draw_snow()

func _draw_rain() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.09, 0.16, 0.16), true)

	for index in range(80):
		var x := fmod(float(index * 97) + _phase * 105.0, size.x + 40.0) - 20.0
		var y := fmod(float(index * 53) + _phase * 190.0, size.y + 40.0) - 20.0
		draw_line(
			Vector2(x, y),
			Vector2(x - 4.0, y + 13.0),
			Color(0.68, 0.83, 1.0, 0.62),
			1.0
		)

func _draw_snow() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.72, 0.82, 0.91, 0.06), true)

	for index in range(55):
		var drift := sin(_phase * 1.5 + float(index)) * 8.0
		var x := fmod(float(index * 83) + drift, size.x + 30.0) - 15.0
		var y := fmod(float(index * 61) + _phase * 45.0, size.y + 30.0) - 15.0
		draw_circle(Vector2(x, y), 1.5 + float(index % 2), Color(1.0, 1.0, 1.0, 0.78))


func _is_player_inside_mine() -> bool:
	var player := get_tree().get_first_node_in_group("player") as PlayerController
	if player == null:
		return false

	for node in get_tree().get_nodes_in_group("mine_area"):
		var mine := node as MineArea
		if mine != null and mine.contains_position(player.global_position):
			return true

	return false
