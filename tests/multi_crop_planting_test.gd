extends SceneTree

const FarmManagerScript := preload("res://scripts/farm/FarmManager.gd")
const InventoryScript := preload("res://scripts/inventory/Inventory.gd")

func _init() -> void:
	var farm = FarmManagerScript.new()
	farm.setup({
		"turnip": {"name": "萝卜", "seed_item": "turnip_seed", "grow_days": 3},
		"potato": {"name": "土豆", "seed_item": "potato_seed", "grow_days": 4},
		"cabbage": {"name": "白菜", "seed_item": "cabbage_seed", "grow_days": 5},
		"corn": {"name": "玉米", "seed_item": "corn_seed", "grow_days": 6},
	})

	var inventory = InventoryScript.new()
	inventory.add_item("potato_seed", 1)

	var first_tile_position := Vector2(528, 296)
	farm.interact_at(first_tile_position, inventory, "potato_seed")
	farm.interact_at(first_tile_position, inventory, "potato_seed")

	var planted_tile: Dictionary = farm.tiles[Vector2i(0, 0)]
	if String(planted_tile.get("crop_id", "")) != "potato":
		_fail("Selected potato seed should plant a potato crop.")
		return
	if inventory.count("potato_seed") != 0:
		_fail("Planting should consume one selected seed.")
		return

	for _day in 4:
		farm.interact_at(first_tile_position, inventory, "potato_seed")
		farm.advance_day()

	if int(planted_tile.get("state", -1)) != FarmManagerScript.TileState.READY:
		_fail("Potato should be ready after four watered days.")
		return

	farm.interact_at(first_tile_position, inventory, "potato_seed")
	if inventory.count("potato") != 1:
		_fail("Harvesting a mature potato should add one potato.")
		return

	var second_tile_position := Vector2(560, 296)
	farm.interact_at(second_tile_position, inventory, "cabbage_seed")
	var failed_message := farm.interact_at(second_tile_position, inventory, "cabbage_seed")
	var second_tile: Dictionary = farm.tiles[Vector2i(1, 0)]
	if int(second_tile.get("state", -1)) != FarmManagerScript.TileState.TILLED:
		_fail("Planting without enough selected seed should leave the tile tilled.")
		return
	if not failed_message.contains("不够"):
		_fail("Planting without enough seed should explain the shortage.")
		return

	farm.free()
	print("PASS multi_crop_planting_test")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
