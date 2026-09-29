class_name FarmField
extends Node2D

const CROP_ATLAS: Texture2D = preload("res://assets/sprout_lands/crops/farming_plants.png")
const GRASS_ATLAS: Texture2D = preload("res://assets/sprout_lands/tiles/grass_tiles.png")
const SOIL_ATLAS: Texture2D = preload("res://assets/sprout_lands/tiles/tilled_dirt.png")
const GRASS_SOURCE := Rect2(0, 64, 16, 16)
const SOIL_SOURCE := Rect2(0, 64, 16, 16)

signal cell_changed(cell: Vector2i)
signal crop_planted(cell: Vector2i, crop: CropDefinition)
signal crop_harvested(cell: Vector2i, crop: CropDefinition, amount: int)
signal crops_withered(count: int)

@export var grid_size: Vector2i = Vector2i(12, 8)
@export var cell_size: int = 32

var harvested_total: int = 0
var _cells: Dictionary = {}

func _ready() -> void:
	add_to_group("farm_field")
	GameClock.day_ended.connect(_on_day_ended)
	GameClock.day_started.connect(_on_day_started)
	GameClock.season_changed.connect(_on_season_changed)
	call_deferred("_apply_current_weather")
	queue_redraw()

func world_to_cell(world_position: Vector2) -> Vector2i:
	var local := to_local(world_position)
	return Vector2i(floori(local.x / cell_size), floori(local.y / cell_size))

func cell_to_world(cell: Vector2i) -> Vector2:
	return to_global(Vector2(
		(float(cell.x) + 0.5) * cell_size,
		(float(cell.y) + 0.5) * cell_size
	))

func is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y

func get_cell(cell: Vector2i) -> FarmCellData:
	if not is_valid_cell(cell):
		return null
	if not _cells.has(cell):
		_cells[cell] = FarmCellData.new()
	return _cells[cell] as FarmCellData

func filter_valid_cells(cells: Array[Vector2i]) -> Array[Vector2i]:
	var valid: Array[Vector2i] = []
	for cell in cells:
		if is_valid_cell(cell):
			valid.append(cell)
	return valid

func apply_hoe(cells: Array[Vector2i]) -> int:
	var changed := 0
	for cell in filter_valid_cells(cells):
		var data := get_cell(cell)
		if data == null or data.tilled:
			continue
		data.tilled = true
		changed += 1
		cell_changed.emit(cell)

	if changed > 0:
		queue_redraw()
	return changed

func apply_water(cells: Array[Vector2i]) -> int:
	var changed := 0
	for cell in filter_valid_cells(cells):
		var data := get_cell(cell)
		if data == null or not data.tilled or data.watered_today:
			continue
		data.watered_today = true
		changed += 1
		cell_changed.emit(cell)

	if changed > 0:
		queue_redraw()
	return changed

func can_fertilize(cell: Vector2i) -> bool:
	var data := get_cell(cell)
	return data != null and data.tilled and data.fertility_bonus <= 0

func apply_fertilizer(cell: Vector2i, bonus: int) -> bool:
	if bonus <= 0 or not can_fertilize(cell):
		return false

	var data := get_cell(cell)
	data.fertility_bonus = bonus
	cell_changed.emit(cell)
	queue_redraw()
	return true

func can_plant(cell: Vector2i) -> bool:
	var data := get_cell(cell)
	return data != null and data.tilled and data.crop == null

func plant_crop(cell: Vector2i, crop: CropDefinition) -> bool:
	if crop == null or not can_plant(cell):
		return false
	if not crop.can_grow_in_season(GameClock.season_index):
		return false

	var data := get_cell(cell)
	data.crop = crop
	data.growth_days_completed = 0
	data.crop_stage = 0
	data.ready_to_harvest = false
	crop_planted.emit(cell, crop)
	cell_changed.emit(cell)
	queue_redraw()
	return true

func can_harvest(cell: Vector2i) -> bool:
	var data := get_cell(cell)
	return data != null and data.ready_to_harvest and data.crop != null

