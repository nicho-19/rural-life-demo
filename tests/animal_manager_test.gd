extends SceneTree

const AnimalManagerScript := preload("res://scripts/animals/AnimalManager.gd")
const InventoryScript := preload("res://scripts/inventory/Inventory.gd")

func _init() -> void:
	var animals = AnimalManagerScript.new()
	var inventory = InventoryScript.new()
	inventory.money = 3000

	for _index in 4:
		var chicken_result: Dictionary = animals.buy_chicken(inventory)
		if not bool(chicken_result.get("success", false)):
			_fail("Buying chickens should succeed until the coop is full.")
			return
	for _index in 2:
		var cow_result: Dictionary = animals.buy_cow(inventory)
		if not bool(cow_result.get("success", false)):
			_fail("Buying cows should succeed until the barn is full.")
			return

	if animals.chickens != 4 or animals.cows != 2:
		_fail("Animal counts should track bought chickens and cows.")
		return
	if inventory.money != 700:
		_fail("Buying 4 chickens and 2 cows should cost 2300 gold.")
		return
	if bool(animals.buy_chicken(inventory).get("success", true)):
		_fail("Buying a fifth chicken should fail at capacity.")
		return
	if bool(animals.buy_cow(inventory).get("success", true)):
		_fail("Buying a third cow should fail at capacity.")
		return

	inventory.add_item("animal_feed", 3)
	var partial_feed: Dictionary = animals.feed_all(inventory)
	if int(partial_feed.get("fed", 0)) != 3:
		_fail("Feeding with 3 feed should feed exactly 3 animals.")
		return
	if animals.fed_chickens != 3 or animals.fed_cows != 0:
		_fail("Feeding should prioritize chickens before cows.")
		return
	if inventory.count("animal_feed") != 0:
		_fail("Feeding should consume available feed.")
		return

	inventory.add_item("animal_feed", 3)
	var full_feed: Dictionary = animals.feed_all(inventory)
	if int(full_feed.get("fed", 0)) != 3:
		_fail("Second feeding should feed remaining animals.")
		return
	if animals.fed_chickens != 4 or animals.fed_cows != 2:
		_fail("All animals should be fed after enough feed is provided.")
		return

	var produced: Dictionary = animals.advance_day(inventory)
	if inventory.count("egg") != 4 or inventory.count("milk") != 2:
		_fail("Fed chickens and cows should produce eggs and milk on the next day.")
		return
	if int(produced.get("egg", 0)) != 4 or int(produced.get("milk", 0)) != 2:
		_fail("advance_day should report produced eggs and milk.")
		return
	if animals.fed_chickens != 0 or animals.fed_cows != 0:
		_fail("Animal feeding state should reset after production.")
		return

	animals.feed_all(inventory)
	var saved: Dictionary = animals.to_save_data()
	var loaded = AnimalManagerScript.new()
	loaded.load_save_data(saved)
	if loaded.chickens != animals.chickens or loaded.cows != animals.cows:
		_fail("Save data should restore animal counts.")
		return
	if loaded.fed_chickens != animals.fed_chickens or loaded.fed_cows != animals.fed_cows:
		_fail("Save data should restore feeding state.")
		return

	print("PASS animal_manager_test")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
