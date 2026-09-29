class_name WorldSpawnManager
extends Node2D

const DROP_SCENE := preload("res://scenes/world/item_drop.tscn")

const WILD_FLOWER: ItemDefinition = preload("res://resources/items/wild_flower.tres")
const WILD_BERRY: ItemDefinition = preload("res://resources/items/wild_berry.tres")
const WILD_MUSHROOM: ItemDefinition = preload("res://resources/items/wild_mushroom.tres")
const WILD_ROOT: ItemDefinition = preload("res://resources/items/wild_root.tres")
const WOOD: ItemDefinition = preload("res://resources/items/wood.tres")
const STONE: ItemDefinition = preload("res://resources/items/stone.tres")
const SPRING_SEED: ItemDefinition = preload("res://resources/items/starter_turnip_seed.tres")
const SUMMER_SEED: ItemDefinition = preload("res://resources/items/summer_tomato_seed.tres")
const FALL_SEED: ItemDefinition = preload("res://resources/items/fall_pumpkin_seed.tres")
const WINTER_SEED: ItemDefinition = preload("res://resources/items/winter_root_seed.tres")

const MIN_DAILY_SPAWNS := 4
const MAX_DAILY_SPAWNS := 7
const MAX_NATURAL_SPAWNS := 12
const FORAGE_LIFETIME_DAYS := 3
const MATERIAL_LIFETIME_DAYS := 5
const SEED_LIFETIME_DAYS := 3

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
	_prune_expired_spawns()
	if _has_spawned_for_day(GameClock.day):
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_for_current_day()

	var points := SPAWN_POINTS.duplicate()
	_shuffle_points(points, rng)

	var spawn_count := mini(
		rng.randi_range(MIN_DAILY_SPAWNS, MAX_DAILY_SPAWNS),
		points.size()
	)

	var created := 0
	for point in points:
		if created >= spawn_count:
			break
		if _get_natural_spawn_count() >= MAX_NATURAL_SPAWNS:
			break
		if _has_spawn_at(point):
			continue

		var item := _pick_item_for_season(rng)
		if item == null:
			continue

		var amount := 1
		if item.id in [&"wood", &"stone"]:
			amount = rng.randi_range(1, 3)

		_spawn_drop(point, item, amount, created)
		created += 1

func get_daily_spawn_snapshot() -> Array[String]:
	var snapshot: Array[String] = []
	for node in get_tree().get_nodes_in_group("daily_world_spawn"):
		var drop := node as ItemDrop
		if drop == null:
			continue
		snapshot.append(
			"%s:%d:%d:%d:%d:%d" % [
				String(drop.item_id),
				drop.amount,
				roundi(drop.global_position.x),
				roundi(drop.global_position.y),
				drop.spawned_day,
				drop.expires_after_days,
			]
		)
	snapshot.sort()
	return snapshot

func _prune_expired_spawns() -> void:
	for node in get_tree().get_nodes_in_group("daily_world_spawn"):
		var drop := node as ItemDrop
		if drop == null or not drop.is_natural_spawn_expired(GameClock.day):
			continue
		var parent := drop.get_parent()
		if parent != null:
			parent.remove_child(drop)
		drop.queue_free()

func _has_spawned_for_day(day: int) -> bool:
	for node in get_tree().get_nodes_in_group("daily_world_spawn"):
		var drop := node as ItemDrop
		if drop != null and drop.natural_spawn and drop.spawned_day == day:
			return true
	return false

func _get_natural_spawn_count() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group("daily_world_spawn"):
		if node is ItemDrop:
			count += 1
	return count

func _has_spawn_at(point: Vector2) -> bool:
	for node in get_tree().get_nodes_in_group("daily_world_spawn"):
		var drop := node as ItemDrop
		if drop != null and drop.global_position.distance_squared_to(point) < 4.0:
			return true
	return false

func _spawn_drop(position_value: Vector2, item: ItemDefinition, amount: int, index: int) -> void:
	if get_parent() == null or item == null:
		return

	var drop := DROP_SCENE.instantiate() as ItemDrop
	if drop == null:
		return

	drop.name = "DailySpawn_%d_%02d" % [GameClock.day, index + 1]
	get_parent().add_child(drop)
	drop.global_position = position_value
	drop.configure(item.id, amount, item.tint)
	drop.configure_natural_spawn(GameClock.day, _get_lifetime_for_item(item))

func _get_lifetime_for_item(item: ItemDefinition) -> int:
	if item == null:
		return FORAGE_LIFETIME_DAYS
	if item.kind == ItemDefinition.ItemKind.SEED:
		return SEED_LIFETIME_DAYS
	if item.id in [&"wood", &"stone"]:
		return MATERIAL_LIFETIME_DAYS
	return FORAGE_LIFETIME_DAYS

func _pick_item_for_season(rng: RandomNumberGenerator) -> ItemDefinition:
	var pool: Array[ItemDefinition] = []

	match GameClock.season_index:
		GameClock.Season.SPRING:
			pool = [
				WILD_FLOWER, WILD_FLOWER, WILD_BERRY,
				WOOD, STONE, SPRING_SEED,
			]
		GameClock.Season.SUMMER:
			pool = [
				WILD_BERRY, WILD_BERRY, WILD_FLOWER,
				WOOD, STONE, SUMMER_SEED,
			]
		GameClock.Season.FALL:
			pool = [
				WILD_MUSHROOM, WILD_MUSHROOM, WILD_BERRY,
				WOOD, STONE, FALL_SEED,
			]
		GameClock.Season.WINTER:
			pool = [
				WILD_ROOT, WILD_ROOT, STONE,
				WOOD, WINTER_SEED,
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
