class_name InventoryComponent
extends Node

signal inventory_changed
signal selected_slot_changed(index: int)

@export_range(1, 36, 1) var slot_count: int = 12
@export var catalog_items: Array[ItemDefinition] = []

var slots: Array[InventorySlotData] = []
var selected_slot: int = 0
var _catalog: Dictionary = {}

func _ready() -> void:
	for item in catalog_items:
		if item != null and item.id != &"":
			_catalog[item.id] = item

	for _index in range(slot_count):
		slots.append(InventorySlotData.new())

func register_definition(item: ItemDefinition) -> void:
	if item == null or item.id == &"":
		return
	_catalog[item.id] = item

func get_definition(item_id: StringName) -> ItemDefinition:
	return _catalog.get(item_id) as ItemDefinition

func set_selected_slot(index: int) -> void:
	if slots.is_empty():
		return

	var wrapped := posmod(index, slots.size())
	if selected_slot == wrapped:
		return

	selected_slot = wrapped
	selected_slot_changed.emit(selected_slot)

func get_selected_stack() -> InventorySlotData:
	if selected_slot < 0 or selected_slot >= slots.size():
		return null
	return slots[selected_slot]

func get_slot(index: int) -> InventorySlotData:
	if index < 0 or index >= slots.size():
		return null
	return slots[index]

func seed_slot(index: int, item: ItemDefinition, amount: int = 1) -> void:
	if item == null or index < 0 or index >= slots.size():
		return

	register_definition(item)
	var slot := slots[index]
	slot.item = item
	slot.amount = clampi(amount, 0, item.max_stack)

	if slot.amount <= 0:
		slot.clear()

	inventory_changed.emit()

func can_add_item(item: ItemDefinition, amount: int = 1) -> bool:
	if item == null or amount <= 0:
		return true

	var remaining := amount

	for slot in slots:
		if slot.is_empty():
			remaining -= mini(item.max_stack, remaining)
		elif slot.item.id == item.id:
			remaining -= mini(item.max_stack - slot.amount, remaining)

		if remaining <= 0:
			return true

	return false

func add_item(item: ItemDefinition, amount: int = 1) -> int:
	if item == null or amount <= 0:
		return amount

	register_definition(item)
	var remaining := amount

	for slot in slots:
		if slot.is_empty() or slot.item.id != item.id:
			continue

		var available := item.max_stack - slot.amount
		if available <= 0:
			continue

		var moved := mini(available, remaining)
		slot.amount += moved
		remaining -= moved

		if remaining <= 0:
			inventory_changed.emit()
			return 0

	for slot in slots:
		if not slot.is_empty():
			continue

		var moved := mini(item.max_stack, remaining)
		slot.item = item
		slot.amount = moved
		remaining -= moved

		if remaining <= 0:
			inventory_changed.emit()
			return 0

	inventory_changed.emit()
	return remaining

func remove_item(item_id: StringName, amount: int = 1) -> bool:
	if amount <= 0:
		return true
	if count_item(item_id) < amount:
		return false

	var remaining := amount

	for slot in slots:
		if slot.is_empty() or slot.item.id != item_id:
			continue

		var removed := mini(slot.amount, remaining)
		slot.amount -= removed
		remaining -= removed

		if slot.amount <= 0:
			slot.clear()

		if remaining <= 0:
			inventory_changed.emit()
			return true

	return false

func count_item(item_id: StringName) -> int:
	var total := 0

	for slot in slots:
		if not slot.is_empty() and slot.item.id == item_id:
			total += slot.amount

	return total

func get_used_slot_count() -> int:
	var used := 0
	for slot in slots:
		if not slot.is_empty():
			used += 1
	return used

func clear_all() -> void:
	for slot in slots:
		slot.clear()
	inventory_changed.emit()

func get_save_data() -> Array:
	var data: Array = []
	for slot in slots:
		if slot.is_empty():
			data.append({})
		else:
			data.append({
				"item_id": String(slot.item.id),
				"amount": slot.amount,
			})
	return data

func load_save_data(data: Array) -> void:
	clear_all()

	var limit := mini(data.size(), slots.size())
	for index in range(limit):
		var entry = data[index]
		if not (entry is Dictionary):
			continue

		var item_id := StringName(str(entry.get("item_id", "")))
		if item_id == &"":
			continue

		var definition := get_definition(item_id)
		if definition == null:
			continue

		seed_slot(index, definition, int(entry.get("amount", 0)))

	inventory_changed.emit()
