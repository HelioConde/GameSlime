class_name StorageNetwork
extends Node

signal item_changed(item_id: StringName, total_amount: int)

var _items: Dictionary = {}

func deposit(item_id: StringName, amount: int) -> int:
	if amount <= 0:
		return get_amount(item_id)

	_items[item_id] = get_amount(item_id) + amount
	item_changed.emit(item_id, _items[item_id])
	return _items[item_id]

func can_withdraw(item_id: StringName, amount: int) -> bool:
	return amount >= 0 and get_amount(item_id) >= amount

func withdraw(item_id: StringName, amount: int) -> bool:
	if amount <= 0 or not can_withdraw(item_id, amount):
		return false

	_items[item_id] = get_amount(item_id) - amount
	item_changed.emit(item_id, _items[item_id])
	return true

func get_amount(item_id: StringName) -> int:
	return int(_items.get(item_id, 0))

func snapshot() -> Dictionary:
	return _items.duplicate(true)
