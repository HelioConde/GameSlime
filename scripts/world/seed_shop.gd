class_name SeedShop
extends Node2D

@export var interaction_radius: float = 58.0
@export var spring_seed_items: Array[ItemDefinition] = []
@export var summer_seed_items: Array[ItemDefinition] = []
@export var fall_seed_items: Array[ItemDefinition] = []
@export var winter_seed_items: Array[ItemDefinition] = []
@export var always_available_items: Array[ItemDefinition] = []

func _ready() -> void:
	add_to_group("seed_shop")
	GameClock.season_changed.connect(_on_season_changed)
	queue_redraw()

func can_interact(player_position: Vector2) -> bool:
	return global_position.distance_to(player_position) <= interaction_radius

func get_current_offers() -> Array[ItemDefinition]:
	var offers: Array[ItemDefinition] = []
	match GameClock.season_index:
		GameClock.Season.SPRING:
			offers.append_array(spring_seed_items)
		GameClock.Season.SUMMER:
			offers.append_array(summer_seed_items)
		GameClock.Season.FALL:
			offers.append_array(fall_seed_items)
		GameClock.Season.WINTER:
			offers.append_array(winter_seed_items)
		_:
			offers.append_array(spring_seed_items)

	offers.append_array(always_available_items)
	return offers

func purchase(player: PlayerController, item_id: StringName, amount: int = 1) -> String:
	if player == null or amount <= 0:
		return "Compra invalida."

	var seed_item := _find_offer(item_id)
	if seed_item == null:
		return "Esse item nao esta disponivel nesta estacao."
	if seed_item.buy_price <= 0:
		return "%s ainda nao possui preco de compra." % seed_item.display_name

	var total_price := seed_item.buy_price * amount
	if not Economy.can_afford(total_price):
		return "%s x%d: %dg · voce tem %dg." % [
			seed_item.display_name,
			amount,
			total_price,
			Economy.gold,
		]

	if not player.inventory.can_add_item(seed_item, amount):
		return "Inventario sem espaco para %d itens." % amount

	if not Economy.spend_gold(total_price):
		return "Ouro insuficiente."

	var remaining := player.inventory.add_item(seed_item, amount)
	if remaining > 0:
		Economy.add_gold(total_price)
		return "Nao foi possivel guardar a compra."

	return "Comprou %s x%d por %dg. Saldo: %dg." % [
		seed_item.display_name,
		amount,
		total_price,
		Economy.gold,
	]

func _find_offer(item_id: StringName) -> ItemDefinition:
	for item in get_current_offers():
		if item != null and item.id == item_id:
			return item
	return null

func _on_season_changed(_year: int, _season: int) -> void:
	queue_redraw()

func _draw() -> void:
	var season_color := Color(0.76, 0.54, 0.24)
	match GameClock.season_index:
		GameClock.Season.SPRING:
			season_color = Color(0.58, 0.78, 0.30)
		GameClock.Season.SUMMER:
			season_color = Color(0.92, 0.66, 0.22)
		GameClock.Season.FALL:
			season_color = Color(0.88, 0.48, 0.20)
		GameClock.Season.WINTER:
			season_color = Color(0.62, 0.82, 0.96)

	draw_rect(Rect2(-30, -18, 60, 36), Color(0.56, 0.35, 0.15), true)
	draw_rect(Rect2(-34, -25, 68, 10), season_color, true)
	draw_circle(Vector2(-12, -3), 6.0, season_color.lightened(0.10))
	draw_circle(Vector2(0, -4), 6.0, season_color)
	draw_circle(Vector2(12, -3), 6.0, season_color.darkened(0.10))
	draw_circle(Vector2(34, -29), 8.0, Color(0.96, 0.80, 0.28, 0.95))
	draw_string(ThemeDB.fallback_font, Vector2(31, -25), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.12, 0.10, 0.06))
