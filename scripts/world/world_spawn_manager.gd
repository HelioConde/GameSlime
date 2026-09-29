class_name WorldSpawnManager
extends Node2D

const DROP_SCENE := preload("res://scenes/world/item_drop.tscn")

const WILD_FLOWER: ItemDefinition = preload("res://resources/items/wild_flower.tres")
const WILD_BERRY: ItemDefinition = preload("res://resources/items/wild_berry.tres")
const WILD_MUSHROOM: ItemDefinition = preload("res://resources/items/wild_mushroom.tres")
const WILD_ROOT: ItemDefinition = preload("res://resources/items/wild_root.tres")
const WOOD: ItemDefinition = preload("res://resources/items/wood.tres")
const STONE: ItemDefinition = preload("res://resources/items/stone.tres")
const STARTER_SEED: ItemDefinition = preload("res://resources/items/starter_turnip_seed.tres")

const MIN_DAILY_SPAWNS := 4
const MAX_DAILY_SPAWNS := 7

const SPAWN_POINTS: Array[Vector2] = [
	Vector2(110, 110),
	Vector2(185, 150),
	Vector2(115, 255),
	Vector2(190, 315),
	Vector2(105, 430),
	Vector2(175, 545),
	Vector2(260, 625),
	Vector2(390, 620),
	Vector2(505, 640),
	Vector2(625, 650),
	Vector2(750, 632),
	Vector2(865, 620),
	Vector2(915, 390),
	Vector2(1040, 400),
	Vector2(1130, 350),
	Vector2(1140, 125),
	Vector2(1010, 105),
	Vector2(875, 115),
	Vector2(730, 105),
	Vector2(600, 110),
	Vector2(520, 115),
	Vector2(285, 555),
]

func _ready() -> void:
	add_to_group("world_spawn_manager")
	if not GameClock.day_started.is_connected(_on_day_started):
		GameClock.day_started.connect(_on_day_started)

	if not SaveManager.has_save():
		call_deferred("refresh_for_current_day")

func _on_day_started(_day: int) -> void:
	refresh_for_current_day()

func refresh_for_current_day() -> void:
	_clear_daily_spawns()

	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_for_current_day()

	var points := SPAWN_POINTS.duplicate()
	_shuffle_points(points, rng)

	var spawn_count := mini(
		rng.randi_range(MIN_DAILY_SPAWNS, MAX_DAILY_SPAWNS),
		points.size()
	)

	for index in range(spawn_count):
		var item := _pick_item_for_season(rng)
		if item == null:
			continue

		var amount := 1
		if item.id in [&"wood", &"stone"]:
			amount = rng.randi_range(1, 3)

		_spawn_drop(points[index], item, amount, index)

func get_daily_spawn_snapshot() -> Array[String]:
	var snapshot: Array[String] = []
	for node in get_tree().get_nodes_in_group("daily_world_spawn"):
		var drop := node as ItemDrop
		if drop == null:
			continue
		snapshot.append(
			"%s:%d:%d:%d" % [
				String(drop.item_id),
				drop.amount,
				roundi(drop.global_position.x),
				roundi(drop.global_position.y),
			]
		)
	snapshot.sort()
	return snapshot

func _clear_daily_spawns() -> void:
	for node in get_tree().get_nodes_in_group("daily_world_spawn"):
		if is_instance_valid(node):
			node.queue_free()

func _spawn_drop(position_value: Vector2, item: ItemDefinition, amount: int, index: int) -> void:
	if get_parent() == null or item == null:
		return

	var drop := DROP_SCENE.instantiate() as ItemDrop
	if drop == null:
		return

	drop.name = "DailySpawn_%02d" % (index + 1)
	get_parent().add_child(drop)
	drop.add_to_group("daily_world_spawn")
	drop.global_position = position_value
	drop.configure(item.id, amount, item.tint)

func _pick_item_for_season(rng: RandomNumberGenerator) -> ItemDefinition:
	var pool: Array[ItemDefinition] = []

	match GameClock.season_index:
		GameClock.Season.SPRING:
			pool = [
				WILD_FLOWER, WILD_FLOWER, WILD_BERRY,
				WOOD, STONE, STARTER_SEED,
			]
		GameClock.Season.SUMMER:
			pool = [
				WILD_BERRY, WILD_BERRY, WILD_FLOWER,
				WOOD, STONE,
			]
		GameClock.Season.FALL:
			pool = [
				WILD_MUSHROOM, WILD_MUSHROOM, WILD_BERRY,
				WOOD, STONE,
			]
		GameClock.Season.WINTER:
			pool = [
				WILD_ROOT, WILD_ROOT, STONE,
				WOOD,
			]
		_:
			pool = [WOOD, STONE]

	if pool.is_empty():
		return null
	return pool[rng.randi_range(0, pool.size() - 1)]

func _seed_for_current_day() -> int:
	return int(
		GameClock.year * 1000003
		+ GameClock.season_index * 10007
		+ GameClock.day_of_season * 503
		+ GameClock.day * 97
	)

func _shuffle_points(points: Array[Vector2], rng: RandomNumberGenerator) -> void:
	for index in range(points.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temp := points[index]
		points[index] = points[swap_index]
		points[swap_index] = temp
