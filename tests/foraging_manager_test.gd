extends SceneTree

const InventoryScript := preload("res://scripts/inventory/Inventory.gd")
const ForagingManagerScript := preload("res://scripts/foraging/ForagingManager.gd")

func _init() -> void:
	var inventory = InventoryScript.new()
	inventory.setup_starter_items()

	var foraging_manager = ForagingManagerScript.new()
	foraging_manager.start_day(1)

	var first: Dictionary = foraging_manager.search(inventory, 1, "Spring")
	if not bool(first.get("success", false)):
		_fail("First search of the day should find a forage item.")
		return
	if String(first.get("item_id", "")) != "wild_berry" or inventory.count("wild_berry") != 1:
		_fail("Spring day 1 first search should add one wild berry.")
		return

	foraging_manager.search(inventory, 1, "Spring")
	var before_limit_count := inventory.count("wild_berry") + inventory.count("mushroom") + inventory.count("wild_herb")
	var limited: Dictionary = foraging_manager.search(inventory, 1, "Spring")
	var after_limit_count := inventory.count("wild_berry") + inventory.count("mushroom") + inventory.count("wild_herb")
	if bool(limited.get("success", false)) or before_limit_count != after_limit_count:
		_fail("Foraging should stop after the daily search limit.")
		return

	foraging_manager.start_day(8)
	var summer: Dictionary = foraging_manager.search(inventory, 8, "Summer")
	if String(summer.get("item_id", "")) != "wild_herb" or inventory.count("wild_herb") != 1:
		_fail("Summer first search should find a wild herb.")
		return

	var saved: Dictionary = foraging_manager.to_save_data()
	var restored = ForagingManagerScript.new()
	restored.load_save_data(saved)
	if restored.current_day != 8 or restored.searches_today != 1:
		_fail("Foraging save data should restore current day and searches.")
		return

	print("PASS foraging_manager_test")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
