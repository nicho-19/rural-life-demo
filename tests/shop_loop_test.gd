extends SceneTree

const DataManagerScript := preload("res://scripts/core/DataManager.gd")
const InventoryScript := preload("res://scripts/inventory/Inventory.gd")
const ShopManagerScript := preload("res://scripts/shop/ShopManager.gd")

func _init() -> void:
	var data_manager = DataManagerScript.new()
	data_manager.load_all()

	var inventory = InventoryScript.new()
	inventory.setup_starter_items()

	var shop = ShopManagerScript.new()
	shop.setup(data_manager.items)

	var seed_ids: Array[String] = ["turnip_seed", "potato_seed", "cabbage_seed", "corn_seed"]
	for seed_id in seed_ids:
		inventory.money = 200
		var before_count := inventory.count(seed_id)
		var price := int(data_manager.items[seed_id].get("price", 0))
		var result: Dictionary = shop.buy_item(inventory, seed_id, 1)
		if not bool(result.get("success", false)):
			_fail("Buying %s should succeed with enough money." % seed_id)
			return
		if inventory.money != 200 - price:
			_fail("Buying %s should deduct its price." % seed_id)
			return
		if inventory.count(seed_id) != before_count + 1:
			_fail("Buying %s should add one seed." % seed_id)
			return

	inventory.money = 10
	var corn_before := inventory.count("corn_seed")
	var failed_buy: Dictionary = shop.buy_item(inventory, "corn_seed", 1)
	if bool(failed_buy.get("success", true)):
		_fail("Buying corn seed should fail when money is too low.")
		return
	if inventory.money != 10 or inventory.count("corn_seed") != corn_before:
		_fail("Failed purchase should not change money or inventory.")
		return

	inventory.money = 0
	inventory.add_item("turnip", 2)
	inventory.add_item("potato", 1)
	var sell_result: Dictionary = shop.sell_all_crops(inventory, ["turnip", "potato", "cabbage", "corn"])
	if not bool(sell_result.get("success", false)):
		_fail("Selling harvested crops should succeed.")
		return
	if inventory.money != 210:
		_fail("Selling 2 turnips and 1 potato should earn 210 gold.")
		return
	if inventory.count("turnip") != 0 or inventory.count("potato") != 0:
		_fail("Selling crops should remove sold crops from inventory.")
		return

	inventory.money = 0
	inventory.add_item("egg", 2)
	inventory.add_item("milk", 1)
	var animal_sell_result: Dictionary = shop.sell_all_items(inventory, ["egg", "milk"])
	if not bool(animal_sell_result.get("success", false)):
		_fail("Selling animal products should succeed.")
		return
	if inventory.money != 170:
		_fail("Selling 2 eggs and 1 milk should earn 170 gold.")
		return
	if inventory.count("egg") != 0 or inventory.count("milk") != 0:
		_fail("Selling animal products should remove sold items from inventory.")
		return

	inventory.money = 0
	inventory.add_item("dried_turnip", 1)
	inventory.add_item("mayonnaise", 2)
	var processed_sell_result: Dictionary = shop.sell_all_items(inventory, ["dried_turnip", "mayonnaise"])
	if not bool(processed_sell_result.get("success", false)):
		_fail("Selling processed goods should succeed.")
		return
	if inventory.money != 275:
		_fail("Selling 1 dried turnip and 2 mayonnaise should earn 275 gold.")
		return
	if inventory.count("dried_turnip") != 0 or inventory.count("mayonnaise") != 0:
		_fail("Selling processed goods should remove sold items from inventory.")
		return

	print("PASS shop_loop_test")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
