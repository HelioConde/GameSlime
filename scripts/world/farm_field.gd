class_name FarmField
extends Node2D

signal cell_changed(cell: Vector2i)
signal crop_planted(cell: Vector2i, crop: CropDefinition)
signal crop_harvested(cell: Vector2i, crop: CropDefinition, amount: int)

@export var grid_size: Vector2i = Vector2i(12, 8)
@export var cell_size: int = 32

var harvested_total: int = 0
var _cells: Dictionary = {}

func _ready() -> void:
	add_to_group("farm_field")
	GameClock.day_ended.connect(_on_day_ended)
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

func can_plant(cell: Vector2i) -> bool:
	var data := get_cell(cell)
	return data != null and data.tilled and data.crop == null

func plant_crop(cell: Vector2i, crop: CropDefinition) -> bool:
	if crop == null or not can_plant(cell):
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

func harvest_cell(cell: Vector2i) -> Dictionary:
	if not can_harvest(cell):
		return {}

	var data := get_cell(cell)
	var harvested_crop := data.crop
	var amount := 1

	data.clear_crop()
	harvested_total += amount
	crop_harvested.emit(cell, harvested_crop, amount)
	cell_changed.emit(cell)
	queue_redraw()

	return {
		"crop": harvested_crop,
		"amount": amount,
	}

func get_cell_hint(cell: Vector2i) -> String:
	var data := get_cell(cell)
	if data == null:
		return ""
	if not data.tilled:
		return "Use a enxada primeiro."
	if data.crop == null:
		return "Selecione uma semente na hotbar."
	if data.ready_to_harvest:
		return "Pronto para colher."
	if not data.watered_today:
		return "A planta precisa de agua hoje."
	return "%s esta crescendo." % data.crop.display_name

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

			var ground := Color(0.25, 0.47, 0.22, 1.0)
			if data.tilled:
				ground = Color(0.39, 0.25, 0.15, 1.0)
			if data.watered_today:
				ground = Color(0.25, 0.19, 0.16, 1.0)

			draw_rect(rect, ground)
			draw_rect(rect, Color(0.08, 0.12, 0.08, 0.24), false, 1.0)

			if data.crop != null:
				_draw_crop(rect.get_center(), data)

func _draw_crop(center: Vector2, data: FarmCellData) -> void:
	var crop := data.crop
	if crop == null:
		return

	var stage_ratio := float(data.crop_stage + 1) / float(crop.visual_stages + 1)
	var radius := lerpf(4.0, 11.0, stage_ratio)
	var color := crop.crop_color

	if data.ready_to_harvest:
		color = color.lightened(0.18)
		radius += 2.0

	draw_line(center + Vector2(0, 9), center + Vector2(0, -4), Color(0.16, 0.42, 0.18), 3.0)
	draw_circle(center + Vector2(0, -5), radius, color)
