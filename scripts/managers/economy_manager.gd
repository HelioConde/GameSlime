class_name EconomyManager
extends Node

signal gold_changed(gold: int)
signal shipping_changed(total_value: int)
signal shipment_paid(amount: int)

const STARTING_GOLD := 500

var gold: int = STARTING_GOLD
var pending_shipments: Dictionary = {}
var last_day_income: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameClock.day_started.connect(_on_day_started)

func can_afford(amount: int) -> bool:
	return amount <= 0 or gold >= amount

func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return true
	if gold < amount:
		return false

	gold -= amount
	gold_changed.emit(gold)
	return true

func queue_shipment(item: ItemDefinition, amount: int) -> bool:
	if item == null or amount <= 0 or item.sell_price <= 0:
		return false

	var key := String(item.id)
	var entry: Dictionary = pending_shipments.get(key, {})
	entry["item_id"] = key
	entry["display_name"] = item.display_name
	entry["amount"] = int(entry.get("amount", 0)) + amount
	entry["unit_price"] = item.sell_price
	pending_shipments[key] = entry

	shipping_changed.emit(get_pending_total())
	return true

func get_pending_total() -> int:
	var total := 0
	for value in pending_shipments.values():
		if not (value is Dictionary):
			continue
		var entry := value as Dictionary
		total += int(entry.get("amount", 0)) * int(entry.get("unit_price", 0))
	return total

func get_pending_item_count() -> int:
	var total := 0
	for value in pending_shipments.values():
		if value is Dictionary:
			total += int((value as Dictionary).get("amount", 0))
	return total

func get_save_data() -> Dictionary:
	return {
		"gold": gold,
		"pending_shipments": pending_shipments.duplicate(true),
		"last_day_income": last_day_income,
	}

func load_save_data(data: Dictionary) -> void:
	gold = maxi(int(data.get("gold", STARTING_GOLD)), 0)
	var saved_shipments = data.get("pending_shipments", {})
	pending_shipments = saved_shipments.duplicate(true) if saved_shipments is Dictionary else {}
	last_day_income = maxi(int(data.get("last_day_income", 0)), 0)
	gold_changed.emit(gold)
	shipping_changed.emit(get_pending_total())

func _on_day_started(_day: int) -> void:
	_settle_shipping()

func _settle_shipping() -> void:
	last_day_income = get_pending_total()
	if last_day_income <= 0:
		return

	pending_shipments.clear()
	gold += last_day_income
	gold_changed.emit(gold)
	shipping_changed.emit(0)
	shipment_paid.emit(last_day_income)
