extends SceneTree

const FarmManagerScript := preload("res://scripts/farm/FarmManager.gd")
const InventoryScript := preload("res://scripts/inventory/Inventory.gd")

func _init() -> void:
	var farm = FarmManagerScript.new()
	farm.setup({"turnip": {"name": "萝卜", "seed_item": "turnip_seed", "grow_days": 3}})
	var inventory = InventoryScript.new()
	inventory.money = 300

	var outside_before: Dictionary = farm.get_target_info(Vector2(512 + 8 * 32 + 16, 296))
	if bool(outside_before.get("valid", false)):
		_fail(farm, "Column 9 should be locked before expansion.")
		return

	var result: Dictionary = farm.buy_expansion(inventory)
	if not bool(result.get("success", false)):
		_fail(farm, "Farm expansion should succeed when the player has enough money.")
		return
	if inventory.money != 50:
		_fail(farm, "Farm expansion should charge the configured cost.")
		return
	if farm.width != 9 or farm.height != 5:
		_fail(farm, "First expansion should add one farm column.")
		return

	var outside_after: Dictionary = farm.get_target_info(Vector2(512 + 8 * 32 + 16, 296))
	if not bool(outside_after.get("valid", false)):
		_fail(farm, "Newly expanded farm tile should become targetable.")
		return

	var saved: Dictionary = farm.to_save_data()
	farm.setup({"turnip": {"name": "萝卜", "seed_item": "turnip_seed", "grow_days": 3}})
	farm.load_save_data(saved)
	if farm.width != 9 or farm.height != 5:
		_fail(farm, "Farm expansion should survive save/load.")
		return

	farm.free()
	print("PASS farm_expansion_test")
	quit(0)


func _fail(farm: Node, message: String) -> void:
	farm.free()
	push_error(message)
	quit(1)
