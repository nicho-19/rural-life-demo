extends RefCounted
class_name FishingManager

const MAX_CASTS_PER_DAY := 3
const FISH_ITEMS: Array[String] = ["pond_fish", "river_fish", "rare_fish"]

var current_day := 1
var casts_today := 0


func start_day(day: int) -> void:
	var normalized_day: int = max(1, day)
	if normalized_day != current_day:
		casts_today = 0
	current_day = normalized_day


func cast(inventory, day: int, weather_id: String) -> Dictionary:
	start_day(day)
	if casts_today >= MAX_CASTS_PER_DAY:
		return {
			"success": false,
			"message": "Fishing is done for today. Try again tomorrow.",
			"item_id": "",
		}

	casts_today += 1
	var item_id: String = _fish_for_cast(current_day, casts_today, weather_id)
	inventory.add_item(item_id, 1)
	return {
		"success": true,
		"message": "Caught fish: %s." % item_id,
		"item_id": item_id,
	}


func describe(inventory) -> String:
	return "Fishing %d/%d | pond %d | river %d | rare %d" % [
		casts_today,
		MAX_CASTS_PER_DAY,
		inventory.count("pond_fish"),
		inventory.count("river_fish"),
		inventory.count("rare_fish"),
	]


func briefing_text() -> String:
	return "Fishing: %d/%d casts used today." % [casts_today, MAX_CASTS_PER_DAY]


func to_save_data() -> Dictionary:
	return {
		"current_day": current_day,
		"casts_today": casts_today,
	}


func load_save_data(data: Dictionary) -> void:
	current_day = max(1, int(data.get("current_day", 1)))
	casts_today = clampi(int(data.get("casts_today", 0)), 0, MAX_CASTS_PER_DAY)


func _fish_for_cast(day: int, cast_number: int, weather_id: String) -> String:
	if weather_id == "rainy" and cast_number == 1:
		return "rare_fish"
	var cycle: Array[String] = ["pond_fish", "river_fish", "pond_fish"]
	return cycle[(day + cast_number - 2) % cycle.size()]
