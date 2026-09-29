class_name CropDefinition
extends Resource

@export var id: StringName = &"starter_turnip"
@export var display_name: String = "Nabo do Vale"
@export_range(1, 28, 1) var growth_days: int = 4
@export_range(2, 8, 1) var visual_stages: int = 4
@export var sell_value: int = 35
@export var crop_color: Color = Color(0.62, 0.88, 0.42)
@export var harvest_item_id: StringName = &"starter_turnip"
