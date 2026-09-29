class_name ItemDrop
extends Node2D

@export var item_id: StringName
@export_range(1, 999, 1) var amount: int = 1
@export var pickup_radius: float = 30.0
@export var tint: Color = Color.WHITE
@export var pickup_delay: float = 0.35

var quality: int = InventorySlotData.Quality.NORMAL
var natural_spawn: bool = false
var spawned_day: int = -1
var expires_after_days: int = 0

var _bob_time: float = 0.0
var _age: float = 0.0

func _ready() -> void:
	add_to_group("world_drop")
	queue_redraw()

func _process(delta: float) -> void:
	_bob_time += delta
	_age += delta
	queue_redraw()

func configure(
	new_item_id: StringName,
	new_amount: int,
	new_tint: Color,
	new_quality: int = InventorySlotData.Quality.NORMAL
) -> void:
	item_id = new_item_id
	amount = maxi(new_amount, 1)
	tint = new_tint
	quality = InventorySlotData.clamp_quality(new_quality)
	queue_redraw()

func configure_natural_spawn(day: int, lifetime_days: int) -> void:
	natural_spawn = true
	spawned_day = day
	expires_after_days = maxi(lifetime_days, 1)
	add_to_group("daily_world_spawn")

func is_natural_spawn_expired(current_day: int) -> bool:
	if not natural_spawn or spawned_day < 0 or expires_after_days <= 0:
		return false
	return current_day - spawned_day >= expires_after_days

func can_pickup(player_position: Vector2) -> bool:
	return (
		_age >= pickup_delay
		and global_position.distance_to(player_position) <= pickup_radius
	)

func try_collect(inventory: InventoryComponent) -> int:
	if inventory == null or amount <= 0:
		return 0

	var definition := inventory.get_definition(item_id)
	if definition == null:
		return 0

	var before := amount
	amount = inventory.add_item(definition, amount, quality)
	var collected := before - amount

	if amount <= 0:
		queue_free()
	else:
		queue_redraw()

	return collected

func _draw() -> void:
	var bob := sin(_bob_time * 3.0) * 2.0
	draw_circle(Vector2(0, bob), 7.0, tint)
	draw_circle(Vector2(0, bob), 3.0, tint.lightened(0.35))

	var outline := Color(0.05, 0.07, 0.06, 0.75)
	var width := 1.5
	if quality == InventorySlotData.Quality.SILVER:
		outline = Color(0.78, 0.84, 0.90, 0.95)
		width = 2.0
	elif quality == InventorySlotData.Quality.GOLD:
		outline = Color(1.0, 0.82, 0.28, 0.98)
		width = 2.5

	draw_arc(Vector2(0, bob), 8.0, 0.0, TAU, 20, outline, width)
