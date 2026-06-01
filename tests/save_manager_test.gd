extends SceneTree

const DataManagerScript := preload("res://scripts/core/DataManager.gd")
const InventoryScript := preload("res://scripts/inventory/Inventory.gd")
const TimeManagerScript := preload("res://scripts/core/TimeManager.gd")
const FarmManagerScript := preload("res://scripts/farm/FarmManager.gd")
const OrderManagerScript := preload("res://scripts/orders/OrderManager.gd")
const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")
const StatsManagerScript := preload("res://scripts/stats/StatsManager.gd")
const WeatherManagerScript := preload("res://scripts/weather/WeatherManager.gd")
const MilestoneManagerScript := preload("res://scripts/milestones/MilestoneManager.gd")
const JournalManagerScript := preload("res://scripts/journal/JournalManager.gd")
const AnimalManagerScript := preload("res://scripts/animals/AnimalManager.gd")
const NpcRelationshipManagerScript := preload("res://scripts/npcs/NpcRelationshipManager.gd")

func _init() -> void:
	var data_manager = DataManagerScript.new()
	data_manager.load_all()

	var inventory = InventoryScript.new()
	inventory.setup_starter_items()
	inventory.money = 1425
	inventory.add_item("potato_seed", 3)
	inventory.add_item("cabbage", 2)
	inventory.add_item("cheese", 1)

	var time_manager = TimeManagerScript.new()
	time_manager.day = 4
	time_manager.hour = 17
	time_manager.minute = 45

	var farm_manager = FarmManagerScript.new()
	farm_manager.setup(data_manager.crops)
	var expansion_result: Dictionary = farm_manager.buy_expansion(inventory)
	if not bool(expansion_result.get("success", false)):
		_fail("save_manager_test should be able to expand the farm before saving.")
		return
	var farm_position := Vector2(528, 296)
	farm_manager.interact_at(farm_position, inventory, "potato_seed")
	farm_manager.interact_at(farm_position, inventory, "potato_seed")
	farm_manager.interact_at(farm_position, inventory, "potato_seed")
	farm_manager.advance_day()

	var order_manager = OrderManagerScript.new()
	order_manager.setup(data_manager.items)
	order_manager.start_day(4)

	var stats_manager = StatsManagerScript.new()
	stats_manager.record_planted("potato")
	stats_manager.record_harvested("cabbage", 2)

	var weather_manager = WeatherManagerScript.new()
	weather_manager.start_day(3)

	var milestone_manager = MilestoneManagerScript.new()
	milestone_manager.check(stats_manager, inventory)

	var journal_manager = JournalManagerScript.new()
	journal_manager.add_entry(4, "测试日记。")

	var animal_manager = AnimalManagerScript.new()
	animal_manager.buy_chicken(inventory)
	animal_manager.buy_cow(inventory)
	inventory.add_item("animal_feed", 2)
	animal_manager.feed_all(inventory)

	var npc_manager = NpcRelationshipManagerScript.new()
	npc_manager.setup(data_manager.npcs)
	inventory.add_item("turnip", 1)
	npc_manager.give_gift("mayor_lin", "turnip", inventory, time_manager.day)

	var save_manager = SaveManagerScript.new()
	var save_path := "user://save_manager_test.json"
	var saved: Dictionary = save_manager.save_game(
		save_path,
		inventory,
		farm_manager,
		time_manager,
		order_manager,
		"potato_seed",
		stats_manager,
		weather_manager,
		milestone_manager,
		journal_manager,
		animal_manager,
		npc_manager
	)
	if not bool(saved.get("success", false)):
		_fail("save_game should write a save file.")
		return

	inventory.money = 1
	inventory.items.clear()
	time_manager.day = 1
	time_manager.hour = 6
	time_manager.minute = 0
	farm_manager.setup(data_manager.crops)
	order_manager.start_day(1)
	stats_manager.load_save_data({})
	weather_manager.start_day(1)
	milestone_manager.load_save_data({})
	journal_manager.load_save_data({})
	animal_manager.load_save_data({})
	npc_manager.load_save_data({})

	var loaded: Dictionary = save_manager.load_game(save_path)
	if not bool(loaded.get("success", false)):
		_fail("load_game should read a save file.")
		return

	var applied: Dictionary = save_manager.apply_save_data(
		loaded.get("data", {}),
		inventory,
		farm_manager,
		time_manager,
		order_manager,
		stats_manager,
		weather_manager,
		milestone_manager,
		journal_manager,
		animal_manager,
		npc_manager
	)
	if not bool(applied.get("success", false)):
		_fail("apply_save_data should restore managers from the save.")
		return

	if inventory.money != 275:
		_fail("Loaded save should restore money.")
		return
	if inventory.count("potato_seed") != 2 or inventory.count("cabbage") != 2 or inventory.count("cheese") != 1:
		_fail("Loaded save should restore inventory items.")
		return
	if time_manager.day != 4 or time_manager.hour != 17 or time_manager.minute != 45:
		_fail("Loaded save should restore time.")
		return

	var tile: Dictionary = farm_manager.tiles[Vector2i(0, 0)]
	if String(tile.get("crop_id", "")) != "potato" or int(tile.get("state", -1)) != FarmManagerScript.TileState.PLANTED:
		_fail("Loaded save should restore farm tile crop and state.")
		return
	if farm_manager.width != 9 or farm_manager.height != 5:
		_fail("Loaded save should restore farm expansion size.")
		return
	if String(applied.get("selected_seed_item_id", "")) != "potato_seed":
		_fail("Loaded save should return the selected seed item.")
		return
	var loaded_requirements: Dictionary = order_manager.current_order.get("requirements", {})
	if int(loaded_requirements.get("potato", 0)) != 1 or int(loaded_requirements.get("corn", 0)) != 1:
		_fail("Loaded save should restore the current optional order.")
		return
	if stats_manager.count_planted("potato") != 1 or stats_manager.count_harvested("cabbage") != 2:
		_fail("Loaded save should restore farm stats.")
		return
	if not weather_manager.is_rainy():
		_fail("Loaded save should restore weather.")
		return
	if not milestone_manager.check(stats_manager, inventory).is_empty():
		_fail("Loaded save should restore unlocked milestones.")
		return
	if not journal_manager.describe_recent().contains("测试日记"):
		_fail("Loaded save should restore journal entries.")
		return
	if animal_manager.chickens != 1 or animal_manager.cows != 1:
		_fail("Loaded save should restore livestock counts.")
		return
	if animal_manager.fed_chickens != 1 or animal_manager.fed_cows != 1:
		_fail("Loaded save should restore livestock feeding state.")
		return
	if npc_manager.friendship_for("mayor_lin") != 12:
		_fail("Loaded save should restore NPC friendship.")
		return
	if not npc_manager.was_gifted_today("mayor_lin", 4):
		_fail("Loaded save should restore today's NPC gift state.")
		return

	farm_manager.free()
	time_manager.free()
	print("PASS save_manager_test")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
