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
	var iron_cost := int(cost.get("iron", 0))
	var silver_cost := int(cost.get("silver", 0))
	var gold_ore_cost := int(cost.get("gold_ore", 0))
	var crystal_cost := int(cost.get("slime_crystal", 0))

	var copper_owned := player.inventory.count_item(&"copper_ore")
	var iron_owned := player.inventory.count_item(&"iron_ore")
	var silver_owned := player.inventory.count_item(&"silver_ore")
	var gold_ore_owned := player.inventory.count_item(&"gold_ore")
	var crystal_owned := player.inventory.count_item(&"slime_crystal")

	if (
		Economy.gold < gold_cost
		or copper_owned < copper_cost
		or iron_owned < iron_cost
		or silver_owned < silver_cost
		or gold_ore_owned < gold_ore_cost
		or crystal_owned < crystal_cost
	):
		return "Upgrade Nv.%d -> %d: %dg + %d Cobre + %d Ferro + %d Prata + %d Ouro + %d Cristal. Voce tem %dg + %d + %d + %d + %d + %d." % [
			current_level,
			current_level + 1,
			gold_cost,
			copper_cost,
			iron_cost,
			silver_cost,
			gold_ore_cost,
			crystal_cost,
			Economy.gold,
			copper_owned,
			iron_owned,
			silver_owned,
			gold_ore_owned,
			crystal_owned,
		]

	if not player.inventory.remove_item(&"copper_ore", copper_cost):
		return "Falha ao consumir Minerio de Cobre."

	if not player.inventory.remove_item(&"iron_ore", iron_cost):
		_refund_materials(player, copper_cost, 0, 0, 0, 0)
		return "Falha ao consumir Minerio de Ferro."

	if not player.inventory.remove_item(&"silver_ore", silver_cost):
		_refund_materials(player, copper_cost, iron_cost, 0, 0, 0)
		return "Falha ao consumir Minerio de Prata."

	if not player.inventory.remove_item(&"gold_ore", gold_ore_cost):
		_refund_materials(player, copper_cost, iron_cost, silver_cost, 0, 0)
		return "Falha ao consumir Minerio de Ouro."

	if not player.inventory.remove_item(&"slime_crystal", crystal_cost):
		_refund_materials(player, copper_cost, iron_cost, silver_cost, gold_ore_cost, 0)
		return "Falha ao consumir Cristal de Slime."

	if not Economy.spend_gold(gold_cost):
		_refund_materials(player, copper_cost, iron_cost, silver_cost, gold_ore_cost, crystal_cost)
		return "Ouro insuficiente."

	if not player.tools.upgrade_tool(tool_type):
		Economy.add_gold(gold_cost)
		_refund_materials(player, copper_cost, iron_cost, silver_cost, gold_ore_cost, crystal_cost)
		return "Nao foi possivel melhorar a ferramenta."

	Sfx.play_cue(&"upgrade")
	return "%s melhorada para nivel %d!" % [
		player.tools.get_tool_display_name(tool_type),
		player.tools.get_tool_level(tool_type),
	]

func _refund_materials(
	player: PlayerController,
	copper: int,
	iron: int,
	silver: int,
	gold_ore: int,
	crystals: int
) -> void:
	if copper > 0:
		player.inventory.add_item(player.copper_ore_item, copper)
	if iron > 0:
		player.inventory.add_item(player.iron_ore_item, iron)
	if silver > 0:
		player.inventory.add_item(player.silver_ore_item, silver)
	if gold_ore > 0:
		player.inventory.add_item(player.gold_ore_item, gold_ore)
	if crystals > 0:
		player.inventory.add_item(player.slime_crystal_item, crystals)

func _draw() -> void:
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
