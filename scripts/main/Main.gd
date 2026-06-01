extends Node2D

const FarmManagerScript := preload("res://scripts/farm/FarmManager.gd")
const InventoryScript := preload("res://scripts/inventory/Inventory.gd")
const DataManagerScript := preload("res://scripts/core/DataManager.gd")
const TimeManagerScript := preload("res://scripts/core/TimeManager.gd")
const ShopManagerScript := preload("res://scripts/shop/ShopManager.gd")
const OrderManagerScript := preload("res://scripts/orders/OrderManager.gd")
const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")
const StatsManagerScript := preload("res://scripts/stats/StatsManager.gd")
const WeatherManagerScript := preload("res://scripts/weather/WeatherManager.gd")
const MilestoneManagerScript := preload("res://scripts/milestones/MilestoneManager.gd")
const JournalManagerScript := preload("res://scripts/journal/JournalManager.gd")
const BriefingManagerScript := preload("res://scripts/briefing/BriefingManager.gd")
const AnimalManagerScript := preload("res://scripts/animals/AnimalManager.gd")
const MainUiScript := preload("res://scripts/main/MainUi.gd")

const SEED_ITEMS: Array[String] = ["turnip_seed", "potato_seed", "cabbage_seed", "corn_seed"]
const CROP_ITEMS: Array[String] = ["turnip", "potato", "cabbage", "corn"]
const ANIMAL_PRODUCT_ITEMS: Array[String] = ["egg", "milk"]
const SELLABLE_ITEMS: Array[String] = ["turnip", "potato", "cabbage", "corn", "egg", "milk"]

@onready var player: CharacterBody2D = $Player

var data_manager
var time_manager
var farm_manager
var inventory
var shop_manager
var order_manager
var save_manager
var stats_manager
var weather_manager
var milestone_manager
var journal_manager
var briefing_manager
var animal_manager
var selected_seed_item_id := "turnip_seed"
var recent_milestone_message := ""
var ui
var target_info: Dictionary = {}

func _ready() -> void:
	data_manager = DataManagerScript.new()
	data_manager.load_all()

	time_manager = TimeManagerScript.new()
	add_child(time_manager)

	farm_manager = FarmManagerScript.new()
	add_child(farm_manager)
	farm_manager.setup(data_manager.crops)

	inventory = InventoryScript.new()
	inventory.setup_starter_items()

	shop_manager = ShopManagerScript.new()
	shop_manager.setup(data_manager.items)

	order_manager = OrderManagerScript.new()
	order_manager.setup(data_manager.items)
	order_manager.start_day(time_manager.day)

	stats_manager = StatsManagerScript.new()

	weather_manager = WeatherManagerScript.new()
	weather_manager.start_day(time_manager.day)

	milestone_manager = MilestoneManagerScript.new()

	journal_manager = JournalManagerScript.new()
	briefing_manager = BriefingManagerScript.new()
	animal_manager = AnimalManagerScript.new()

	save_manager = SaveManagerScript.new()
	var start_message := "早上好。靠近农田按 E，或直接点击农田开始干活。"
	if _should_auto_load():
		var load_result := _load_game_state()
		if bool(load_result.get("success", false)):
			start_message = "已自动读取上次存档。"

	_build_ui()
	_update_ui(start_message)
	refresh_inventory_ui()
	_update_target_hint()


func _process(delta: float) -> void:
	time_manager.tick(delta)
	_update_target_hint()
	queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo:
		return

	match event.physical_keycode:
		KEY_E, KEY_SPACE:
			_interact_with_farm_at(player.facing_position())
		KEY_F:
			_feed_animals()
		KEY_L:
			_toggle_animals()
		KEY_X:
			_buy_farm_expansion()
		KEY_R:
			_toggle_briefing()
		KEY_N:
			_next_day()
		KEY_M:
			_sell_all_crops()
		KEY_O:
			_deliver_order()
		KEY_F5:
			_save_game()
		KEY_F9:
			_load_game()
		KEY_I:
			_toggle_stats()
		KEY_H:
			_toggle_help()
		KEY_J:
			_toggle_journal()
		KEY_B:
			_toggle_shop()
		KEY_1:
			_select_seed(SEED_ITEMS[0])
		KEY_2:
			_select_seed(SEED_ITEMS[1])
		KEY_3:
			_select_seed(SEED_ITEMS[2])
		KEY_4:
			_select_seed(SEED_ITEMS[3])


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_interact_with_farm_at(get_global_mouse_position())


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("#89c779"))
	draw_rect(Rect2(Vector2(0, 500), Vector2(1280, 220)), Color("#d9b77f"))
	draw_rect(Rect2(Vector2(0, 0), Vector2(1280, 90)), weather_manager.sky_color())
	if weather_manager.is_rainy():
		for x in range(0, 1280, 26):
			draw_line(Vector2(x, 96), Vector2(x - 8, 122), Color("#d7edf7"), 1.0)
	draw_rect(Rect2(Vector2(420, 210), Vector2(380, 280)), Color("#9b7043"))
	_draw_animal_area()
	var highlighted_cell = target_info.get("cell") if bool(target_info.get("valid", false)) else null
	farm_manager.draw_farm(self, highlighted_cell)


