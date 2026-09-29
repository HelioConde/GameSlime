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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameClock.day_started.connect(_on_day_started)
	_roll_weather_for_current_day()

func is_raining() -> bool:
	return current_weather == Weather.RAIN

func is_snowing() -> bool:
	return current_weather == Weather.SNOW

func get_weather_name(weather: int = current_weather) -> String:
	match weather:
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

func get_tomorrow_weather() -> int:
	var next_year := GameClock.year
	var next_season := GameClock.season_index
	var next_day := GameClock.day_of_season + 1

	if next_day > GameClock.DAYS_PER_SEASON:
		next_day = 1
		next_season += 1

		if next_season > GameClock.Season.WINTER:
			next_season = GameClock.Season.SPRING
			next_year += 1

	return _weather_for_date(next_year, next_season, next_day, GameClock.day + 1)

func get_tomorrow_weather_name() -> String:
	return get_weather_name(get_tomorrow_weather())

func refresh_for_current_day() -> void:
	_roll_weather_for_current_day()

func _on_day_started(_day: int) -> void:
	_roll_weather_for_current_day()

func _roll_weather_for_current_day() -> void:
	_set_weather(
		_weather_for_date(
			GameClock.year,
			GameClock.season_index,
			GameClock.day_of_season,
			GameClock.day
		)
	)

func _weather_for_date(year: int, season: int, season_day: int, absolute_day: int) -> int:
	if absolute_day == 1:
		return Weather.CLEAR

	var rng := RandomNumberGenerator.new()
	rng.seed = int(year * 100000 + season * 1000 + season_day * 37)
	var roll := rng.randf()

	match season:
		GameClock.Season.SPRING:
			if roll < 0.30:
				return Weather.RAIN
			if roll < 0.45:
				return Weather.CLOUDY
			return Weather.CLEAR
		GameClock.Season.SUMMER:
			if roll < 0.15:
				return Weather.RAIN
			if roll < 0.25:
				return Weather.CLOUDY
			return Weather.CLEAR
		GameClock.Season.FALL:
			if roll < 0.25:
				return Weather.RAIN
			if roll < 0.45:
				return Weather.CLOUDY
			return Weather.CLEAR
		GameClock.Season.WINTER:
			if roll < 0.35:
				return Weather.SNOW
			if roll < 0.55:
				return Weather.CLOUDY
			return Weather.CLEAR
		_:
			return Weather.CLEAR

func _set_weather(value: int) -> void:
	current_weather = value
	weather_changed.emit(current_weather)
