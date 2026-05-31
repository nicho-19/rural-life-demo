extends RefCounted
class_name Inventory

var money := 100
var items: Dictionary = {}

func setup_starter_items() -> void:
	items.clear()
	add_item("turnip_seed", 8)


func add_item(item_id: String, amount: int) -> void:
	items[item_id] = count(item_id) + amount


func remove_item(item_id: String, amount: int) -> bool:
	if count(item_id) < amount:
		return false
	items[item_id] = count(item_id) - amount
	if int(items[item_id]) <= 0:
		items.erase(item_id)
	return true


func count(item_id: String) -> int:
	return int(items.get(item_id, 0))
