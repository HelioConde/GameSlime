class_name CalendarEventManager
extends Node

var _events: Dictionary = {}

func _ready() -> void:
	_register_default_events()

func get_event(season: int, day_of_season: int) -> Dictionary:
	var key := _make_key(season, day_of_season)
	if not _events.has(key):
		return {}
	return (_events[key] as Dictionary).duplicate(true)

func get_current_event() -> Dictionary:
	return get_event(GameClock.season_index, GameClock.day_of_season)

func get_current_event_name() -> String:
	var event := get_current_event()
	return str(event.get("name", ""))

func get_events_for_season(season: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for day in range(1, GameClock.DAYS_PER_SEASON + 1):
		var event := get_event(season, day)
		if event.is_empty():
			continue
		result.append(event)

	return result

func _register_default_events() -> void:
	_events.clear()

	_register(GameClock.Season.SPRING, 7, "Feira da Primavera", "Um dia de encontro e comercio.")
	_register(GameClock.Season.SPRING, 21, "Dia das Flores", "Celebracao do fim da Primavera.")
	_register(GameClock.Season.SUMMER, 7, "Festival do Sol", "Festival de Verao.")
	_register(GameClock.Season.SUMMER, 21, "Noite das Lanternas", "Evento noturno de Verao.")
	_register(GameClock.Season.FALL, 7, "Feira da Colheita", "Exposicao dos produtos da fazenda.")
	_register(GameClock.Season.FALL, 21, "Festival da Lua", "Evento de Outono.")
	_register(GameClock.Season.WINTER, 7, "Feira de Inverno", "Mercado especial da estacao.")
	_register(GameClock.Season.WINTER, 21, "Festival da Neve", "Celebracao de encerramento do ano.")

func _register(season: int, day: int, event_name: String, description: String) -> void:
	_events[_make_key(season, day)] = {
		"season": season,
		"day": day,
		"name": event_name,
		"description": description,
	}

func _make_key(season: int, day: int) -> String:
	return "%d:%d" % [season, day]