func _interact_with_farm_at(world_position: Vector2) -> void:
	var before_seeds := _counts_for(SEED_ITEMS)
	var before_crops := _counts_for(CROP_ITEMS)
	var result: String = farm_manager.interact_at(world_position, inventory, selected_seed_item_id)
	_record_farm_changes(before_seeds, before_crops)
	_check_milestones()
	_record_journal(result)
	_update_ui(result)
	refresh_inventory_ui()
	_update_target_hint()


func _next_day() -> void:
	var rain_message := ""
	if weather_manager.is_rainy():
		var watered_count: int = farm_manager.water_all_planted()
		if watered_count > 0:
			rain_message = "雨水帮你浇灌了 %d 块作物。" % watered_count
			_record_journal(rain_message)

	time_manager.next_day()
	farm_manager.advance_day()
	var animal_result: Dictionary = animal_manager.advance_day(inventory)
	order_manager.start_day(time_manager.day)
	weather_manager.start_day(time_manager.day)
	var message := "睡了一觉。第 %d 天开始，新的可选订单来了；不做也没关系。" % time_manager.day
	if int(animal_result.get("egg", 0)) > 0 or int(animal_result.get("milk", 0)) > 0:
		var animal_message := String(animal_result.get("message", ""))
		message = "%s\n%s" % [animal_message, message]
		_record_journal(animal_message)
	if not rain_message.is_empty():
		message = "%s\n%s" % [rain_message, message]
	_record_journal("进入第 %d 天。%s" % [time_manager.day, weather_manager.describe()])
	if ui.briefing_panel != null:
		ui.briefing_panel.visible = true
	_update_ui(message)
	refresh_inventory_ui()
	_update_target_hint()


func _sell_all_crops() -> void:
	var before_crops := _counts_for(CROP_ITEMS)
	var money_before: int = inventory.money
	var result: Dictionary = shop_manager.sell_all_items(inventory, SELLABLE_ITEMS)
	if bool(result.get("success", false)):
		_record_sold_changes(before_crops, inventory.money - money_before)
	_check_milestones()
	_record_journal(String(result.get("message", "")))
	_update_ui(String(result.get("message", "没有可以出售的农产品。")))
	refresh_inventory_ui()
	_update_target_hint()


func _deliver_order() -> void:
	var money_before: int = inventory.money
	var result: Dictionary = order_manager.deliver_order(inventory)
	if bool(result.get("success", false)):
		stats_manager.record_order_completed(inventory.money - money_before)
	_check_milestones()
	_record_journal(String(result.get("message", "")))
	_update_ui(String(result.get("message", "订单交付失败。")))
	refresh_inventory_ui()
	_update_target_hint()


func _buy_farm_expansion() -> void:
	var result: Dictionary = farm_manager.buy_expansion(inventory)
	if bool(result.get("success", false)):
		_record_journal(String(result.get("message", "")))
	_update_ui(String(result.get("message", "扩建失败。")))
	refresh_inventory_ui()
	_update_target_hint()


func _buy_chicken() -> void:
	var result: Dictionary = animal_manager.buy_chicken(inventory)
	if bool(result.get("success", false)):
		_record_journal(String(result.get("message", "")))
	_update_ui(String(result.get("message", "买鸡失败。")))
	refresh_inventory_ui()
	_update_animal_ui()
	_update_target_hint()


func _buy_cow() -> void:
	var result: Dictionary = animal_manager.buy_cow(inventory)
	if bool(result.get("success", false)):
		_record_journal(String(result.get("message", "")))
	_update_ui(String(result.get("message", "买牛失败。")))
	refresh_inventory_ui()
	_update_animal_ui()
	_update_target_hint()


func _buy_animal_feed() -> void:
	var result: Dictionary = shop_manager.buy_item(inventory, AnimalManagerScript.FEED_ITEM_ID, 5)
	if bool(result.get("success", false)):
		_record_journal(String(result.get("message", "")))
	_update_ui(String(result.get("message", "购买饲料失败。")))
	refresh_inventory_ui()
	_update_shop_ui()
	_update_animal_ui()
	_update_target_hint()


