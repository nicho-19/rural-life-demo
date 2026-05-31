extends SceneTree

const DataManagerScript := preload("res://scripts/core/DataManager.gd")

func _init() -> void:
	var data_manager = DataManagerScript.new()
	data_manager.load_all()

	var expected_crops := {
		"turnip": {"seed": "turnip_seed", "price": 20, "sell": 60, "days": 3},
		"potato": {"seed": "potato_seed", "price": 30, "sell": 90, "days": 4},
		"cabbage": {"seed": "cabbage_seed", "price": 40, "sell": 130, "days": 5},
		"corn": {"seed": "corn_seed", "price": 50, "sell": 160, "days": 6},
	}

	for crop_id in expected_crops.keys():
		var expected: Dictionary = expected_crops[crop_id]
		if not data_manager.crops.has(crop_id):
			_fail("Missing crop: %s" % crop_id)
			return
		if not data_manager.items.has(expected["seed"]):
			_fail("Missing seed item: %s" % expected["seed"])
			return
		if int(data_manager.items[expected["seed"]].get("price", 0)) != int(expected["price"]):
			_fail("Seed price mismatch for %s" % expected["seed"])
			return
		if int(data_manager.items[crop_id].get("sell_price", 0)) != int(expected["sell"]):
			_fail("Sell price mismatch for %s" % crop_id)
			return
		if int(data_manager.crops[crop_id].get("grow_days", 0)) != int(expected["days"]):
			_fail("Grow days mismatch for %s" % crop_id)
			return

	print("PASS multi_crop_data_test")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
