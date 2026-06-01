extends RefCounted
class_name NpcRelationshipManager

const ALLOWED_GIFTS: Array[String] = ["turnip", "potato", "cabbage", "corn", "egg", "milk"]
const LOVED_DELTA := 12
const LIKED_DELTA := 6
const NEUTRAL_DELTA := 2
const DISLIKED_DELTA := -3

var npcs: Dictionary = {}
var friendship: Dictionary = {}
var last_gift_day: Dictionary = {}
var current_day := 1

func setup(npc_data: Dictionary) -> void:
	npcs = npc_data.duplicate(true)
	for npc_id in npcs.keys():
		var key := String(npc_id)
		if not friendship.has(key):
			friendship[key] = 0


func start_day(day: int) -> void:
	current_day = max(1, day)


func give_gift(npc_id: String, item_id: String, inventory, day: int = -1) -> Dictionary:
	var gift_day: int = current_day if day <= 0 else max(1, day)
	current_day = gift_day
	if not npcs.has(npc_id):
		return _result(false, "没有这位村民。")
	if not ALLOWED_GIFTS.has(item_id):
		return _result(false, "这件东西不适合作为礼物。")
	if was_gifted_today(npc_id, gift_day):
		return _result(false, "%s 今天已经收过礼物了。" % npc_name(npc_id))
	if inventory == null or inventory.count(item_id) <= 0:
		return _result(false, "背包里没有这件礼物。")

	var delta := preference_delta(npc_id, item_id)
	if not inventory.remove_item(item_id, 1):
		return _result(false, "背包里没有这件礼物。")

	friendship[npc_id] = clampi(friendship_for(npc_id) + delta, 0, 100)
	last_gift_day[npc_id] = gift_day
	return {
		"success": true,
		"message": "%s 收下了 %s，好感 %+d。" % [npc_name(npc_id), item_id, delta],
		"delta": delta,
		"friendship": friendship_for(npc_id),
	}


func friendship_for(npc_id: String) -> int:
	return clampi(int(friendship.get(npc_id, 0)), 0, 100)


func was_gifted_today(npc_id: String, day: int = -1) -> bool:
	var check_day: int = current_day if day <= 0 else max(1, day)
	return int(last_gift_day.get(npc_id, 0)) == check_day


func preference_delta(npc_id: String, item_id: String) -> int:
	var npc: Dictionary = npcs.get(npc_id, {})
	if _string_array(npc.get("loved", [])).has(item_id):
		return LOVED_DELTA
	if _string_array(npc.get("liked", [])).has(item_id):
		return LIKED_DELTA
	if _string_array(npc.get("disliked", [])).has(item_id):
		return DISLIKED_DELTA
	return NEUTRAL_DELTA


func npc_name(npc_id: String) -> String:
	var npc: Dictionary = npcs.get(npc_id, {})
	return String(npc.get("name", npc_id))


func preference_hint(npc_id: String) -> String:
	var npc: Dictionary = npcs.get(npc_id, {})
	return String(npc.get("hint", "偏好还在慢慢了解中。"))


func describe() -> String:
	var lines: Array[String] = ["村民关系"]
	for npc_id in npcs.keys():
		var key := String(npc_id)
		var gift_state := "今日已送" if was_gifted_today(key) else "今日未送"
		lines.append("%s  好感 %d/100  %s" % [npc_name(key), friendship_for(key), gift_state])
		lines.append("偏好提示：%s" % preference_hint(key))
	return "\n".join(lines)


func briefing_text() -> String:
	var parts: Array[String] = []
	for npc_id in npcs.keys():
		var key := String(npc_id)
		var gift_state := "已送" if was_gifted_today(key) else "未送"
		parts.append("%s %d/100 %s" % [npc_name(key), friendship_for(key), gift_state])
	return "村民：%s。" % "；".join(parts)


func gift_button_text(npc_id: String, item_id: String, item_name: String, inventory) -> String:
	var count := 0
	if inventory != null:
		count = inventory.count(item_id)
	return "送%s给%s（%d）" % [item_name, npc_name(npc_id), count]


func to_save_data() -> Dictionary:
	return {
		"friendship": friendship.duplicate(true),
		"last_gift_day": last_gift_day.duplicate(true),
	}


func load_save_data(data: Dictionary) -> void:
	friendship.clear()
	last_gift_day.clear()
	var saved_friendship = data.get("friendship", {})
	if saved_friendship is Dictionary:
		for npc_id in saved_friendship.keys():
			friendship[String(npc_id)] = clampi(int(saved_friendship[npc_id]), 0, 100)
	var saved_gift_days = data.get("last_gift_day", {})
	if saved_gift_days is Dictionary:
		for npc_id in saved_gift_days.keys():
			var day := int(saved_gift_days[npc_id])
			if day > 0:
				last_gift_day[String(npc_id)] = day
	for npc_id in npcs.keys():
		var key := String(npc_id)
		if not friendship.has(key):
			friendship[key] = 0


func _string_array(value) -> Array[String]:
	var result: Array[String] = []
	if not value is Array:
		return result
	for item in value:
		result.append(String(item))
	return result


func _result(success: bool, message: String) -> Dictionary:
	return {
		"success": success,
		"message": message,
	}