func _feed_animals() -> void:
	var result: Dictionary = animal_manager.feed_all(inventory)
	if bool(result.get("success", false)):
		_record_journal(String(result.get("message", "")))
	_update_ui(String(result.get("message", "喂养失败。")))
	refresh_inventory_ui()
	_update_animal_ui()
	_update_target_hint()


func _save_game() -> void:
	var result: Dictionary = save_manager.save_game(
		SaveManagerScript.SAVE_PATH,
		inventory,
		farm_manager,
		time_manager,
		order_manager,
		selected_seed_item_id,
		stats_manager,
		weather_manager,
		milestone_manager,
		journal_manager,
		animal_manager
	)
	_update_ui(String(result.get("message", "存档失败。")))
	refresh_inventory_ui()
	_update_target_hint()


func _load_game() -> void:
	var result: Dictionary = _load_game_state()
	_update_ui(String(result.get("message", "读档失败。")))
	refresh_inventory_ui()
	_update_target_hint()


func _load_game_state() -> Dictionary:
	var loaded: Dictionary = save_manager.load_game(SaveManagerScript.SAVE_PATH)
	if not bool(loaded.get("success", false)):
		return loaded

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
		animal_manager
	)
	var saved_seed := String(applied.get("selected_seed_item_id", selected_seed_item_id))
	if SEED_ITEMS.has(saved_seed):
		selected_seed_item_id = saved_seed
	return applied


func _buy_seed(seed_item_id: String) -> void:
	var result: Dictionary = shop_manager.buy_item(inventory, seed_item_id, 1)
	if bool(result.get("success", false)):
		_select_seed(seed_item_id, false)
	_update_ui(String(result.get("message", "购买失败。")))
	refresh_inventory_ui()
	_update_shop_ui()
	_update_target_hint()


func _select_seed(seed_item_id: String, show_message: bool = true) -> void:
	if not SEED_ITEMS.has(seed_item_id):
		return
	selected_seed_item_id = seed_item_id
	if show_message:
		_update_ui("当前选择：%s。" % _item_name(seed_item_id))
	refresh_inventory_ui()
	_update_target_hint()


func _toggle_shop() -> void:
	ui.shop_panel.visible = not ui.shop_panel.visible
	_update_shop_ui()
	if ui.shop_panel.visible:
		_update_ui("商店打开了。点击按钮购买种子，按 B 关闭。")
	else:
		_update_ui("商店关闭。")


func _toggle_stats() -> void:
	ui.stats_panel.visible = not ui.stats_panel.visible
	_update_stats_ui()
	if ui.stats_panel.visible:
		_update_ui("图鉴打开了。这里只有记录和回忆，不会强迫你完成任何东西。")
	else:
		_update_ui("图鉴关闭。")


func _toggle_help() -> void:
	ui.help_panel.visible = not ui.help_panel.visible
	if ui.help_panel.visible:
		_update_ui("帮助打开了。这里是自由经营提示，不是任务要求。")
	else:
		_update_ui("帮助关闭。")


func _toggle_journal() -> void:
	ui.journal_panel.visible = not ui.journal_panel.visible
	_update_journal_ui()
	if ui.journal_panel.visible:
		_update_ui("日记打开了。这里记录农场故事，不是待办清单。")
	else:
		_update_ui("日记关闭。")


func _toggle_briefing() -> void:
	ui.briefing_panel.visible = not ui.briefing_panel.visible
	_update_briefing_ui()
	if ui.briefing_panel.visible:
		_update_ui("晨间简报打开了。它只帮你回忆今天的情况。")
	else:
		_update_ui("晨间简报关闭。")


func _toggle_animals() -> void:
	ui.animal_panel.visible = not ui.animal_panel.visible
	_update_animal_ui()
	if ui.animal_panel.visible:
		_update_ui("动物棚打开了。可以买鸡、买牛、买饲料，也可以喂全部动物。")
	else:
		_update_ui("动物棚关闭。")


func _build_ui() -> void:
	ui = MainUiScript.new()
	ui.build(self, data_manager, SEED_ITEMS, CROP_ITEMS, AnimalManagerScript.FEED_ITEM_ID)


func _update_ui(message: String) -> void:
	ui.update_ui(
		message,
		time_manager,
		inventory,
		selected_seed_item_id,
		data_manager,
		order_manager,
		weather_manager,
		milestone_manager,
		recent_milestone_message,
		journal_manager,
		briefing_manager,
		animal_manager,
		farm_manager,
		FarmManagerScript,
		AnimalManagerScript,
		stats_manager
	)


