class_name GameSaveManager
extends Node

signal game_saved(path: String)
signal game_loaded(path: String)
signal save_failed(message: String)

const SAVE_VERSION := 4
const SAVE_PATH := "user://savegame.json"
const DROP_SCENE := preload("res://scenes/world/item_drop.tscn")
const SLIME_SCENE := preload("res://scenes/slimes/slime_creature.tscn")

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
		"discoveries": SlimeDiscovery.get_save_data(),
		"economy": Economy.get_save_data(),
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
	var version := int(data.get("version", 0))
	if version < 1 or version > SAVE_VERSION:
		save_failed.emit("Versao de save incompativel.")
		return false

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
	var slimes: Array[Dictionary] = []
	var drops: Array[Dictionary] = []

	for node in get_tree().get_nodes_in_group("harvestable_resource"):
		if node is HarvestableResource:
			alive_resources.append(String(node.name))

	for node in get_tree().get_nodes_in_group("slime_creature"):
		var slime := node as SlimeCreature
		if slime != null:
			slimes.append(slime.get_save_data())

	for node in get_tree().get_nodes_in_group("world_drop"):
		var drop := node as ItemDrop
		if drop == null or drop.amount <= 0:
			continue
		drops.append({
			"item_id": String(drop.item_id),
			"amount": drop.amount,
			"position": [drop.global_position.x, drop.global_position.y],
			"tint": [drop.tint.r, drop.tint.g, drop.tint.b, drop.tint.a],
		})

	return {
		"alive_resources": alive_resources,
		"slimes": slimes,
		"drops": drops,
	}

func _load_world_save_data(data: Dictionary) -> void:
	_load_resource_state(data)
	_load_slime_state(data)
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
