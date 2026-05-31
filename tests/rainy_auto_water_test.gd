extends SceneTree

const FarmManagerScript := preload("res://scripts/farm/FarmManager.gd")
const InventoryScript := preload("res://scripts/inventory/Inventory.gd")
const WeatherManagerScript := preload("res://scripts/weather/WeatherManager.gd")

func _init() -> void:
	var farm = FarmManagerScript.new()
	farm.setup({
		"turnip": {"name": "萝卜", "seed_item": "turnip_seed", "grow_days": 3},
	})

	var inventory = InventoryScript.new()
	inventory.add_item("turnip_seed", 1)

	var tile_position := Vector2(528, 296)
	farm.interact_at(tile_position, inventory, "turnip_seed")
	farm.interact_at(tile_position, inventory, "turnip_seed")

	var tile_before: Dictionary = farm.tiles[Vector2i(0, 0)]
	if int(tile_before.get("state", -1)) != FarmManagerScript.TileState.PLANTED:
		_fail("Test setup should leave a planted but unwatered crop.")
		return

	var weather = WeatherManagerScript.new()
	weather.start_day(3)
	var watered := farm.water_all_planted() if weather.is_rainy() else 0
	farm.advance_day()

	var tile_after: Dictionary = farm.tiles[Vector2i(0, 0)]
	if watered != 1:
		_fail("Rainy days should water planted crops automatically.")
		return
	if int(tile_after.get("growth", 0)) != 1:
		_fail("A crop watered by rain should grow overnight.")
		return
	if int(tile_after.get("state", -1)) != FarmManagerScript.TileState.PLANTED:
		_fail("Rain should not skip growth stages or force harvest readiness.")
		return

	farm.free()
	print("PASS rainy_auto_water_test")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
