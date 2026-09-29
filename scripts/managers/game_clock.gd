class_name GameClockManager
extends Node

signal time_changed(day: int, hour: int, minute: int)
signal day_ended(day: int)
signal day_started(day: int)

const START_MINUTE := 6 * 60
const END_MINUTE := 26 * 60
const REAL_SECONDS_PER_TEN_GAME_MINUTES := 7.0

var day: int = 1
var minute_of_day: int = START_MINUTE
var _accumulator: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	time_changed.emit(day, get_hour(), get_minute())

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

func _finish_day() -> void:
	day_ended.emit(day)
	day += 1
	minute_of_day = START_MINUTE
	_accumulator = 0.0
	day_started.emit(day)
	time_changed.emit(day, get_hour(), get_minute())
