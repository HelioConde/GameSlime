class_name FarmCellData
extends RefCounted

var tilled: bool = false
var watered_today: bool = false
var crop: CropDefinition
var growth_days_completed: int = 0
var crop_stage: int = 0
var ready_to_harvest: bool = false
var fertility_bonus: int = 0

func clear_crop() -> void:
	crop = null
	growth_days_completed = 0
	crop_stage = 0
	ready_to_harvest = false
	fertility_bonus = 0
