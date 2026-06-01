extends SceneTree

const DataManagerScript := preload("res://scripts/core/DataManager.gd")
const InventoryScript := preload("res://scripts/inventory/Inventory.gd")
const CraftingManagerScript := preload("res://scripts/crafting/CraftingManager.gd")

func _init() -> void:
	var data_manager = DataManagerScript.new()
	data_manager.load_all()

	if data_manager.recipes.size() != 5:
		_fail("DataManager should load the five first crafting recipes.")
		return
	for recipe_id in ["dried_turnip", "hash_brown", "cornmeal", "mayonnaise", "cheese"]:
		if not data_manager.recipes.has(recipe_id):
			_fail("Recipe data should include %s." % recipe_id)
			return
		var output_item_id := String(data_manager.recipes[recipe_id].get("output", ""))
		if not data_manager.items.has(output_item_id):
			_fail("Recipe %s should output an item known to DataManager." % recipe_id)
			return
		if int(data_manager.items[output_item_id].get("sell_price", 0)) <= 0:
			_fail("Crafted item %s should have a sell_price." % output_item_id)
			return

	var inventory = InventoryScript.new()
	inventory.add_item("turnip", 2)
	inventory.add_item("potato", 1)
	inventory.add_item("corn", 2)
	inventory.add_item("egg", 1)
	inventory.add_item("milk", 1)

	var crafting = CraftingManagerScript.new()
	crafting.setup(data_manager.recipes, data_manager.items)

	var turnip_result: Dictionary = crafting.craft(inventory, "dried_turnip")
	if not bool(turnip_result.get("success", false)):
		_fail("Crafting dried turnip should succeed when turnips are available.")
		return
	if inventory.count("turnip") != 1 or inventory.count("dried_turnip") != 1:
		_fail("Crafting dried turnip should consume one turnip and add one dried turnip.")
		return

	var potato_result: Dictionary = crafting.craft(inventory, "hash_brown")
	var corn_result: Dictionary = crafting.craft(inventory, "cornmeal")
	var mayo_result: Dictionary = crafting.craft(inventory, "mayonnaise")
	var cheese_result: Dictionary = crafting.craft(inventory, "cheese")
	if not bool(potato_result.get("success", false)) or not bool(corn_result.get("success", false)) or not bool(mayo_result.get("success", false)) or not bool(cheese_result.get("success", false)):
		_fail("All first processing recipes should craft immediately when ingredients exist.")
		return
	if inventory.count("hash_brown") != 1 or inventory.count("cornmeal") != 1 or inventory.count("mayonnaise") != 1 or inventory.count("cheese") != 1:
		_fail("Crafting should add each processed output item.")
		return

	var failed_result: Dictionary = crafting.craft(inventory, "mayonnaise")
	if bool(failed_result.get("success", true)):
		_fail("Crafting without enough ingredients should fail.")
		return
	if inventory.count("mayonnaise") != 1:
		_fail("Failed crafting should not add output items.")
		return

	print("PASS crafting_manager_test")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
