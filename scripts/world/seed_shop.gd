class_name SeedShop
extends Node2D

@export var interaction_radius: float = 58.0
@export var seed_item: ItemDefinition

func _ready() -> void:
	add_to_group("seed_shop")
	queue_redraw()

func can_interact(player_position: Vector2) -> bool:
	return global_position.distance_to(player_position) <= interaction_radius

func interact(player: PlayerController) -> String:
	if player == null or not can_interact(player.global_position):
		return ""
	if seed_item == null or seed_item.buy_price <= 0:
		return "A banca ainda nao tem sementes disponiveis."

	var price := seed_item.buy_price
	if not Economy.can_afford(price):
		return "Semente de Nabo: %dg · voce tem %dg." % [price, Economy.gold]

	if not player.inventory.can_add_item(seed_item, 1):
		return "Inventario cheio."

	if not Economy.spend_gold(price):
		return "Ouro insuficiente."

	var remaining := player.inventory.add_item(seed_item, 1)
	if remaining > 0:
		Economy.add_gold(price)
		return "Nao foi possivel guardar a semente."

	return "Comprou %s por %dg. Saldo: %dg." % [
		seed_item.display_name,
		price,
		Economy.gold,
	]

func _draw() -> void:
	draw_rect(Rect2(-30, -18, 60, 36), Color(0.56, 0.35, 0.15), true)
	draw_rect(Rect2(-34, -25, 68, 10), Color(0.76, 0.54, 0.24), true)
	draw_circle(Vector2(-12, -3), 6.0, Color(0.74, 0.80, 0.28))
	draw_circle(Vector2(0, -4), 6.0, Color(0.62, 0.76, 0.24))
	draw_circle(Vector2(12, -3), 6.0, Color(0.82, 0.70, 0.26))
	draw_circle(Vector2(34, -29), 8.0, Color(0.96, 0.80, 0.28, 0.95))
	draw_string(ThemeDB.fallback_font, Vector2(31, -25), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.12, 0.10, 0.06))
