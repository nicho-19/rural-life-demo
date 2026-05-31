extends SceneTree

const DataManagerScript := preload("res://scripts/core/DataManager.gd")
const InventoryScript := preload("res://scripts/inventory/Inventory.gd")
const OrderManagerScript := preload("res://scripts/orders/OrderManager.gd")

func _init() -> void:
	var data_manager = DataManagerScript.new()
	data_manager.load_all()

	var inventory = InventoryScript.new()
	inventory.setup_starter_items()

	var orders = OrderManagerScript.new()
	orders.setup(data_manager.items)
	orders.start_day(1)

	var money_before: int = inventory.money
	var turnip_before: int = inventory.count("turnip")
	var failed_delivery: Dictionary = orders.deliver_order(inventory)
	if bool(failed_delivery.get("success", true)):
		_fail("Optional order delivery should fail when crops are missing.")
		return
	if inventory.money != money_before or inventory.count("turnip") != turnip_before:
		_fail("Failed optional order delivery should not change money or inventory.")
		return
	if not String(failed_delivery.get("message", "")).contains("可选"):
		_fail("Missing crops should be framed as optional, not mandatory.")
		return

	orders.start_day(2)
	if inventory.money != money_before:
		_fail("Ignoring yesterday's optional order should not penalize money.")
		return

	inventory.add_item("potato", 2)
	var reward := int(orders.current_order.get("reward", 0))
	var delivered: Dictionary = orders.deliver_order(inventory)
	if not bool(delivered.get("success", false)):
		_fail("Delivery should succeed when required crops are available.")
		return
	if inventory.count("potato") != 0:
		_fail("Successful delivery should remove required crops.")
		return
	if inventory.money != money_before + reward:
		_fail("Successful delivery should add the order reward.")
		return
	if not bool(orders.current_order.get("completed", false)):
		_fail("Successful delivery should mark today's order complete.")
		return

	print("PASS optional_order_test")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
