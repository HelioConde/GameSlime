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

func move_or_merge_stack(from_index: int, to_index: int) -> bool:
	if from_index == to_index:
		return false
	if from_index < 0 or from_index >= slots.size():
		return false
	if to_index < 0 or to_index >= slots.size():
		return false

	var source := slots[from_index]
	var target := slots[to_index]

	if source == null or source.is_empty():
		return false

	var selected_item_id := StringName()
	if selected_slot >= 0 and selected_slot < slots.size():
		var selected_stack := slots[selected_slot]
		if selected_stack != null and not selected_stack.is_empty():
			selected_item_id = selected_stack.item.id

	if target == null or target.is_empty():
		target.item = source.item
		target.amount = source.amount
		source.clear()
	elif target.item.id == source.item.id and source.item.max_stack > 1:
		var available := maxi(target.item.max_stack - target.amount, 0)
		if available <= 0:
			return false

		var moved := mini(available, source.amount)
		target.amount += moved
		source.amount -= moved

		if source.amount <= 0:
			source.clear()
	else:
		var temp_item := target.item
		var temp_amount := target.amount
		target.item = source.item
		target.amount = source.amount
		source.item = temp_item
		source.amount = temp_amount

	_restore_selection_by_item(selected_item_id)
	inventory_changed.emit()
	selected_slot_changed.emit(selected_slot)
	return true

func split_stack_half(from_index: int, to_index: int) -> bool:
	if from_index == to_index:
		return false
	if from_index < 0 or from_index >= slots.size():
		return false
	if to_index < 0 or to_index >= slots.size():
		return false

	var source := slots[from_index]
	var target := slots[to_index]
	if source == null or source.is_empty() or source.amount <= 1:
		return false
	if target == null or not target.is_empty():
		return false
	if source.item.max_stack <= 1:
		return false

	var moved := int(ceil(float(source.amount) * 0.5))
	target.item = source.item
	target.amount = moved
	source.amount -= moved

	inventory_changed.emit()
	return true

func organize_slots() -> void:
	if slots.is_empty():
		return

	var selected_item_id := StringName()
	var selected_stack := get_selected_stack()
	if selected_stack != null and not selected_stack.is_empty():
		selected_item_id = selected_stack.item.id

	var totals: Dictionary = {}
	var order: Array[StringName] = []

	for slot in slots:
		if slot == null or slot.is_empty():
			continue

		var item_id := slot.item.id
		if not totals.has(item_id):
			totals[item_id] = {
				"item": slot.item,
				"amount": 0,
			}
			order.append(item_id)

		var entry := totals[item_id] as Dictionary
		entry["amount"] = int(entry.get("amount", 0)) + slot.amount
		totals[item_id] = entry

	for slot in slots:
		slot.clear()

	var write_index := 0
	for item_id in order:
		var entry := totals[item_id] as Dictionary
		var item := entry.get("item") as ItemDefinition
		var remaining := int(entry.get("amount", 0))

		while remaining > 0 and write_index < slots.size():
			var moved := mini(item.max_stack, remaining)
			slots[write_index].item = item
			slots[write_index].amount = moved
			remaining -= moved
			write_index += 1

	_restore_selection_by_item(selected_item_id)
	inventory_changed.emit()
	selected_slot_changed.emit(selected_slot)

func _restore_selection_by_item(item_id: StringName) -> void:
	if item_id == &"":
		selected_slot = clampi(selected_slot, 0, maxi(slots.size() - 1, 0))
		return

	for index in range(slots.size()):
		var slot := slots[index]
		if slot != null and not slot.is_empty() and slot.item.id == item_id:
			selected_slot = index
			return

	selected_slot = clampi(selected_slot, 0, maxi(slots.size() - 1, 0))

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
