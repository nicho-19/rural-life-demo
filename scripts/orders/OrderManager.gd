extends RefCounted
class_name OrderManager

var items: Dictionary = {}
var current_order: Dictionary = {}

func setup(item_data: Dictionary) -> void:
	items = item_data


func start_day(day: int) -> void:
	current_order = _order_for_day(day)


func describe_order(inventory = null) -> String:
	if current_order.is_empty():
		return "可选订单：今天没有订单。"
	if bool(current_order.get("completed", false)):
		return "可选订单：今天的订单已完成。"

	var requirements: Dictionary = current_order.get("requirements", {})
	var parts: Array[String] = []
	for crop_id in requirements.keys():
		var needed := int(requirements[crop_id])
		if inventory == null:
			parts.append("%s x%d" % [_item_name(crop_id), needed])
		else:
			parts.append("%s %d/%d" % [_item_name(crop_id), inventory.count(crop_id), needed])

	return "可选订单：%s | 奖励 %d 金 | 按 O 交付（可忽略）" % [
		"、".join(parts),
		int(current_order.get("reward", 0)),
	]


func can_deliver(inventory) -> bool:
	if current_order.is_empty() or bool(current_order.get("completed", false)):
		return false

	var requirements: Dictionary = current_order.get("requirements", {})
	for crop_id in requirements.keys():
		if inventory.count(crop_id) < int(requirements[crop_id]):
			return false
	return true


func deliver_order(inventory) -> Dictionary:
	if current_order.is_empty():
		return {
			"success": false,
			"message": "今天没有可交付的订单。",
		}
	if bool(current_order.get("completed", false)):
		return {
			"success": false,
			"message": "今天的订单已经完成了。",
		}
	if not can_deliver(inventory):
		return {
			"success": false,
			"message": "订单是可选的，作物够了再交也可以。",
		}

	var requirements: Dictionary = current_order.get("requirements", {})
	for crop_id in requirements.keys():
		inventory.remove_item(crop_id, int(requirements[crop_id]))

	var reward := int(current_order.get("reward", 0))
	inventory.money += reward
	current_order["completed"] = true
	return {
		"success": true,
		"message": "完成可选订单，获得 %d 金。" % reward,
	}


func _order_for_day(day: int) -> Dictionary:
	var templates: Array[Dictionary] = [
		{"turnip": 2},
		{"potato": 2},
		{"turnip": 2, "cabbage": 1},
		{"potato": 1, "corn": 1},
	]
	var requirements: Dictionary = templates[(day - 1) % templates.size()].duplicate(true)
	return {
		"requirements": requirements,
		"reward": _reward_for(requirements),
		"completed": false,
	}


func _reward_for(requirements: Dictionary) -> int:
	var base_value := 0
	for crop_id in requirements.keys():
		var item: Dictionary = items.get(crop_id, {})
		base_value += int(item.get("sell_price", 0)) * int(requirements[crop_id])
	return int(ceil(float(base_value) * 1.25))


func _item_name(item_id: String) -> String:
	var item: Dictionary = items.get(item_id, {})
	return String(item.get("name", item_id))


func to_save_data() -> Dictionary:
	return {
		"current_order": current_order.duplicate(true),
	}


func load_save_data(data: Dictionary) -> void:
	var saved_order = data.get("current_order", {})
	if saved_order is Dictionary:
		current_order = saved_order.duplicate(true)
