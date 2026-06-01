extends RefCounted
class_name ApiaryManager

const BEEHIVE_PRICE := 300
const MAX_BEEHIVES := 3
const HONEY_ITEM_ID := "honey"

var beehives := 0


func buy_beehive(inventory) -> Dictionary:
	if beehives >= MAX_BEEHIVES:
		return {
			"success": false,
			"message": "Apiary is full.",
		}
	if inventory.money < BEEHIVE_PRICE:
		return {
			"success": false,
			"message": "Not enough gold for a beehive.",
		}
	inventory.money -= BEEHIVE_PRICE
	beehives += 1
	return {
		"success": true,
		"message": "Built one beehive.",
	}


func advance_day(inventory, season_id: String) -> Dictionary:
	if beehives <= 0 or season_id.to_lower() == "winter":
		return {
			"honey": 0,
			"message": "",
		}
	inventory.add_item(HONEY_ITEM_ID, beehives)
	return {
		"honey": beehives,
		"message": "Beehives produced honey x%d." % beehives,
	}


func describe(inventory) -> String:
	return "Apiary %d/%d | honey %d" % [
		beehives,
		MAX_BEEHIVES,
		inventory.count(HONEY_ITEM_ID),
	]


func briefing_text() -> String:
	if beehives <= 0:
		return "Apiary: no beehives yet."
	return "Apiary: %d/%d beehives producing outside winter." % [beehives, MAX_BEEHIVES]


func to_save_data() -> Dictionary:
	return {
		"beehives": beehives,
	}


func load_save_data(data: Dictionary) -> void:
	beehives = clampi(int(data.get("beehives", 0)), 0, MAX_BEEHIVES)
