class_name ShippingBin
extends Node2D

@export var interaction_radius: float = 58.0

func _ready() -> void:
	add_to_group("shipping_bin")
	queue_redraw()

func can_interact(player_position: Vector2) -> bool:
	return global_position.distance_to(player_position) <= interaction_radius

func interact(player: PlayerController) -> String:
	if player == null or not can_interact(player.global_position):
		return ""

	var stack := player.inventory.get_selected_stack()
	if stack == null or stack.is_empty():
		return "Caixa de remessa: selecione algo vendavel."

	var item := stack.item
	if item == null or item.sell_price <= 0:
		return "%s nao pode ser enviado para venda." % player.get_selected_item_name()

	var amount := stack.amount
	var value := amount * item.sell_price

	if not player.inventory.remove_item(item.id, amount):
		return "Nao foi possivel retirar os itens do inventario."

	if not Economy.queue_shipment(item, amount):
		player.inventory.add_item(item, amount)
		return "Nao foi possivel registrar a remessa."

	return "Enviado: %s x%d · %dg amanha." % [item.display_name, amount, value]

func _draw() -> void:
	draw_rect(Rect2(-25, -19, 50, 38), Color(0.34, 0.20, 0.10), true)
	draw_rect(Rect2(-22, -16, 44, 30), Color(0.56, 0.34, 0.16), true)
	draw_rect(Rect2(-27, -23, 54, 8), Color(0.68, 0.43, 0.20), true)
	draw_rect(Rect2(-12, -6, 24, 4), Color(0.16, 0.10, 0.06), true)
	draw_circle(Vector2(28, -27), 8.0, Color(0.96, 0.80, 0.28, 0.95))
	draw_string(ThemeDB.fallback_font, Vector2(25, -23), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.12, 0.10, 0.06))
