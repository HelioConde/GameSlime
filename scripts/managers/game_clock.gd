class_name GameClockManager
extends Node

signal time_changed(day: int, hour: int, minute: int)
signal day_ended(day: int)
signal day_started(day: int)
signal calendar_changed(year: int, season: int, day_of_season: int)
signal season_changed(year: int, season: int)
signal year_changed(year: int)

enum Season {
	SPRING,
	SUMMER,
	FALL,
	WINTER,
}

const START_MINUTE := 6 * 60
const END_MINUTE := 26 * 60
const REAL_SECONDS_PER_TEN_GAME_MINUTES := 7.0
const DAYS_PER_SEASON := 28

var day: int = 1
var minute_of_day: int = START_MINUTE
var year: int = 1
var season_index: int = Season.SPRING
var day_of_season: int = 1

var _accumulator: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	time_changed.emit(day, get_hour(), get_minute())
	calendar_changed.emit(year, season_index, day_of_season)

func _process(delta: float) -> void:
	if get_tree().paused:
		return

	_accumulator += delta
	while _accumulator >= REAL_SECONDS_PER_TEN_GAME_MINUTES:
		_accumulator -= REAL_SECONDS_PER_TEN_GAME_MINUTES
		advance_minutes(10)

func advance_minutes(amount: int) -> void:
	if amount <= 0:
		return

	minute_of_day += amount
	if minute_of_day >= END_MINUTE:
		_finish_day()
		return

	time_changed.emit(day, get_hour(), get_minute())

func sleep_and_start_next_day() -> void:
	_finish_day()

func get_hour() -> int:
	var raw_hour: int = int(floor(float(minute_of_day) / 60.0))
	return raw_hour % 24

func get_minute() -> int:
	return minute_of_day % 60

func get_time_text() -> String:
	return "%02d:%02d" % [get_hour(), get_minute()]

func get_season_name() -> String:
	match season_index:
		Season.SPRING:
			return "Primavera"
		Season.SUMMER:
			return "Verao"
		Season.FALL:
			return "Outono"
		Season.WINTER:
			return "Inverno"
		_:
			return "Estacao"

func get_date_text() -> String:
	return "%s %d · Ano %d" % [get_season_name(), day_of_season, year]

func _finish_day() -> void:
	day_ended.emit(day)

	day += 1
	_advance_calendar()
	minute_of_day = START_MINUTE
	_accumulator = 0.0

	day_started.emit(day)
	time_changed.emit(day, get_hour(), get_minute())
	calendar_changed.emit(year, season_index, day_of_season)

func _advance_calendar() -> void:
	day_of_season += 1

	if day_of_season <= DAYS_PER_SEASON:
		return

	day_of_season = 1
	season_index += 1

	if season_index > Season.WINTER:
		season_index = Season.SPRING
		year += 1
		year_changed.emit(year)

	season_changed.emit(year, season_index)

func get_save_data() -> Dictionary:
	return {
		"day": day,
		"minute_of_day": minute_of_day,
		"year": year,
		"season_index": season_index,
		"day_of_season": day_of_season,
	}

func load_save_data(data: Dictionary) -> void:
	day = maxi(int(data.get("day", 1)), 1)
	minute_of_day = int(data.get("minute_of_day", START_MINUTE))
	year = maxi(int(data.get("year", 1)), 1)
	season_index = clampi(int(data.get("season_index", Season.SPRING)), Season.SPRING, Season.WINTER)
	day_of_season = clampi(int(data.get("day_of_season", 1)), 1, DAYS_PER_SEASON)
	_accumulator = 0.0

	time_changed.emit(day, get_hour(), get_minute())
	calendar_changed.emit(year, season_index, day_of_season)
