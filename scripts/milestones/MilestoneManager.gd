extends RefCounted
class_name MilestoneManager

var unlocked: Dictionary = {}

func check(stats_manager, inventory) -> Array[String]:
	var messages: Array[String] = []
	_try_unlock(messages, "first_seed", stats_manager.total_planted() >= 1, "小里程碑：第一粒种子落土了。慢慢来，农场已经开始呼吸。")
	_try_unlock(messages, "first_harvest", stats_manager.total_harvested() >= 1, "小里程碑：第一次收获完成。土地开始回报你的照料。")
	_try_unlock(messages, "first_sale", stats_manager.total_sold() >= 1, "小里程碑：第一次出售作物。钱袋响了一下，但日子不用赶。")
	_try_unlock(messages, "first_order", stats_manager.orders_completed >= 1, "小里程碑：完成了一次可选订单。接不接都可以，今天只是刚好合适。")
	_try_unlock(messages, "gold_500", inventory.money >= 500, "小里程碑：攒到 500 金。已经是一座很像样的小农场了。")
	return messages


func describe() -> String:
	return "小里程碑：已点亮 %d / 5。它们只是纪念，不是任务。" % unlocked.size()


func to_save_data() -> Dictionary:
	return {
		"unlocked": unlocked.duplicate(true),
	}


func load_save_data(data: Dictionary) -> void:
	unlocked.clear()
	var saved = data.get("unlocked", {})
	if not saved is Dictionary:
		return
	for key in saved.keys():
		if bool(saved[key]):
			unlocked[String(key)] = true


func _try_unlock(messages: Array[String], milestone_id: String, condition: bool, message: String) -> void:
	if not condition or bool(unlocked.get(milestone_id, false)):
		return
	unlocked[milestone_id] = true
	messages.append(message)
