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
		return "Ferreiro: selecione uma ferramenta para melhorar."

	if selected.item.kind != ItemDefinition.ItemKind.TOOL:
		return "Ferreiro: selecione Enxada, Regador, Machado ou Picareta."

	var tool_type := selected.item.tool_type
	var current_level := player.tools.get_tool_level(tool_type)

	if not player.tools.can_upgrade_tool(tool_type):
		return "%s ja esta no nivel maximo." % player.tools.get_tool_display_name(tool_type)

	var cost := player.tools.get_upgrade_cost(tool_type)
	var gold_cost := int(cost.get("gold", 0))
	var copper_cost := int(cost.get("copper", 0))
	var copper_owned := player.inventory.count_item(&"copper_ore")

	if Economy.gold < gold_cost or copper_owned < copper_cost:
		return "Upgrade Nv.%d -> %d: %dg + %d Cobre. Voce tem %dg + %d." % [
			current_level,
			current_level + 1,
			gold_cost,
			copper_cost,
			Economy.gold,
			copper_owned,
		]

	if not player.inventory.remove_item(&"copper_ore", copper_cost):
		return "Falha ao consumir Minerio de Cobre."

	if not Economy.spend_gold(gold_cost):
		player.inventory.add_item(player.copper_ore_item, copper_cost)
		return "Ouro insuficiente."

	if not player.tools.upgrade_tool(tool_type):
		Economy.add_gold(gold_cost)
		player.inventory.add_item(player.copper_ore_item, copper_cost)
		return "Nao foi possivel melhorar a ferramenta."

	return "%s melhorada para nivel %d por %dg + %d Cobre!" % [
		player.tools.get_tool_display_name(tool_type),
		player.tools.get_tool_level(tool_type),
		gold_cost,
		copper_cost,
	]

func _draw() -> void:
	# Small anvil / smithing station.
	draw_rect(Rect2(-26, -8, 52, 16), Color(0.29, 0.31, 0.34), true)
	draw_rect(Rect2(-18, 8, 36, 8), Color(0.20, 0.21, 0.23), true)
	draw_rect(Rect2(-11, 16, 22, 10), Color(0.16, 0.17, 0.19), true)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-28, -8),
			Vector2(-15, -19),
			Vector2(20, -19),
			Vector2(28, -8),
		]),
		Color(0.48, 0.50, 0.54)
	)
	draw_circle(Vector2(29, -29), 8.0, Color(0.96, 0.80, 0.28, 0.95))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(26, -25),
		"E",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		10,
		Color(0.12, 0.10, 0.06)
	)
