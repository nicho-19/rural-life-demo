extends RefCounted
class_name ShopManager

var items: Dictionary = {}

func setup(item_data: Dictionary) -> void:
	items = item_data


func buy_item(inventory, item_id: String, amount: int = 1) -> Dictionary:
	var item: Dictionary = items.get(item_id, {})
	var price := int(item.get("price", 0))
	var name := String(item.get("name", item_id))
	if price <= 0:
		return {
			"success": false,
			"message": "%s 暂时不能购买。" % name,
		}

	var total_price := price * amount
	if inventory.money < total_price:
		return {
			"success": false,
			"message": "金币不足，购买 %d 个%s需要 %d 金。" % [amount, name, total_price],
		}

	inventory.money -= total_price
	inventory.add_item(item_id, amount)
	return {
		"success": true,
		"message": "购买 %d 个%s，花费 %d 金。" % [amount, name, total_price],
	}


func sell_all_crops(inventory, crop_ids: Array[String]) -> Dictionary:
	var earned := 0
	var sold_count := 0
	var sold_names: Array[String] = []

	for crop_id in crop_ids:
		var amount: int = inventory.count(crop_id)
		if amount <= 0:
			continue

		var item: Dictionary = items.get(crop_id, {})
		var price := int(item.get("sell_price", 0))
		if price <= 0:
			continue

		inventory.remove_item(crop_id, amount)
		earned += amount * price
		sold_count += amount
		sold_names.append("%s x%d" % [String(item.get("name", crop_id)), amount])

	if earned <= 0:
		return {
			"success": false,
			"message": "背包里没有成熟作物可以出售。",
			"earned": 0,
			"sold_count": 0,
		}

	inventory.money += earned
	return {
		"success": true,
		"message": "出售 %s，收入 %d 金。" % [", ".join(sold_names), earned],
		"earned": earned,
		"sold_count": sold_count,
	}
