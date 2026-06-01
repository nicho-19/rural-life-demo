extends SceneTree

const InventoryScript := preload("res://scripts/inventory/Inventory.gd")
const FishingManagerScript := preload("res://scripts/fishing/FishingManager.gd")

func _init() -> void:
	var inventory = InventoryScript.new()
	inventory.setup_starter_items()

	var fishing_manager = FishingManagerScript.new()
	fishing_manager.start_day(1)

	var first: Dictionary = fishing_manager.cast(inventory, 1, "sunny")
	if not bool(first.get("success", false)):
		_fail("First cast of the day should catch a fish.")
		return
	if String(first.get("item_id", "")) != "pond_fish" or inventory.count("pond_fish") != 1:
		_fail("Sunny day 1 first cast should add one pond fish.")
		return

	fishing_manager.cast(inventory, 1, "sunny")
	fishing_manager.cast(inventory, 1, "sunny")
	var before_limit_count := inventory.count("pond_fish") + inventory.count("river_fish") + inventory.count("rare_fish")
	var limited: Dictionary = fishing_manager.cast(inventory, 1, "sunny")
	var after_limit_count := inventory.count("pond_fish") + inventory.count("river_fish") + inventory.count("rare_fish")
	if bool(limited.get("success", false)) or before_limit_count != after_limit_count:
		_fail("Fishing should stop after the daily cast limit.")
		return

	fishing_manager.start_day(3)
	var rainy: Dictionary = fishing_manager.cast(inventory, 3, "rainy")
	if String(rainy.get("item_id", "")) != "rare_fish" or inventory.count("rare_fish") != 1:
		_fail("Rainy first cast should catch a rare fish.")
		return

	var saved: Dictionary = fishing_manager.to_save_data()
	var restored = FishingManagerScript.new()
	restored.load_save_data(saved)
	if restored.current_day != 3 or restored.casts_today != 1:
		_fail("Fishing save data should restore current day and casts.")
		return

	print("PASS fishing_manager_test")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
