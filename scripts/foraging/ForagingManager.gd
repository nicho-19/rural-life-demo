extends RefCounted
class_name ForagingManager

const MAX_SEARCHES_PER_DAY := 2
const FORAGE_ITEMS: Array[String] = ["wild_berry", "mushroom", "wild_herb"]

var current_day := 1
var searches_today := 0


func start_day(day: int) -> void:
	var normalized_day: int = max(1, day)
	if normalized_day != current_day:
		searches_today = 0
	current_day = normalized_day


func search(inventory, day: int, season_name: String) -> Dictionary:
	start_day(day)
	if searches_today >= MAX_SEARCHES_PER_DAY:
		return {
			"success": false,
			"message": "Foraging is done for today. Try again tomorrow.",
			"item_id": "",
		}

	searches_today += 1
	var item_id: String = _forage_for_search(current_day, searches_today, season_name)
	inventory.add_item(item_id, 1)
	return {
		"success": true,
		"message": "Found forage: %s." % item_id,
		"item_id": item_id,
	}


func describe(inventory) -> String:
	return "Foraging %d/%d | berries %d | mushrooms %d | herbs %d" % [
		searches_today,
		MAX_SEARCHES_PER_DAY,
		inventory.count("wild_berry"),
		inventory.count("mushroom"),
		inventory.count("wild_herb"),
	]


func briefing_text() -> String:
	return "Foraging: %d/%d searches used today." % [searches_today, MAX_SEARCHES_PER_DAY]


func to_save_data() -> Dictionary:
	return {
		"current_day": current_day,
		"searches_today": searches_today,
	}


func load_save_data(data: Dictionary) -> void:
	current_day = max(1, int(data.get("current_day", 1)))
	searches_today = clampi(int(data.get("searches_today", 0)), 0, MAX_SEARCHES_PER_DAY)


func _forage_for_search(day: int, search_number: int, season_name: String) -> String:
	match season_name.to_lower():
		"summer":
			return "wild_herb" if search_number == 1 else "wild_berry"
		"autumn":
			return "mushroom" if search_number == 1 else "wild_berry"
		"winter":
			return "wild_herb"
	var cycle: Array[String] = ["wild_berry", "mushroom"]
	return cycle[(day + search_number - 2) % cycle.size()]
