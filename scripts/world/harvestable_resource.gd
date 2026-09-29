class_name HarvestableResource
extends Node2D

signal resource_hit(resource: HarvestableResource, remaining_hits: int)
signal resource_depleted(resource: HarvestableResource)

enum ResourceKind {
	TREE,
	ROCK,
}

const TREE_HITS_BY_LEVEL := [10, 8, 6, 4, 2, 1]
const ROCK_HITS_BY_LEVEL := [5, 4, 3, 2, 1, 1]
const DROP_SCENE := preload("res://scenes/world/item_drop.tscn")

@export var resource_kind: ResourceKind = ResourceKind.TREE
@export var required_tool_type: int = ToolController.ToolType.AXE
@export_range(0, 5, 1) var minimum_tool_level: int = 0
@export var drop_item_id: StringName = &"wood"
@export_range(1, 99, 1) var drop_amount: int = 5
@export var drop_tint: Color = Color(0.65, 0.39, 0.20)
@export var hit_radius: float = 30.0

var _hits_taken: int = 0
var _required_hits: int = 1
var _hit_flash: float = 0.0

func _ready() -> void:
	add_to_group("harvestable_resource")
	queue_redraw()

func _process(delta: float) -> void:
	if _hit_flash > 0.0:
		_hit_flash -= delta
		queue_redraw()

func can_be_hit_by(tool_type: int, tool_level: int) -> bool:
	return tool_type == required_tool_type and tool_level >= minimum_tool_level

func apply_tool_hit(tool_type: int, tool_level: int) -> Dictionary:
	if not can_be_hit_by(tool_type, tool_level):
		return {
			"success": false,
			"reason": "Ferramenta inadequada ou nivel insuficiente.",
		}

	_required_hits = _calculate_required_hits(tool_level)
	_hits_taken += 1
	_hit_flash = 0.12

	var remaining := maxi(_required_hits - _hits_taken, 0)
	resource_hit.emit(self, remaining)
	queue_redraw()

	if _hits_taken >= _required_hits:
		_spawn_drop()
		resource_depleted.emit(self)
		queue_free()

	return {
		"success": true,
		"depleted": remaining <= 0,
		"remaining_hits": remaining,
	}

func _calculate_required_hits(tool_level: int) -> int:
	var level := clampi(tool_level, 0, 5)
	match resource_kind:
		ResourceKind.TREE:
			return TREE_HITS_BY_LEVEL[level]
		ResourceKind.ROCK:
			return ROCK_HITS_BY_LEVEL[level]
		_:
			return 1

func _spawn_drop() -> void:
	var drop := DROP_SCENE.instantiate() as ItemDrop
	if drop == null:
		return

	get_parent().call_deferred("add_child", drop)
	drop.global_position = global_position + Vector2(0, 12)
	drop.configure(drop_item_id, drop_amount, drop_tint)

func _draw() -> void:
	var flash := 0.28 if _hit_flash > 0.0 else 0.0

	match resource_kind:
		ResourceKind.TREE:
			draw_rect(Rect2(-6, -4, 12, 30), Color(0.37, 0.20, 0.10).lightened(flash), true)
			draw_circle(Vector2(0, -20), 24.0, Color(0.17, 0.52, 0.22).lightened(flash))
			draw_circle(Vector2(-14, -14), 16.0, Color(0.20, 0.61, 0.27).lightened(flash))
			draw_circle(Vector2(14, -14), 16.0, Color(0.20, 0.61, 0.27).lightened(flash))
		ResourceKind.ROCK:
			var color := Color(0.45, 0.48, 0.51).lightened(flash)
			draw_colored_polygon(
				PackedVector2Array([
					Vector2(-20, 10),
					Vector2(-15, -10),
					Vector2(-3, -20),
					Vector2(17, -12),
					Vector2(22, 8),
					Vector2(8, 18),
					Vector2(-10, 17),
				]),
				color
			)
