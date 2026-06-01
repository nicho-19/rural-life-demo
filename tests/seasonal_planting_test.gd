extends SceneTree

const FarmManagerScript := preload("res://scripts/farm/FarmManager.gd")
const InventoryScript := preload("res://scripts/inventory/Inventory.gd")

func _init() -> void:
	var farm = FarmManagerScript.new()
	farm.setup({
		"turnip": {"name": "Turnip", "seed_item": "turnip_seed", "grow_days": 3, "season": ["spring", "summer"]},
		"corn": {"name": "Corn", "seed_item": "corn_seed", "grow_days": 6, "season": ["summer"]},
	})

	var inventory = InventoryScript.new()
	inventory.add_item("corn_seed", 1)
	inventory.add_item("turnip_seed", 1)

	var first_tile_position := Vector2(528, 296)
	farm.interact_at(first_tile_position, inventory, "corn_seed", "spring")
	var failed_message := farm.interact_at(first_tile_position, inventory, "corn_seed", "spring")
	var blocked_tile: Dictionary = farm.tiles[Vector2i(0, 0)]
	if int(blocked_tile.get("state", -1)) != FarmManagerScript.TileState.TILLED:
		_fail(farm, "Out-of-season planting should leave the tile tilled.")
		return
	if inventory.count("corn_seed") != 1:
		_fail(farm, "Out-of-season planting should not consume the seed.")
		return
	if not failed_message.contains("season"):
		_fail(farm, "Out-of-season planting should explain the seasonal reason.")
		return

	var second_tile_position := Vector2(560, 296)
	farm.interact_at(second_tile_position, inventory, "corn_seed", "summer")
	farm.interact_at(second_tile_position, inventory, "corn_seed", "summer")
	var planted_tile: Dictionary = farm.tiles[Vector2i(1, 0)]
	if int(planted_tile.get("state", -1)) != FarmManagerScript.TileState.PLANTED:
		_fail(farm, "In-season planting should plant the selected crop.")
		return
	if String(planted_tile.get("crop_id", "")) != "corn":
		_fail(farm, "In-season planting should keep the selected crop id.")
		return
	if inventory.count("corn_seed") != 0:
		_fail(farm, "In-season planting should consume one seed.")
		return

	for _day in 6:
		farm.interact_at(second_tile_position, inventory, "corn_seed", "winter")
		farm.advance_day()
	if int(planted_tile.get("state", -1)) != FarmManagerScript.TileState.READY:
		_fail(farm, "Already planted crops should keep growing across seasons.")
		return

	farm.free()
	print("PASS seasonal_planting_test")
	quit(0)


func _fail(farm: Node, message: String) -> void:
	farm.free()
	push_error(message)
	quit(1)
