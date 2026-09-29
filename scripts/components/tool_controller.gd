class_name ToolController
extends Node

signal tool_changed(tool: int)
signal charge_started
signal charge_stage_changed(stage: int)
signal charge_released(tool: int, stage: int)

enum ToolType {
	HOE,
	WATERING_CAN,
}

const CHARGE_THRESHOLDS := [0.0, 0.45, 0.90, 1.35, 1.80, 2.25]

@export_range(0, 5, 1) var hoe_level: int = 0
@export_range(0, 5, 1) var watering_can_level: int = 0

var selected_tool: int = ToolType.HOE
var is_charging: bool = false
var charge_elapsed: float = 0.0
var charge_stage: int = 0

func select_tool(tool: int) -> void:
	if is_charging:
		cancel_charge()
	if selected_tool == tool:
		return
	selected_tool = tool
	tool_changed.emit(selected_tool)

func begin_charge() -> void:
	if is_charging:
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

func get_max_charge_stage() -> int:
	match selected_tool:
		ToolType.HOE:
			return hoe_level
		ToolType.WATERING_CAN:
			return watering_can_level
		_:
			return 0

func get_energy_cost(stage: int) -> float:
	match selected_tool:
		ToolType.HOE:
			return 2.0
		ToolType.WATERING_CAN:
			return 2.0 + float(clampi(stage, 0, 5)) * 2.0
		_:
			return 0.0

func get_tool_name() -> String:
	match selected_tool:
		ToolType.HOE:
			return "Enxada"
		ToolType.WATERING_CAN:
			return "Regador"
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
