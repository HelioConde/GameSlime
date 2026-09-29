class_name ItemDrop
extends Node2D

@export var item_id: StringName
@export_range(1, 999, 1) var amount: int = 1
@export var pickup_radius: float = 30.0
@export var tint: Color = Color.WHITE

var _bob_time: float = 0.0

func _ready() -> void:
	add_to_group("world_drop")
	queue_redraw()

func _process(delta: float) -> void:
	_bob_time += delta
	queue_redraw()

func configure(new_item_id: StringName, new_amount: int, new_tint: Color) -> void:
	item_id = new_item_id
	amount = maxi(new_amount, 1)
	tint = new_tint
	queue_redraw()

func can_pickup(player_position: Vector2) -> bool:
	return global_position.distance_to(player_position) <= pickup_radius

func try_collect(inventory: InventoryComponent) -> int:
	if inventory == null or amount <= 0:
		return 0

	var definition := inventory.get_definition(item_id)
	if definition == null:
		return 0

	var before := amount
	amount = inventory.add_item(definition, amount)
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
	draw_arc(Vector2(0, bob), 8.0, 0.0, TAU, 20, Color(0.05, 0.07, 0.06, 0.75), 1.5)