func refresh_inventory_ui() -> void:
	ui.refresh_inventory(
		inventory,
		selected_seed_item_id,
		data_manager,
		order_manager,
		weather_manager,
		milestone_manager,
		recent_milestone_message,
		journal_manager,
		briefing_manager,
		animal_manager,
		time_manager,
		farm_manager,
		FarmManagerScript,
		AnimalManagerScript,
		stats_manager
	)


func _update_shop_ui() -> void:
	ui.update_shop(inventory, data_manager)


func _update_target_hint() -> void:
	target_info = ui.update_target_hint(farm_manager, player, selected_seed_item_id)


func _update_order_ui() -> void:
	ui.update_order(inventory, order_manager)


func _update_weather_ui() -> void:
	ui.update_weather(weather_manager)


func _update_milestone_ui() -> void:
	ui.update_milestone(milestone_manager, recent_milestone_message)


func _update_journal_ui() -> void:
	ui.update_journal(journal_manager)


func _update_briefing_ui() -> void:
	ui.update_briefing(time_manager, inventory, order_manager, weather_manager, milestone_manager, recent_milestone_message, briefing_manager, animal_manager)


func _update_animal_ui() -> void:
	ui.update_animal(inventory, animal_manager, AnimalManagerScript)


func _update_farm_size_ui() -> void:
	ui.update_farm_size(farm_manager, FarmManagerScript)


func _update_stats_ui() -> void:
	ui.update_stats(stats_manager, data_manager)

func _item_name(item_id: String) -> String:
	var item: Dictionary = data_manager.items.get(item_id, {})
	return String(item.get("name", item_id))


func _draw_animal_area() -> void:
	draw_rect(Rect2(Vector2(840, 340), Vector2(170, 82)), Color("#b98555"))
	draw_rect(Rect2(Vector2(858, 304), Vector2(56, 48)), Color("#8f5d3b"))
	draw_rect(Rect2(Vector2(936, 304), Vector2(66, 54)), Color("#7f573d"))
	draw_rect(Rect2(Vector2(858, 304), Vector2(56, 48)), Color("#5f4328"), false, 2.0)
	draw_rect(Rect2(Vector2(936, 304), Vector2(66, 54)), Color("#5f4328"), false, 2.0)

	for index in animal_manager.chickens:
		var x: int = 864 + (index % 4) * 18
		var y: int = 382 + int(index / 4) * 18
		draw_circle(Vector2(x, y), 7.0, Color("#fff4c7"))
		draw_circle(Vector2(x + 4, y - 3), 2.0, Color("#d6513b"))

	for index in animal_manager.cows:
		var x: int = 940 + index * 28
		var y: int = 386
		draw_rect(Rect2(Vector2(x, y - 8), Vector2(22, 14)), Color("#f5efe5"))
		draw_circle(Vector2(x + 5, y - 2), 3.0, Color("#4f3a2e"))
		draw_circle(Vector2(x + 16, y + 1), 3.0, Color("#4f3a2e"))


func _check_milestones() -> void:
	var messages: Array[String] = milestone_manager.check(stats_manager, inventory)
	if messages.is_empty():
		return
	recent_milestone_message = messages[messages.size() - 1]
	_record_journal(recent_milestone_message)
	_update_milestone_ui()


func _record_journal(message: String) -> void:
	if journal_manager == null:
		return
	journal_manager.add_entry(time_manager.day, message)


func _counts_for(item_ids: Array[String]) -> Dictionary:
	var counts: Dictionary = {}
	for item_id in item_ids:
		counts[item_id] = inventory.count(item_id)
	return counts


func _record_farm_changes(before_seeds: Dictionary, before_crops: Dictionary) -> void:
	for seed_item_id in SEED_ITEMS:
		if inventory.count(seed_item_id) < int(before_seeds.get(seed_item_id, 0)):
			var crop_id: String = farm_manager.crop_id_for_seed(seed_item_id)
			if not crop_id.is_empty():
				stats_manager.record_planted(crop_id)

	for crop_id in CROP_ITEMS:
		var delta: int = inventory.count(crop_id) - int(before_crops.get(crop_id, 0))
		if delta > 0:
			stats_manager.record_harvested(crop_id, delta)


func _record_sold_changes(before_crops: Dictionary, earned: int) -> void:
	for crop_id in CROP_ITEMS:
		var sold_count: int = int(before_crops.get(crop_id, 0)) - inventory.count(crop_id)
		if sold_count > 0:
			var sell_price := int(data_manager.items[crop_id].get("sell_price", 0))
			stats_manager.record_sold(crop_id, sold_count, sell_price * sold_count)


func _should_auto_load() -> bool:
	for arg in OS.get_cmdline_args():
		if String(arg).contains("res://tests/"):
			return false
	return true
