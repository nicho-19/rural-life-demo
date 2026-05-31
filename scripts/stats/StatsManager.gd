extends RefCounted
class_name StatsManager

var planted: Dictionary = {}
var harvested: Dictionary = {}
var sold: Dictionary = {}
var total_earned := 0
var orders_completed := 0

func record_planted(crop_id: String, amount: int = 1) -> void:
	_add_count(planted, crop_id, amount)


func record_harvested(crop_id: String, amount: int = 1) -> void:
	_add_count(harvested, crop_id, amount)


func record_sold(crop_id: String, amount: int, earned: int) -> void:
	_add_count(sold, crop_id, amount)
	total_earned += earned


func record_order_completed(reward: int) -> void:
	orders_completed += 1
	total_earned += reward


func count_planted(crop_id: String) -> int:
	return int(planted.get(crop_id, 0))


func count_harvested(crop_id: String) -> int:
	return int(harvested.get(crop_id, 0))


func count_sold(crop_id: String) -> int:
	return int(sold.get(crop_id, 0))


func describe(items: Dictionary) -> String:
	var lines: Array[String] = [
		"农场图鉴（只记录，不强制）",
		"总收入 %d 金 | 完成可选订单 %d 次" % [total_earned, orders_completed],
	]

	for crop_id in _known_crop_ids():
		var item: Dictionary = items.get(crop_id, {})
		lines.append("%s：种植 %d | 收获 %d | 出售 %d" % [
			String(item.get("name", crop_id)),
			count_planted(crop_id),
			count_harvested(crop_id),
			count_sold(crop_id),
		])

	return "\n".join(lines)


func to_save_data() -> Dictionary:
	return {
		"planted": planted.duplicate(true),
		"harvested": harvested.duplicate(true),
		"sold": sold.duplicate(true),
		"total_earned": total_earned,
		"orders_completed": orders_completed,
	}


func load_save_data(data: Dictionary) -> void:
	planted = _counts_from(data.get("planted", {}))
	harvested = _counts_from(data.get("harvested", {}))
	sold = _counts_from(data.get("sold", {}))
	total_earned = int(data.get("total_earned", 0))
	orders_completed = int(data.get("orders_completed", 0))


func _add_count(target: Dictionary, crop_id: String, amount: int) -> void:
	if amount <= 0:
		return
	target[crop_id] = int(target.get(crop_id, 0)) + amount


func _counts_from(value) -> Dictionary:
	var result: Dictionary = {}
	if not value is Dictionary:
		return result

	for key in value.keys():
		var amount := int(value[key])
		if amount > 0:
			result[String(key)] = amount
	return result


func _known_crop_ids() -> Array[String]:
	var crop_ids: Array[String] = []
	for source in [planted, harvested, sold]:
		for crop_id in source.keys():
			if not crop_ids.has(String(crop_id)):
				crop_ids.append(String(crop_id))
	crop_ids.sort()
	return crop_ids
