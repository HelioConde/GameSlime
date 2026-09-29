class_name InventorySlotData
extends RefCounted

enum Quality {
	NORMAL,
	SILVER,
	GOLD,
}

var item: ItemDefinition
var amount: int = 0
var quality: int = Quality.NORMAL

func is_empty() -> bool:
	return item == null or amount <= 0

func clear() -> void:
	item = null
	amount = 0
	quality = Quality.NORMAL

static func clamp_quality(value: int) -> int:
	return clampi(value, Quality.NORMAL, Quality.GOLD)

static func get_quality_name(value: int) -> String:
	match clamp_quality(value):
		Quality.SILVER:
			return "Prata"
		Quality.GOLD:
			return "Ouro"
		_:
			return "Normal"

static func get_quality_marker(value: int) -> String:
	match clamp_quality(value):
		Quality.SILVER:
			return "☆"
		Quality.GOLD:
			return "★"
		_:
			return ""

static func get_sell_multiplier(value: int) -> float:
	match clamp_quality(value):
		Quality.SILVER:
			return 1.25
		Quality.GOLD:
			return 1.50
		_:
			return 1.0

static func get_adjusted_sell_price(base_price: int, value: int) -> int:
	return maxi(roundi(float(base_price) * get_sell_multiplier(value)), 0)
