class_name ToolUpgradeStation
extends Node2D

@export var interaction_radius: float = 64.0

func _ready() -> void:
	add_to_group("tool_upgrade_station")
	queue_redraw()

func can_interact(player_position: Vector2) -> bool:
	return global_position.distance_to(player_position) <= interaction_radius

func interact(player: PlayerController) -> String:
	if player == null or not can_interact(player.global_position):
		return ""

	var selected := player.inventory.get_selected_stack()
	if selected == null or selected.is_empty():
		return "Selecione uma ferramenta para melhorar."

	if selected.item.kind != ItemDefinition.ItemKind.TOOL:
		return "Selecione Enxada, Regador, Machado ou Picareta."

	var tool_type := selected.item.tool_type
	var current_level := player.tools.get_tool_level(tool_type)

	if not player.tools.can_upgrade_tool(tool_type):
		return "%s ja esta no nivel maximo." % player.tools.get_tool_display_name(tool_type)

	var cost := player.tools.get_upgrade_cost(tool_type)
	var wood_cost := int(cost.get("wood", 0))
	var stone_cost := int(cost.get("stone", 0))
	var wood_owned := player.inventory.count_item(&"wood")
	var stone_owned := player.inventory.count_item(&"stone")

	if wood_owned < wood_cost or stone_owned < stone_cost:
		return "Upgrade Nv.%d -> %d: precisa %d Madeira + %d Pedra. Voce tem %d + %d." % [
			current_level,
			current_level + 1,
			wood_cost,
			stone_cost,
			wood_owned,
			stone_owned,
		]

	if not player.inventory.remove_item(&"wood", wood_cost):
		return "Falha ao consumir Madeira."

	if not player.inventory.remove_item(&"stone", stone_cost):
		player.inventory.add_item(player.wood_item, wood_cost)
		return "Falha ao consumir Pedra."

	if not player.tools.upgrade_tool(tool_type):
		player.inventory.add_item(player.wood_item, wood_cost)
		player.inventory.add_item(player.stone_item, stone_cost)
		return "Nao foi possivel melhorar a ferramenta."

	return "%s melhorada para nivel %d!" % [
		player.tools.get_tool_display_name(tool_type),
		player.tools.get_tool_level(tool_type),
	]

func _draw() -> void:
	draw_rect(Rect2(-24, -14, 48, 28), Color(0.38, 0.22, 0.12), true)
	draw_rect(Rect2(-20, -10, 40, 9), Color(0.66, 0.42, 0.22), true)
	draw_line(Vector2(-16, 0), Vector2(-16, 17), Color(0.24, 0.14, 0.08), 5.0)
	draw_line(Vector2(16, 0), Vector2(16, 17), Color(0.24, 0.14, 0.08), 5.0)
	draw_circle(Vector2(0, -15), 6.0, Color(0.63, 0.66, 0.70))
	draw_line(Vector2(-5, -19), Vector2(8, -8), Color(0.83, 0.86, 0.89), 3.0)
