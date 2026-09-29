class_name GameSaveManager
extends Node

signal game_saved(path: String)
signal game_loaded(path: String)
signal save_failed(message: String)

const SAVE_VERSION := 1
const SAVE_PATH := "user://savegame.json"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> bool:
	var player := get_tree().get_first_node_in_group("player") as PlayerController
	var farm := get_tree().get_first_node_in_group("farm_field") as FarmField

	if player == null or farm == null:
		save_failed.emit("Player ou fazenda nao encontrados.")
		return false

	var data := {
		"version": SAVE_VERSION,
		"clock": GameClock.get_save_data(),
		"player": player.get_save_data(),
		"farm": farm.get_save_data(),
		"world": _get_world_save_data(),
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		save_failed.emit("Nao foi possivel abrir o arquivo de save.")
		return false

	file.store_string(JSON.stringify(data))
	file.close()
	game_saved.emit(SAVE_PATH)
	return true

func load_game() -> bool:
	if not has_save():
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		save_failed.emit("Nao foi possivel abrir o save.")
		return false

	var json_text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_text)
	if not (parsed is Dictionary):
		save_failed.emit("Save invalido.")
		return false

	var data: Dictionary = parsed
	if int(data.get("version", 0)) != SAVE_VERSION:
		save_failed.emit("Versao de save incompativel.")
		return false

	var clock_data: Dictionary = data.get("clock", {})
	var player_data: Dictionary = data.get("player", {})
	var farm_data: Dictionary = data.get("farm", {})
	var world_data: Dictionary = data.get("world", {})

	GameClock.load_save_data(clock_data)
	WeatherManager.refresh_for_current_day()

	var player := get_tree().get_first_node_in_group("player") as PlayerController
	var farm := get_tree().get_first_node_in_group("farm_field") as FarmField

	if player != null:
		player.load_save_data(player_data)

	if farm != null:
		farm.load_save_data(farm_data)

	_load_world_save_data(world_data)
	game_loaded.emit(SAVE_PATH)
	return true

func delete_save() -> bool:
	if not has_save():
		return true

	var absolute_path := ProjectSettings.globalize_path(SAVE_PATH)
	return DirAccess.remove_absolute(absolute_path) == OK

func _get_world_save_data() -> Dictionary:
	var alive_resources: Array[String] = []
	for node in get_tree().get_nodes_in_group("harvestable_resource"):
		if node is HarvestableResource:
			alive_resources.append(String(node.name))

	return {
		"alive_resources": alive_resources,
	}

func _load_world_save_data(data: Dictionary) -> void:
	var saved_alive: Array = data.get("alive_resources", [])
	var alive_lookup: Dictionary = {}

	for value in saved_alive:
		alive_lookup[String(value)] = true

	for node in get_tree().get_nodes_in_group("harvestable_resource"):
		if not (node is HarvestableResource):
			continue

		if not alive_lookup.has(String(node.name)):
			node.queue_free()
