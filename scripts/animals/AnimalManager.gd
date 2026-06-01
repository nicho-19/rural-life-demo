extends RefCounted
class_name AnimalManager

const CHICKEN_PRICE := 250
const COW_PRICE := 650
const MAX_CHICKENS := 4
const MAX_COWS := 2
const FEED_ITEM_ID := "animal_feed"
const EGG_ITEM_ID := "egg"
const MILK_ITEM_ID := "milk"

var chickens := 0
var cows := 0
var fed_chickens := 0
var fed_cows := 0

func buy_chicken(inventory) -> Dictionary:
	if chickens >= MAX_CHICKENS:
		return {
			"success": false,
			"message": "鸡舍已经住满了。",
		}
	if inventory.money < CHICKEN_PRICE:
		return {
			"success": false,
			"message": "买鸡需要 %d 金。" % CHICKEN_PRICE,
		}
	inventory.money -= CHICKEN_PRICE
	chickens += 1
	return {
		"success": true,
		"message": "买了一只鸡。明天开始，好好喂它就会下蛋。",
	}


func buy_cow(inventory) -> Dictionary:
	if cows >= MAX_COWS:
		return {
			"success": false,
			"message": "牛棚已经住满了。",
		}
	if inventory.money < COW_PRICE:
		return {
			"success": false,
			"message": "买牛需要 %d 金。" % COW_PRICE,
		}
	inventory.money -= COW_PRICE
	cows += 1
	return {
		"success": true,
		"message": "买了一头牛。喂饱后第二天会产出牛奶。",
	}


func feed_all(inventory) -> Dictionary:
	var fed := 0
	while fed_chickens < chickens and inventory.remove_item(FEED_ITEM_ID, 1):
		fed_chickens += 1
		fed += 1
	while fed_cows < cows and inventory.remove_item(FEED_ITEM_ID, 1):
		fed_cows += 1
		fed += 1

	if fed <= 0:
		if chickens + cows <= 0:
			return {
				"success": false,
				"message": "动物棚还没有动物。",
				"fed": 0,
			}
		return {
			"success": false,
			"message": "没有饲料，或者动物今天已经喂过了。",
			"fed": 0,
		}

	return {
		"success": true,
		"message": "喂好了 %d 只动物。" % fed,
		"fed": fed,
	}


func advance_day(inventory) -> Dictionary:
	var eggs := fed_chickens
	var milk := fed_cows
	if eggs > 0:
		inventory.add_item(EGG_ITEM_ID, eggs)
	if milk > 0:
		inventory.add_item(MILK_ITEM_ID, milk)

	fed_chickens = 0
	fed_cows = 0
	return {
		"egg": eggs,
		"milk": milk,
		"message": production_message(eggs, milk),
	}


func describe(inventory = null) -> String:
	var feed_count := 0
	var egg_count := 0
	var milk_count := 0
	if inventory != null:
		feed_count = inventory.count(FEED_ITEM_ID)
		egg_count = inventory.count(EGG_ITEM_ID)
		milk_count = inventory.count(MILK_ITEM_ID)
	return "动物：鸡 %d/%d（已喂 %d），牛 %d/%d（已喂 %d），饲料 %d，鸡蛋 %d，牛奶 %d。" % [
		chickens,
		MAX_CHICKENS,
		fed_chickens,
		cows,
		MAX_COWS,
		fed_cows,
		feed_count,
		egg_count,
		milk_count,
	]


func briefing_text() -> String:
	return "动物：鸡 %d/%d，牛 %d/%d，今天已喂 %d/%d。" % [
		chickens,
		MAX_CHICKENS,
		cows,
		MAX_COWS,
		fed_chickens + fed_cows,
		chickens + cows,
	]


func production_message(eggs: int, milk: int) -> String:
	if eggs <= 0 and milk <= 0:
		return "动物们安静地过了一天；没喂食就不会产出。"
	var parts: Array[String] = []
	if eggs > 0:
		parts.append("鸡蛋 x%d" % eggs)
	if milk > 0:
		parts.append("牛奶 x%d" % milk)
	return "动物棚产出了 %s。" % "，".join(parts)


func to_save_data() -> Dictionary:
	return {
		"chickens": chickens,
		"cows": cows,
		"fed_chickens": fed_chickens,
		"fed_cows": fed_cows,
	}


func load_save_data(data: Dictionary) -> void:
	chickens = clampi(int(data.get("chickens", 0)), 0, MAX_CHICKENS)
	cows = clampi(int(data.get("cows", 0)), 0, MAX_COWS)
	fed_chickens = clampi(int(data.get("fed_chickens", 0)), 0, chickens)
	fed_cows = clampi(int(data.get("fed_cows", 0)), 0, cows)
