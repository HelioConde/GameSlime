class_name SeedShop
extends Node2D

@export var interaction_radius: float = 58.0
@export var spring_seed_item: ItemDefinition
@export var summer_seed_item: ItemDefinition
@export var fall_seed_item: ItemDefinition
@export var winter_seed_item: ItemDefinition

func _ready() -> void:
	add_to_group("seed_shop")
	GameClock.season_changed.connect(_on_season_changed)
	queue_redraw()

func can_interact(player_position: Vector2) -> bool:
	return global_position.distance_to(player_position) <= interaction_radius

func interact(player: PlayerController) -> String:
	if player == null or not can_interact(player.global_position):
		return ""

	var seed_item := _get_current_seed()
	if seed_item == null or seed_item.buy_price <= 0:
		return "A banca ainda nao tem sementes para esta estacao."

	var price := seed_item.buy_price
	if not Economy.can_afford(price):
		return "%s: %dg · voce tem %dg." % [
			seed_item.display_name,
			price,
			Economy.gold,
		]

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

func get_current_offer_text() -> String:
	var seed_item := _get_current_seed()
	if seed_item == null:
		return "Sem oferta"
	return "%s · %dg" % [seed_item.display_name, seed_item.buy_price]

func _get_current_seed() -> ItemDefinition:
	match GameClock.season_index:
		GameClock.Season.SPRING:
			return spring_seed_item
		GameClock.Season.SUMMER:
			return summer_seed_item
		GameClock.Season.FALL:
			return fall_seed_item
		GameClock.Season.WINTER:
			return winter_seed_item
		_:
			return spring_seed_item

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
