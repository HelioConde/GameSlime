class_name CropDefinition
extends Resource

@export var id: StringName = &"starter_turnip"
@export var display_name: String = "Nabo do Vale"
@export_range(1, 28, 1) var growth_days: int = 4
@export_range(2, 8, 1) var visual_stages: int = 4
@export var sell_value: int = 35
@export var crop_color: Color = Color(0.62, 0.88, 0.42)
@export_range(0, 14, 1) var sprite_row: int = 0
@export var harvest_item_id: StringName = &"starter_turnip"

@export_group("Harvest")
@export_range(1, 99, 1) var harvest_min: int = 1
@export_range(1, 99, 1) var harvest_max: int = 1
@export_range(0, 28, 1) var regrow_days: int = 0

@export_group("Season")
@export var grows_in_spring: bool = true
@export var grows_in_summer: bool = false
@export var grows_in_fall: bool = false
@export var grows_in_winter: bool = false

func can_grow_in_season(season: int) -> bool:
	match season:
		GameClockManager.Season.SPRING:
			return grows_in_spring
		GameClockManager.Season.SUMMER:
			return grows_in_summer
		GameClockManager.Season.FALL:
			return grows_in_fall
		GameClockManager.Season.WINTER:
			return grows_in_winter
		_:
			return false

func get_season_names() -> String:
	var names: Array[String] = []
	if grows_in_spring:
		names.append("Primavera")
	if grows_in_summer:
		names.append("Verao")
	if grows_in_fall:
		names.append("Outono")
	if grows_in_winter:
		names.append("Inverno")
	return ", ".join(names)

func get_harvest_amount(day_seed: int, cell: Vector2i) -> int:
	var minimum := mini(harvest_min, harvest_max)
	var maximum := maxi(harvest_min, harvest_max)
	if minimum == maximum:
		return minimum

	var rng := RandomNumberGenerator.new()
	rng.seed = int(day_seed * 104729 + cell.x * 92821 + cell.y * 68917 + String(id).hash())
	return rng.randi_range(minimum, maximum)

func regrows_after_harvest() -> bool:
	return regrow_days > 0
