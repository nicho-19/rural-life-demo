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


func to_save_data() -> Dictionary:
	return {
		"money": money,
		"items": items.duplicate(true),
	}


func load_save_data(data: Dictionary) -> void:
	money = int(data.get("money", 100))
	items.clear()

	var saved_items = data.get("items", {})
	if not saved_items is Dictionary:
		return

	for item_id in saved_items.keys():
		var amount := int(saved_items[item_id])
		if amount > 0:
			items[String(item_id)] = amount
