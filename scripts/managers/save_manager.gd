class_name GameSaveManager
extends Node

signal game_saved(path: String)
signal game_loaded(path: String)
signal save_failed(message: String)

const SAVE_VERSION := 7
const SAVE_PATH := "user://savegame.json"
const TEMP_SAVE_PATH := "user://savegame.tmp"
const BACKUP_SAVE_PATH := "user://savegame.bak"
const DROP_SCENE := preload("res://scenes/world/item_drop.tscn")
const SLIME_SCENE := preload("res://scenes/slimes/slime_creature.tscn")

var last_successful_save_day: int = -1
var last_successful_save_minute: int = -1

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(BACKUP_SAVE_PATH)

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
		"discoveries": SlimeDiscovery.get_save_data(),
		"economy": Economy.get_save_data(),
	}

	var file := FileAccess.open(TEMP_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		save_failed.emit("Nao foi possivel criar o arquivo temporario de save.")
		return false

	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()

	var save_absolute := ProjectSettings.globalize_path(SAVE_PATH)
	var temp_absolute := ProjectSettings.globalize_path(TEMP_SAVE_PATH)
	var backup_absolute := ProjectSettings.globalize_path(BACKUP_SAVE_PATH)

	if FileAccess.file_exists(BACKUP_SAVE_PATH):
		DirAccess.remove_absolute(backup_absolute)

	if FileAccess.file_exists(SAVE_PATH):
		var backup_error := DirAccess.rename_absolute(save_absolute, backup_absolute)
		if backup_error != OK:
			DirAccess.remove_absolute(temp_absolute)
			save_failed.emit("Nao foi possivel preparar o backup do save.")
			return false

	var replace_error := DirAccess.rename_absolute(temp_absolute, save_absolute)
	if replace_error != OK:
		if FileAccess.file_exists(BACKUP_SAVE_PATH):
			DirAccess.rename_absolute(backup_absolute, save_absolute)
		save_failed.emit("Nao foi possivel finalizar o save.")
		return false

	last_successful_save_day = GameClock.day
	last_successful_save_minute = GameClock.minute_of_day
	game_saved.emit(SAVE_PATH)
	return true

func load_game() -> bool:
	var candidates := [SAVE_PATH, BACKUP_SAVE_PATH]
	var data: Dictionary = {}
	var loaded_path := ""

	for path in candidates:
		if not FileAccess.file_exists(path):
			continue

		var candidate := _read_save_dictionary(path)
		if candidate.is_empty():
			continue

		var candidate_version := int(candidate.get("version", 0))
		if candidate_version < 1 or candidate_version > SAVE_VERSION:
			continue

		data = candidate
		loaded_path = path
		break

	if data.is_empty():
		save_failed.emit("Nenhum save valido encontrado.")
		return false

	var version := int(data.get("version", 0))
	var clock_data: Dictionary = data.get("clock", {})
	var player_data: Dictionary = data.get("player", {})
	var farm_data: Dictionary = data.get("farm", {})
	var world_data: Dictionary = data.get("world", {})
	var discovery_data: Dictionary = data.get("discoveries", {})
	var economy_data: Dictionary = data.get("economy", {})

	GameClock.load_save_data(clock_data)
	WeatherManager.refresh_for_current_day()
	if not discovery_data.is_empty():
		SlimeDiscovery.load_save_data(discovery_data)
	if not economy_data.is_empty():
		Economy.load_save_data(economy_data)

	var player := get_tree().get_first_node_in_group("player") as PlayerController
	var farm := get_tree().get_first_node_in_group("farm_field") as FarmField

	if player != null:
		player.load_save_data(player_data)

	if farm != null:
		farm.load_save_data(farm_data)

	_load_world_save_data(world_data, version)
	last_successful_save_day = GameClock.day
	last_successful_save_minute = GameClock.minute_of_day
	game_loaded.emit(loaded_path)
	return true

func was_saved_at_current_clock() -> bool:
	return (
		last_successful_save_day == GameClock.day
		and last_successful_save_minute == GameClock.minute_of_day
	)

func _read_save_dictionary(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var json_text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_text)
	if not (parsed is Dictionary):
		return {}

	return parsed as Dictionary

func delete_save() -> bool:
	var success := true
	for path in [SAVE_PATH, TEMP_SAVE_PATH, BACKUP_SAVE_PATH]:
		if not FileAccess.file_exists(path):
			continue
		var absolute_path := ProjectSettings.globalize_path(path)
		if DirAccess.remove_absolute(absolute_path) != OK:
			success = false
	return success

func _get_world_save_data() -> Dictionary:
	var alive_resources: Array[String] = []
	var slimes: Array[Dictionary] = []
	var drops: Array[Dictionary] = []
	var processors: Array[Dictionary] = []

	for node in get_tree().get_nodes_in_group("harvestable_resource"):
		if node is HarvestableResource:
			alive_resources.append(String(node.name))

	for node in get_tree().get_nodes_in_group("slime_creature"):
		var slime := node as SlimeCreature
		if slime != null:
			slimes.append(slime.get_save_data())

	for node in get_tree().get_nodes_in_group("slime_crystallizer"):
		var processor := node as SlimeCrystallizer
		if processor != null:
			processors.append(processor.get_save_data())

	for node in get_tree().get_nodes_in_group("world_drop"):
		var drop := node as ItemDrop
		if drop == null or drop.amount <= 0:
			continue
		drops.append({
			"item_id": String(drop.item_id),
			"amount": drop.amount,
			"position": [drop.global_position.x, drop.global_position.y],
			"tint": [drop.tint.r, drop.tint.g, drop.tint.b, drop.tint.a],
			"daily_spawn": drop.is_in_group("daily_world_spawn"),
			"natural_spawn": drop.natural_spawn,
			"spawned_day": drop.spawned_day,
			"expires_after_days": drop.expires_after_days,
		})

	return {
		"alive_resources": alive_resources,
		"slimes": slimes,
		"drops": drops,
		"processors": processors,
	}

func _load_world_save_data(data: Dictionary, save_version: int = SAVE_VERSION) -> void:
	for node in get_tree().get_nodes_in_group("daily_resource_patch"):
		var patch := node as DailyResourcePatch
		if patch != null:
			patch.ensure_resources()

	# Saves v5 were created before the complete mine/resource catalog existed.
# Saves v6 remain compatible with v7: fertilizer, soil age and natural-spawn
# lifetime fields are additive and load with safe defaults when absent.
	# Applying their old alive-resource whitelist would delete every resource
	# added later. For the one-time v5 -> v6 migration, keep scene resources
	# intact; the next autosave writes a complete v6 snapshot.
	if save_version >= 6:
		_load_resource_state(data)
	_load_slime_state(data)
	_load_processor_state(data)
	_load_drop_state(data)

func _load_resource_state(data: Dictionary) -> void:
	var saved_alive: Array = data.get("alive_resources", [])
	var alive_lookup: Dictionary = {}

	for value in saved_alive:
		alive_lookup[String(value)] = true

	for node in get_tree().get_nodes_in_group("harvestable_resource"):
		if not (node is HarvestableResource):
			continue

		if not alive_lookup.has(String(node.name)):
			node.queue_free()

func _load_slime_state(data: Dictionary) -> void:
	var saved_slimes: Array = data.get("slimes", [])
	if saved_slimes.is_empty():
		return

	var existing: Dictionary = {}
	for node in get_tree().get_nodes_in_group("slime_creature"):
		var slime := node as SlimeCreature
		if slime != null:
			existing[String(slime.name)] = slime

	var saved_names: Dictionary = {}

	for entry_variant in saved_slimes:
		if not (entry_variant is Dictionary):
			continue

		var entry: Dictionary = entry_variant
		var node_name := str(entry.get("node_name", ""))
		if node_name.is_empty():
			continue

		saved_names[node_name] = true
		var slime: SlimeCreature = existing.get(node_name) as SlimeCreature

		if slime == null:
			slime = SLIME_SCENE.instantiate() as SlimeCreature
			if slime == null:
				continue

			slime.name = node_name

			var position_data: Array = entry.get("position", [])
			if position_data.size() >= 2:
				slime.position = Vector2(float(position_data[0]), float(position_data[1]))

			get_tree().current_scene.add_child(slime)

		slime.load_save_data(entry)

	for node in get_tree().get_nodes_in_group("slime_creature"):
		var slime := node as SlimeCreature
		if slime == null:
			continue

		if not saved_names.has(String(slime.name)):
			slime.queue_free()

func _load_drop_state(data: Dictionary) -> void:
	for node in get_tree().get_nodes_in_group("world_drop"):
		if not is_instance_valid(node):
			continue
		var parent := node.get_parent()
		if parent != null:
			parent.remove_child(node)
		node.queue_free()

	var saved_drops: Array = data.get("drops", [])
	for entry_variant in saved_drops:
		if not (entry_variant is Dictionary):
			continue

		var entry: Dictionary = entry_variant
		var item_id := StringName(str(entry.get("item_id", "")))
		var amount := int(entry.get("amount", 0))
		var position_data: Array = entry.get("position", [])
		var tint_data: Array = entry.get("tint", [])

		if item_id == &"" or amount <= 0 or position_data.size() < 2:
			continue

		var drop := DROP_SCENE.instantiate() as ItemDrop
		if drop == null:
			continue

		get_tree().current_scene.add_child(drop)
		var is_natural := bool(entry.get("natural_spawn", entry.get("daily_spawn", false)))
		if is_natural:
			var spawned_day := int(entry.get("spawned_day", GameClock.day))
			var lifetime := int(entry.get("expires_after_days", 3))
			drop.configure_natural_spawn(spawned_day, lifetime)
		elif bool(entry.get("daily_spawn", false)):
			drop.add_to_group("daily_world_spawn")
		drop.global_position = Vector2(float(position_data[0]), float(position_data[1]))

		var tint := Color.WHITE
		if tint_data.size() >= 4:
			tint = Color(
				float(tint_data[0]),
				float(tint_data[1]),
				float(tint_data[2]),
				float(tint_data[3])
			)

		drop.configure(item_id, amount, tint)


func _load_processor_state(data: Dictionary) -> void:
	var saved_processors: Array = data.get("processors", [])
	if saved_processors.is_empty():
		return

	var by_name: Dictionary = {}
	for entry_variant in saved_processors:
		if not (entry_variant is Dictionary):
			continue
		var entry := entry_variant as Dictionary
		by_name[str(entry.get("node_name", ""))] = entry

	for node in get_tree().get_nodes_in_group("slime_crystallizer"):
		var processor := node as SlimeCrystallizer
		if processor == null:
			continue

		var key := String(processor.name)
		if by_name.has(key):
			processor.load_save_data(by_name[key] as Dictionary)
