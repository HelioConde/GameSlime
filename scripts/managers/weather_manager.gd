class_name WorldWeatherManager
extends Node

signal weather_changed(weather: int)

enum Weather {
	CLEAR,
	CLOUDY,
	RAIN,
	SNOW,
}

var current_weather: int = Weather.CLEAR
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameClock.day_started.connect(_on_day_started)
	_roll_weather_for_current_day()

func is_raining() -> bool:
	return current_weather == Weather.RAIN

func is_snowing() -> bool:
	return current_weather == Weather.SNOW

func get_weather_name() -> String:
	match current_weather:
		Weather.CLEAR:
			return "Ensolarado"
		Weather.CLOUDY:
			return "Nublado"
		Weather.RAIN:
			return "Chuva"
		Weather.SNOW:
			return "Neve"
		_:
			return "Clima"

func _on_day_started(_day: int) -> void:
	_roll_weather_for_current_day()

func refresh_for_current_day() -> void:
	_roll_weather_for_current_day()

func _roll_weather_for_current_day() -> void:
	if GameClock.day == 1:
		_set_weather(Weather.CLEAR)
		return

	var seed_value := int(
		GameClock.year * 100000
		+ GameClock.season_index * 1000
		+ GameClock.day_of_season * 37
	)
	_rng.seed = seed_value
	var roll := _rng.randf()

	match GameClock.season_index:
		GameClock.Season.SPRING:
			if roll < 0.30:
				_set_weather(Weather.RAIN)
			elif roll < 0.45:
				_set_weather(Weather.CLOUDY)
			else:
				_set_weather(Weather.CLEAR)
		GameClock.Season.SUMMER:
			if roll < 0.15:
				_set_weather(Weather.RAIN)
			elif roll < 0.25:
				_set_weather(Weather.CLOUDY)
			else:
				_set_weather(Weather.CLEAR)
		GameClock.Season.FALL:
			if roll < 0.25:
				_set_weather(Weather.RAIN)
			elif roll < 0.45:
				_set_weather(Weather.CLOUDY)
			else:
				_set_weather(Weather.CLEAR)
		GameClock.Season.WINTER:
			if roll < 0.35:
				_set_weather(Weather.SNOW)
			elif roll < 0.55:
				_set_weather(Weather.CLOUDY)
			else:
				_set_weather(Weather.CLEAR)

func _set_weather(value: int) -> void:
	current_weather = value
	weather_changed.emit(current_weather)
