class_name ToolController
extends Node

signal tool_changed(tool: int)
signal charge_started
signal charge_stage_changed(stage: int)
signal charge_released(tool: int, stage: int)
signal water_changed(current: int, maximum: int)

enum ToolType {
	HOE,
	WATERING_CAN,
	AXE,
	PICKAXE,
}

const CHARGE_THRESHOLDS := [0.0, 0.45, 0.90, 1.35, 1.80, 2.25]
const WATER_CAPACITY_BY_LEVEL := [40, 55, 70, 85, 100, 130]
const WATER_COST_BY_STAGE := [1, 2, 3, 4, 5, 6]

@export_range(0, 5, 1) var hoe_level: int = 0
@export_range(0, 5, 1) var watering_can_level: int = 0
@export_range(0, 5, 1) var axe_level: int = 0
@export_range(0, 5, 1) var pickaxe_level: int = 0

var selected_tool: int = ToolType.HOE
var is_charging: bool = false
var charge_elapsed: float = 0.0
var charge_stage: int = 0
var current_water: int = 0

func _ready() -> void:
	current_water = get_water_capacity()
	water_changed.emit(current_water, get_water_capacity())

func select_tool(tool: int) -> void:
	if is_charging:
		cancel_charge()
	if selected_tool == tool:
		return
	selected_tool = tool
	tool_changed.emit(selected_tool)

func is_chargeable_tool(tool: int = selected_tool) -> bool:
	return tool in [ToolType.HOE, ToolType.WATERING_CAN]

func begin_charge() -> void:
	if is_charging or not is_chargeable_tool():
		return
	is_charging = true
	charge_elapsed = 0.0
	charge_stage = 0
	charge_started.emit()
	charge_stage_changed.emit(charge_stage)

func update_charge(delta: float) -> void:
	if not is_charging:
		return

	charge_elapsed += delta
	var next_stage := _stage_for_elapsed(charge_elapsed)
	if next_stage == charge_stage:
		return

	charge_stage = next_stage
	charge_stage_changed.emit(charge_stage)

func release_charge() -> Dictionary:
	if not is_charging:
		return {}

	var result := {
		"tool": selected_tool,
		"stage": charge_stage,
		"held_seconds": charge_elapsed,
	}

	is_charging = false
	charge_elapsed = 0.0
	charge_stage = 0
	charge_released.emit(int(result["tool"]), int(result["stage"]))
	return result

func cancel_charge() -> void:
	is_charging = false
	charge_elapsed = 0.0
	charge_stage = 0

func get_tool_level(tool: int = selected_tool) -> int:
	match tool:
		ToolType.HOE:
			return hoe_level
		ToolType.WATERING_CAN:
			return watering_can_level
		ToolType.AXE:
			return axe_level
		ToolType.PICKAXE:
			return pickaxe_level
		_:
			return 0

func get_max_charge_stage() -> int:
	if not is_chargeable_tool():
		return 0
	return get_tool_level()

func get_energy_cost(stage: int = 0, tool: int = selected_tool) -> float:
	match tool:
		ToolType.HOE:
			return 2.0
		ToolType.WATERING_CAN:
			return 2.0 + float(clampi(stage, 0, 5)) * 2.0
		ToolType.AXE, ToolType.PICKAXE:
			return 2.0
		_:
			return 0.0

func get_water_capacity() -> int:
	return WATER_CAPACITY_BY_LEVEL[clampi(watering_can_level, 0, 5)]

func get_water_cost(stage: int) -> int:
	return WATER_COST_BY_STAGE[clampi(stage, 0, 5)]

func can_spend_water(stage: int) -> bool:
	return current_water >= get_water_cost(stage)

func spend_water(stage: int) -> bool:
	var cost := get_water_cost(stage)
	if current_water < cost:
		return false

	current_water -= cost
	water_changed.emit(current_water, get_water_capacity())
	return true

func refill_water() -> void:
	current_water = get_water_capacity()
	water_changed.emit(current_water, get_water_capacity())

func get_tool_name() -> String:
	match selected_tool:
		ToolType.HOE:
			return "Enxada"
		ToolType.WATERING_CAN:
			return "Regador"
		ToolType.AXE:
			return "Machado"
		ToolType.PICKAXE:
			return "Picareta"
		_:
			return "Ferramenta"

func _stage_for_elapsed(elapsed: float) -> int:
	var maximum := get_max_charge_stage()
	var result := 0

	for stage in range(1, maximum + 1):
		if elapsed >= CHARGE_THRESHOLDS[stage]:
			result = stage
		else:
			break

	return result

func get_save_data() -> Dictionary:
	return {
		"hoe_level": hoe_level,
		"watering_can_level": watering_can_level,
		"axe_level": axe_level,
		"pickaxe_level": pickaxe_level,
		"current_water": current_water,
	}

func load_save_data(data: Dictionary) -> void:
	hoe_level = clampi(int(data.get("hoe_level", hoe_level)), 0, 5)
	watering_can_level = clampi(int(data.get("watering_can_level", watering_can_level)), 0, 5)
	axe_level = clampi(int(data.get("axe_level", axe_level)), 0, 5)
	pickaxe_level = clampi(int(data.get("pickaxe_level", pickaxe_level)), 0, 5)
	current_water = clampi(int(data.get("current_water", get_water_capacity())), 0, get_water_capacity())
	water_changed.emit(current_water, get_water_capacity())