func get_harvest_amount(cell: Vector2i) -> int:
	if not can_harvest(cell):
		return 0

	var data := get_cell(cell)
	if data == null or data.crop == null:
		return 0
	return data.crop.get_harvest_amount(GameClock.day, cell) + maxi(data.fertility_bonus, 0)

func harvest_cell(cell: Vector2i) -> Dictionary:
	if not can_harvest(cell):
		return {}

	var data := get_cell(cell)
	var harvested_crop := data.crop
	var amount := get_harvest_amount(cell)
	if amount <= 0:
		return {}

	if harvested_crop.regrows_after_harvest():
		data.ready_to_harvest = false
		data.growth_days_completed = maxi(harvested_crop.growth_days - harvested_crop.regrow_days, 0)
		data.crop_stage = maxi(harvested_crop.visual_stages - 1, 0)
	else:
		data.clear_crop()

	harvested_total += amount
	crop_harvested.emit(cell, harvested_crop, amount)
	cell_changed.emit(cell)
	queue_redraw()

	return {
		"crop": harvested_crop,
		"amount": amount,
		"regrowing": harvested_crop.regrows_after_harvest(),
	}

func can_plant_crop_now(crop: CropDefinition) -> bool:
	return crop != null and crop.can_grow_in_season(GameClock.season_index)

func get_crop_season_hint(crop: CropDefinition) -> String:
	if crop == null:
		return ""
	if crop.can_grow_in_season(GameClock.season_index):
		return ""
	return "%s cresce em: %s." % [crop.display_name, crop.get_season_names()]

func get_cell_hint(cell: Vector2i) -> String:
	var data := get_cell(cell)
	if data == null:
		return ""
	if not data.tilled:
		return "Use a enxada primeiro."
	if data.crop == null:
		if data.fertility_bonus > 0:
			return "Solo adubado · selecione uma semente."
		return "Selecione uma semente na hotbar."
	if data.ready_to_harvest:
		return "Pronto para colher."
	if not data.watered_today:
		return "A planta precisa de agua hoje."
	return "%s esta crescendo." % data.crop.display_name

func _on_season_changed(_year: int, new_season: int) -> void:
	var withered := 0

	for key in _cells.keys():
		var cell: Vector2i = key
		var data := _cells[key] as FarmCellData
		if data == null or data.crop == null:
			continue

		if data.crop.can_grow_in_season(new_season):
			continue

		data.clear_crop()
		withered += 1
		cell_changed.emit(cell)

	if withered > 0:
		crops_withered.emit(withered)
		queue_redraw()

func _on_day_started(_day: int) -> void:
	_apply_current_weather()

func _apply_current_weather() -> void:
	if not WeatherManager.is_raining():
		return

	var changed := false
	for key in _cells.keys():
		var cell: Vector2i = key
		var data := _cells[key] as FarmCellData
		if data == null or not data.tilled or data.watered_today:
			continue

		data.watered_today = true
		changed = true
		cell_changed.emit(cell)

	if changed:
		queue_redraw()

func _on_day_ended(_day: int) -> void:
	for key in _cells.keys():
		var cell: Vector2i = key
		var data := _cells[key] as FarmCellData
		if data == null:
			continue

		if data.crop != null and data.watered_today and not data.ready_to_harvest:
			data.growth_days_completed += 1
			var progress := float(data.growth_days_completed) / float(maxi(data.crop.growth_days, 1))
			data.crop_stage = mini(
				floori(progress * float(data.crop.visual_stages)),
				data.crop.visual_stages
			)
			if data.growth_days_completed >= data.crop.growth_days:
				data.ready_to_harvest = true
				data.crop_stage = data.crop.visual_stages

		data.watered_today = false
		cell_changed.emit(cell)

	queue_redraw()

