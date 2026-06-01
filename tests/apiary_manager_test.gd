extends SceneTree

const InventoryScript := preload("res://scripts/inventory/Inventory.gd")
const ApiaryManagerScript := preload("res://scripts/apiary/ApiaryManager.gd")

func _init() -> void:
	var inventory = InventoryScript.new()
	inventory.setup_starter_items()
	inventory.money = 1000

	var apiary_manager = ApiaryManagerScript.new()
	var bought: Dictionary = apiary_manager.buy_beehive(inventory)
	if not bool(bought.get("success", false)):
		_fail("Buying a beehive should succeed with enough money.")
		return
	if apiary_manager.beehives != 1 or inventory.money != 700:
		_fail("Buying a beehive should deduct 300 gold and increase hive count.")
		return

	apiary_manager.advance_day(inventory, "spring")
	if inventory.count("honey") != 1:
		_fail("One beehive should produce one honey outside winter.")
		return

	apiary_manager.advance_day(inventory, "winter")
	if inventory.count("honey") != 1:
		_fail("Beehives should not produce honey in winter.")
		return

	apiary_manager.buy_beehive(inventory)
	apiary_manager.buy_beehive(inventory)
	var full: Dictionary = apiary_manager.buy_beehive(inventory)
	if bool(full.get("success", false)) or apiary_manager.beehives != ApiaryManagerScript.MAX_BEEHIVES:
		_fail("Apiary should enforce the beehive capacity.")
		return

	var saved: Dictionary = apiary_manager.to_save_data()
	var restored = ApiaryManagerScript.new()
	restored.load_save_data(saved)
	if restored.beehives != ApiaryManagerScript.MAX_BEEHIVES:
		_fail("Apiary save data should restore beehive count.")
		return

	print("PASS apiary_manager_test")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