func _draw() -> void:
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var cell := Vector2i(x, y)
			var rect := Rect2(
				Vector2(x * cell_size, y * cell_size),
				Vector2(cell_size, cell_size)
			)
			var data := get_cell(cell)
			if data == null:
				continue

			var source_texture := SOIL_ATLAS if data.tilled else GRASS_ATLAS
			var source_rect := SOIL_SOURCE if data.tilled else GRASS_SOURCE
			draw_texture_rect_region(source_texture, rect, source_rect)

			if data.watered_today:
				draw_rect(rect, Color(0.05, 0.10, 0.14, 0.28), true)

			if data.fertility_bonus > 0:
				var center := rect.get_center()
				draw_circle(center + Vector2(-7, 6), 2.0, Color(0.64, 0.44, 0.23, 0.90))
				draw_circle(center + Vector2(5, 8), 2.0, Color(0.64, 0.44, 0.23, 0.90))
				draw_circle(center + Vector2(1, -7), 1.6, Color(0.72, 0.50, 0.28, 0.85))

			draw_rect(rect, Color(0.08, 0.12, 0.08, 0.24), false, 1.0)

			if data.crop != null:
				_draw_crop(rect.get_center(), data)

func _draw_crop(center: Vector2, data: FarmCellData) -> void:
	var crop := data.crop
	if crop == null:
		return

	var atlas_columns := 5
	var stage := clampi(data.crop_stage, 0, atlas_columns - 1)
	var source_rect := Rect2(
		Vector2(stage * 16, crop.sprite_row * 16),
		Vector2(16, 16)
	)
	var destination_rect := Rect2(
		center - Vector2(16, 16),
		Vector2(32, 32)
	)

	draw_texture_rect_region(CROP_ATLAS, destination_rect, source_rect)

	if data.ready_to_harvest:
		draw_arc(center, 14.0, 0.0, TAU, 24, Color(1.0, 0.92, 0.42, 0.7), 1.5)

func get_save_data() -> Dictionary:
	var saved_cells: Array = []

	for key in _cells.keys():
		var cell: Vector2i = key
		var data := _cells[key] as FarmCellData
		if data == null:
			continue

		saved_cells.append({
			"x": cell.x,
			"y": cell.y,
			"tilled": data.tilled,
			"watered_today": data.watered_today,
			"crop_id": String(data.crop.id) if data.crop != null else "",
			"growth_days_completed": data.growth_days_completed,
			"crop_stage": data.crop_stage,
			"ready_to_harvest": data.ready_to_harvest,
			"fertility_bonus": data.fertility_bonus,
		})

	return {
		"harvested_total": harvested_total,
		"cells": saved_cells,
	}

func load_save_data(data: Dictionary) -> void:
	_cells.clear()
	harvested_total = int(data.get("harvested_total", 0))

	var saved_cells: Array = data.get("cells", [])
	for entry_variant in saved_cells:
		if not (entry_variant is Dictionary):
			continue

		var entry := entry_variant as Dictionary
		var cell := Vector2i(int(entry.get("x", -1)), int(entry.get("y", -1)))
		if not is_valid_cell(cell):
			continue

		var cell_data := get_cell(cell)
		if cell_data == null:
			continue

		cell_data.tilled = bool(entry.get("tilled", false))
		cell_data.watered_today = bool(entry.get("watered_today", false))
		cell_data.growth_days_completed = int(entry.get("growth_days_completed", 0))
		cell_data.crop_stage = int(entry.get("crop_stage", 0))
		cell_data.ready_to_harvest = bool(entry.get("ready_to_harvest", false))
		cell_data.fertility_bonus = int(entry.get("fertility_bonus", 0))

		var crop_id := StringName(str(entry.get("crop_id", "")))
		if crop_id != &"":
			cell_data.crop = _load_crop_definition(crop_id)

	queue_redraw()

func _load_crop_definition(crop_id: StringName) -> CropDefinition:
	var path := "res://resources/crops/%s.tres" % String(crop_id)
	if not ResourceLoader.exists(path):
		return null
	return load(path) as CropDefinition
