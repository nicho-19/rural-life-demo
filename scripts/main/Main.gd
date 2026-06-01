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
const CraftingManagerScript := preload("res://scripts/crafting/CraftingManager.gd")
const NpcRelationshipManagerScript := preload("res://scripts/npcs/NpcRelationshipManager.gd")
const MainUiScript := preload("res://scripts/main/MainUi.gd")
const FishingManagerScript := preload("res://scripts/fishing/FishingManager.gd")
const ForagingManagerScript := preload("res://scripts/foraging/ForagingManager.gd")
const ApiaryManagerScript := preload("res://scripts/apiary/ApiaryManager.gd")

const SEED_ITEMS: Array[String] = ["turnip_seed", "potato_seed", "cabbage_seed", "corn_seed"]
const CROP_ITEMS: Array[String] = ["turnip", "potato", "cabbage", "corn"]
const ANIMAL_PRODUCT_ITEMS: Array[String] = ["egg", "milk"]
const PROCESSED_ITEMS: Array[String] = ["dried_turnip", "hash_brown", "cornmeal", "mayonnaise", "cheese"]
const FISH_ITEMS: Array[String] = ["pond_fish", "river_fish", "rare_fish"]
const FORAGE_ITEMS: Array[String] = ["wild_berry", "mushroom", "wild_herb"]
const APIARY_ITEMS: Array[String] = ["honey"]
const SELLABLE_ITEMS: Array[String] = ["turnip", "potato", "cabbage", "corn", "egg", "milk", "dried_turnip", "hash_brown", "cornmeal", "mayonnaise", "cheese", "pond_fish", "river_fish", "rare_fish", "wild_berry", "mushroom", "wild_herb", "honey"]
const GIFT_ITEMS: Array[String] = ["turnip", "potato", "cabbage", "corn", "egg", "milk"]

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
var crafting_manager
var npc_manager
var fishing_manager
var foraging_manager
var apiary_manager
var selected_seed_item_id := "turnip_seed"
var recent_milestone_message := ""
var ui
var status_label: Label
var hint_label: Label
var order_label: Label
var weather_label: Label
var milestone_label: Label
var farm_size_label: Label
var money_value_label: Label
var seed_value_labels: Dictionary = {}
var crop_value_labels: Dictionary = {}
var seed_slot_buttons: Dictionary = {}
var shop_panel: PanelContainer
var shop_money_label: Label
var shop_message_label: Label
var stats_panel: PanelContainer
var stats_value_label: Label
var help_panel: PanelContainer
var help_text_label: Label
var journal_panel: PanelContainer
var journal_value_label: Label
var briefing_panel: PanelContainer
var briefing_value_label: Label
var animal_panel: PanelContainer
var animal_value_label: Label
var crafting_panel: PanelContainer
var crafting_value_label: Label
var npc_panel: PanelContainer
var npc_value_label: Label
var fishing_panel: PanelContainer
var fishing_value_label: Label
var foraging_panel: PanelContainer
var foraging_value_label: Label
var apiary_panel: PanelContainer
var apiary_value_label: Label
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
	crafting_manager = CraftingManagerScript.new()
	crafting_manager.setup(data_manager.recipes, data_manager.items)
	npc_manager = NpcRelationshipManagerScript.new()
	npc_manager.setup(data_manager.npcs)
	fishing_manager = FishingManagerScript.new()
	fishing_manager.start_day(time_manager.day)
	foraging_manager = ForagingManagerScript.new()
	foraging_manager.start_day(time_manager.day)
	apiary_manager = ApiaryManagerScript.new()

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
		KEY_C:
			_toggle_crafting()
		KEY_V:
			_toggle_npcs()
		KEY_P:
			_toggle_fishing()
		KEY_K:
			_cast_fishing()
		KEY_G:
			_toggle_foraging()
		KEY_Y:
			_search_foraging()
		KEY_U:
			_toggle_apiary()
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
	draw_rect(Rect2(Vector2(72, 330), Vector2(160, 120)), Color("#4d8b45"))
	for index in range(6):
		var bush_position := Vector2(92 + index * 22, 352 + (index % 2) * 32)
		draw_circle(bush_position, 18.0, Color("#35783b"))
		draw_circle(bush_position + Vector2(7, -3), 4.0, Color("#c84c63"))
	for index in apiary_manager.beehives:
		var hive_position := Vector2(842 + index * 28, 450)
		draw_rect(Rect2(hive_position, Vector2(22, 30)), Color("#d6a33c"))
		draw_rect(Rect2(hive_position + Vector2(3, 7), Vector2(16, 5)), Color("#7a4e20"))
	draw_circle(Vector2(1080, 430), 86.0, Color("#4e9ccf"))
	draw_circle(Vector2(1080, 430), 86.0, Color("#2f6f94"), false, 3.0)
	draw_rect(Rect2(Vector2(420, 210), Vector2(380, 280)), Color("#9b7043"))
	_draw_animal_area()
	var highlighted_cell = target_info.get("cell") if bool(target_info.get("valid", false)) else null
	farm_manager.draw_farm(self, highlighted_cell)


func _interact_with_farm_at(world_position: Vector2) -> void:
	var before_seeds := _counts_for(SEED_ITEMS)
	var before_crops := _counts_for(CROP_ITEMS)
	var result: String = farm_manager.interact_at(world_position, inventory, selected_seed_item_id, time_manager.current_season())
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
	var apiary_result: Dictionary = apiary_manager.advance_day(inventory, time_manager.current_season())
	npc_manager.start_day(time_manager.day)
	fishing_manager.start_day(time_manager.day)
	foraging_manager.start_day(time_manager.day)
	order_manager.start_day(time_manager.day)
	weather_manager.start_day(time_manager.day)
	var message := "睡了一觉。第 %d 天开始，新的可选订单来了；不做也没关系。" % time_manager.day
	if int(animal_result.get("egg", 0)) > 0 or int(animal_result.get("milk", 0)) > 0:
		var animal_message := String(animal_result.get("message", ""))
		message = "%s\n%s" % [animal_message, message]
		_record_journal(animal_message)
	if int(apiary_result.get("honey", 0)) > 0:
		var apiary_message := String(apiary_result.get("message", ""))
		message = "%s\n%s" % [apiary_message, message]
		_record_journal(apiary_message)
	if not rain_message.is_empty():
		message = "%s\n%s" % [rain_message, message]
	_record_journal("进入第 %d 天。%s" % [time_manager.day, weather_manager.describe()])
	if briefing_panel != null:
		briefing_panel.visible = true
	_update_ui(message)
	refresh_inventory_ui()
	_update_target_hint()


func _sell_all_crops() -> void:
	var before_crops := _counts_for(CROP_ITEMS)
	var before_processed := _counts_for(PROCESSED_ITEMS)
	var before_fish := _counts_for(FISH_ITEMS)
	var before_forage := _counts_for(FORAGE_ITEMS)
	var before_apiary := _counts_for(APIARY_ITEMS)
	var money_before: int = inventory.money
	var result: Dictionary = shop_manager.sell_all_items(inventory, SELLABLE_ITEMS)
	if bool(result.get("success", false)):
		_record_sold_changes(before_crops, inventory.money - money_before)
		_record_processed_sold_changes(before_processed, inventory.money - money_before)
		_record_fish_sold_changes(before_fish)
		_record_forage_sold_changes(before_forage)
		_record_apiary_sold_changes(before_apiary)
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


func _buy_beehive() -> void:
	var result: Dictionary = apiary_manager.buy_beehive(inventory)
	if bool(result.get("success", false)):
		_record_journal(String(result.get("message", "")))
	_update_ui(String(result.get("message", "Buying beehive failed.")))
	refresh_inventory_ui()
	_update_apiary_ui()
	_update_target_hint()


func _craft_recipe(recipe_id: String) -> void:
	var result: Dictionary = crafting_manager.craft(inventory, recipe_id)
	if bool(result.get("success", false)):
		_record_journal(String(result.get("message", "")))
	_update_ui(String(result.get("message", "加工失败。")))
	refresh_inventory_ui()
	_update_crafting_ui()
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
		animal_manager,
		npc_manager,
		fishing_manager,
		foraging_manager,
		apiary_manager
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
		animal_manager,
		npc_manager,
		fishing_manager,
		foraging_manager,
		apiary_manager
	)
	var saved_seed := String(applied.get("selected_seed_item_id", selected_seed_item_id))
	if SEED_ITEMS.has(saved_seed):
		selected_seed_item_id = saved_seed
	npc_manager.start_day(time_manager.day)
	fishing_manager.start_day(time_manager.day)
	foraging_manager.start_day(time_manager.day)
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
	shop_panel.visible = not shop_panel.visible
	_update_shop_ui()
	if shop_panel.visible:
		_update_ui("商店打开了。点击按钮购买种子，按 B 关闭。")
	else:
		_update_ui("商店关闭。")


func _toggle_stats() -> void:
	stats_panel.visible = not stats_panel.visible
	_update_stats_ui()
	if stats_panel.visible:
		_update_ui("图鉴打开了。这里只有记录和回忆，不会强迫你完成任何东西。")
	else:
		_update_ui("图鉴关闭。")


func _toggle_help() -> void:
	help_panel.visible = not help_panel.visible
	if help_panel.visible:
		_update_ui("帮助打开了。这里是自由经营提示，不是任务要求。")
	else:
		_update_ui("帮助关闭。")


func _toggle_journal() -> void:
	journal_panel.visible = not journal_panel.visible
	_update_journal_ui()
	if journal_panel.visible:
		_update_ui("日记打开了。这里记录农场故事，不是待办清单。")
	else:
		_update_ui("日记关闭。")


func _toggle_briefing() -> void:
	briefing_panel.visible = not briefing_panel.visible
	_update_briefing_ui()
	if briefing_panel.visible:
		_update_ui("晨间简报打开了。它只帮你回忆今天的情况。")
	else:
		_update_ui("晨间简报关闭。")


func _toggle_animals() -> void:
	animal_panel.visible = not animal_panel.visible
	_update_animal_ui()
	if animal_panel.visible:
		_update_ui("动物棚打开了。可以买鸡、买牛、买饲料，也可以喂全部动物。")
	else:
		_update_ui("动物棚关闭。")


func _toggle_crafting() -> void:
	crafting_panel.visible = not crafting_panel.visible
	_update_crafting_ui()
	if crafting_panel.visible:
		_update_ui("加工坊打开了。点击配方会立即消耗原料并产出加工品。")
	else:
		_update_ui("加工坊关闭。")


func _toggle_npcs() -> void:
	npc_panel.visible = not npc_panel.visible
	_update_npc_ui()
	if npc_panel.visible:
		_update_ui("村民关系打开了。可以给每位村民每天送一次礼物。")
	else:
		_update_ui("村民关系关闭。")


func _give_npc_gift(npc_id: String, item_id: String) -> void:
	var result: Dictionary = npc_manager.give_gift(npc_id, item_id, inventory, time_manager.day)
	var message := String(result.get("message", "送礼失败。"))
	if bool(result.get("success", false)):
		_record_journal(message)
	_update_ui(message)
	refresh_inventory_ui()
	_update_npc_ui()
	_update_target_hint()


func _toggle_fishing() -> void:
	fishing_panel.visible = not fishing_panel.visible
	_update_fishing_ui()
	if fishing_panel.visible:
		_update_ui("Fishing spot opened. Press K or the cast button to fish.")
	else:
		_update_ui("Fishing spot closed.")


func _cast_fishing() -> void:
	var result: Dictionary = fishing_manager.cast(inventory, time_manager.day, weather_manager.current_weather_id)
	var message := String(result.get("message", "Fishing failed."))
	if bool(result.get("success", false)):
		_record_journal(message)
	_update_ui(message)
	refresh_inventory_ui()
	_update_fishing_ui()
	_update_target_hint()


func _toggle_foraging() -> void:
	foraging_panel.visible = not foraging_panel.visible
	_update_foraging_ui()
	if foraging_panel.visible:
		_update_ui("Foraging spot opened. Press Y or the search button to forage.")
	else:
		_update_ui("Foraging spot closed.")


func _search_foraging() -> void:
	var result: Dictionary = foraging_manager.search(inventory, time_manager.day, time_manager.season_name())
	var message := String(result.get("message", "Foraging failed."))
	if bool(result.get("success", false)):
		_record_journal(message)
	_update_ui(message)
	refresh_inventory_ui()
	_update_foraging_ui()
	_update_target_hint()


func _toggle_apiary() -> void:
	apiary_panel.visible = not apiary_panel.visible
	_update_apiary_ui()
	if apiary_panel.visible:
		_update_ui("Apiary opened. Buy beehives to produce honey outside winter.")
	else:
		_update_ui("Apiary closed.")


func _build_ui() -> void:
	ui = MainUiScript.new()
	ui.build(
		self,
		data_manager,
		SEED_ITEMS,
		CROP_ITEMS,
		GIFT_ITEMS,
		AnimalManagerScript.FEED_ITEM_ID,
		crafting_manager,
		npc_manager,
		fishing_manager,
		foraging_manager,
		apiary_manager
	)
	_sync_ui_references()
	return

	var canvas := CanvasLayer.new()
	add_child(canvas)

	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.custom_minimum_size = Vector2(560, 178)
	canvas.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	margin.add_child(box)

	hint_label = Label.new()
	hint_label.text = "WASD移动 | E/空格/鼠标农田 | 1-4选种 | B商店 | H帮助 | N睡觉 | M出售 | F5/F9存读"
	box.add_child(hint_label)

	order_label = Label.new()
	order_label.name = "OrderValue"
	order_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(order_label)

	weather_label = Label.new()
	weather_label.name = "WeatherValue"
	weather_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(weather_label)

	milestone_label = Label.new()
	milestone_label.name = "MilestoneValue"
	milestone_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(milestone_label)

	farm_size_label = Label.new()
	farm_size_label.name = "FarmSizeValue"
	farm_size_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(farm_size_label)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(status_label)

	_build_shop_panel(canvas)
	_build_stats_panel(canvas)
	_build_animal_panel(canvas)
	_build_crafting_panel(canvas)
	_build_npc_panel(canvas)
	_build_help_panel(canvas)
	_build_briefing_panel(canvas)
	_build_journal_panel(canvas)
	_build_inventory_bar(canvas)


func _sync_ui_references() -> void:
	status_label = ui.status_label
	hint_label = ui.hint_label
	order_label = ui.order_label
	weather_label = ui.weather_label
	milestone_label = ui.milestone_label
	farm_size_label = ui.farm_size_label
	money_value_label = ui.money_value_label
	seed_value_labels = ui.seed_value_labels
	crop_value_labels = ui.crop_value_labels
	seed_slot_buttons = ui.seed_slot_buttons
	shop_panel = ui.shop_panel
	shop_money_label = ui.shop_money_label
	shop_message_label = ui.shop_message_label
	stats_panel = ui.stats_panel
	stats_value_label = ui.stats_value_label
	help_panel = ui.help_panel
	help_text_label = ui.help_text_label
	journal_panel = ui.journal_panel
	journal_value_label = ui.journal_value_label
	briefing_panel = ui.briefing_panel
	briefing_value_label = ui.briefing_value_label
	animal_panel = ui.animal_panel
	animal_value_label = ui.animal_value_label
	crafting_panel = ui.crafting_panel
	crafting_value_label = ui.crafting_value_label
	npc_panel = ui.npc_panel
	npc_value_label = ui.npc_value_label
	fishing_panel = ui.fishing_panel
	fishing_value_label = ui.fishing_value_label
	foraging_panel = ui.foraging_panel
	foraging_value_label = ui.foraging_value_label
	apiary_panel = ui.apiary_panel
	apiary_value_label = ui.apiary_value_label


func _build_shop_panel(canvas: CanvasLayer) -> void:
	shop_panel = PanelContainer.new()
	shop_panel.name = "ShopPanel"
	shop_panel.position = Vector2(570, 18)
	shop_panel.custom_minimum_size = Vector2(360, 210)
	shop_panel.visible = false
	canvas.add_child(shop_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	shop_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var title := Label.new()
	title.text = "种子商店"
	box.add_child(title)

	shop_money_label = Label.new()
	box.add_child(shop_money_label)

	for seed_item_id in SEED_ITEMS:
		var button := Button.new()
		button.name = "%sBuyButton" % seed_item_id.to_pascal_case()
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_buy_seed.bind(seed_item_id))
		box.add_child(button)

	var feed_button := Button.new()
	feed_button.name = "AnimalFeedBuyButton"
	feed_button.focus_mode = Control.FOCUS_NONE
	feed_button.pressed.connect(_buy_animal_feed)
	box.add_child(feed_button)

	shop_message_label = Label.new()
	shop_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(shop_message_label)


func _build_stats_panel(canvas: CanvasLayer) -> void:
	stats_panel = PanelContainer.new()
	stats_panel.name = "StatsPanel"
	stats_panel.position = Vector2(940, 18)
	stats_panel.custom_minimum_size = Vector2(318, 246)
	stats_panel.visible = false
	canvas.add_child(stats_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	stats_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var title := Label.new()
	title.text = "农场图鉴"
	box.add_child(title)

	stats_value_label = Label.new()
	stats_value_label.name = "StatsValue"
	stats_value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(stats_value_label)


func _build_animal_panel(canvas: CanvasLayer) -> void:
	animal_panel = PanelContainer.new()
	animal_panel.name = "AnimalPanel"
	animal_panel.position = Vector2(570, 238)
	animal_panel.custom_minimum_size = Vector2(360, 238)
	animal_panel.visible = false
	canvas.add_child(animal_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	animal_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var title := Label.new()
	title.text = "动物棚"
	box.add_child(title)

	animal_value_label = Label.new()
	animal_value_label.name = "AnimalValue"
	animal_value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(animal_value_label)

	var chicken_button := Button.new()
	chicken_button.name = "BuyChickenButton"
	chicken_button.focus_mode = Control.FOCUS_NONE
	chicken_button.pressed.connect(_buy_chicken)
	box.add_child(chicken_button)

	var cow_button := Button.new()
	cow_button.name = "BuyCowButton"
	cow_button.focus_mode = Control.FOCUS_NONE
	cow_button.pressed.connect(_buy_cow)
	box.add_child(cow_button)

	var feed_button := Button.new()
	feed_button.name = "FeedAnimalsButton"
	feed_button.focus_mode = Control.FOCUS_NONE
	feed_button.text = "喂全部动物"
	feed_button.pressed.connect(_feed_animals)
	box.add_child(feed_button)


func _build_crafting_panel(canvas: CanvasLayer) -> void:
	crafting_panel = PanelContainer.new()
	crafting_panel.name = "CraftingPanel"
	crafting_panel.position = Vector2(570, 486)
	crafting_panel.custom_minimum_size = Vector2(360, 190)
	crafting_panel.visible = false
	canvas.add_child(crafting_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	crafting_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var title := Label.new()
	title.text = "加工坊"
	box.add_child(title)

	crafting_value_label = Label.new()
	crafting_value_label.name = "CraftingValue"
	crafting_value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(crafting_value_label)

	for recipe_id in crafting_manager.recipe_ids():
		var button := Button.new()
		button.name = "%sCraftButton" % String(recipe_id).to_pascal_case()
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_craft_recipe.bind(String(recipe_id)))
		box.add_child(button)


func _build_npc_panel(canvas: CanvasLayer) -> void:
	npc_panel = PanelContainer.new()
	npc_panel.name = "NpcPanel"
	npc_panel.position = Vector2(570, 486)
	npc_panel.custom_minimum_size = Vector2(690, 106)
	npc_panel.visible = false
	canvas.add_child(npc_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	npc_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var title := Label.new()
	title.text = "村民关系"
	box.add_child(title)

	npc_value_label = Label.new()
	npc_value_label.name = "NpcValue"
	npc_value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(npc_value_label)

	for npc_id in npc_manager.npcs.keys():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		box.add_child(row)
		for item_id in GIFT_ITEMS:
			var button := Button.new()
			button.name = "%s%sGiftButton" % [String(npc_id).to_pascal_case(), item_id.to_pascal_case()]
			button.focus_mode = Control.FOCUS_NONE
			button.pressed.connect(_give_npc_gift.bind(String(npc_id), item_id))
			row.add_child(button)


func _build_help_panel(canvas: CanvasLayer) -> void:
	help_panel = PanelContainer.new()
	help_panel.name = "HelpPanel"
	help_panel.position = Vector2(320, 150)
	help_panel.custom_minimum_size = Vector2(640, 330)
	help_panel.visible = true
	canvas.add_child(help_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	help_panel.add_child(margin)

	help_text_label = Label.new()
	help_text_label.name = "HelpText"
	help_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_text_label.text = "\n".join([
		"农村生活 Demo",
		"",
		"这是一个自由经营的小农场：种什么、卖不卖、接不接订单都由你决定。",
		"建议玩法：开垦土地 -> 选种子 -> 种植 -> 浇水或等雨天 -> 收获 -> 出售或交可选订单。",
		"",
		"常用按键：",
		"WASD/方向键移动，E/空格交互，鼠标点击农田操作。",
		"1-4 选择种子，B 打开商店，M 出售农产品，O 交付可选订单。",
		"L 查看动物棚，F 喂全部动物，I 查看图鉴，J 查看日记，R 查看晨报，X 扩建农田。",
		"F5 保存，F9 读档，H 打开/关闭这个帮助。",
		"",
		"订单、图鉴和天气都只是让日子更有味道，不会惩罚你慢慢玩。"
	])
	margin.add_child(help_text_label)


func _build_briefing_panel(canvas: CanvasLayer) -> void:
	briefing_panel = PanelContainer.new()
	briefing_panel.name = "BriefingPanel"
	briefing_panel.position = Vector2(18, 188)
	briefing_panel.custom_minimum_size = Vector2(286, 246)
	briefing_panel.visible = true
	canvas.add_child(briefing_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	briefing_panel.add_child(margin)

	briefing_value_label = Label.new()
	briefing_value_label.name = "BriefingValue"
	briefing_value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(briefing_value_label)


func _build_journal_panel(canvas: CanvasLayer) -> void:
	journal_panel = PanelContainer.new()
	journal_panel.name = "JournalPanel"
	journal_panel.position = Vector2(920, 278)
	journal_panel.custom_minimum_size = Vector2(340, 300)
	journal_panel.visible = false
	canvas.add_child(journal_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	journal_panel.add_child(margin)

	journal_value_label = Label.new()
	journal_value_label.name = "JournalValue"
	journal_value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(journal_value_label)


func _build_inventory_bar(canvas: CanvasLayer) -> void:
	var bar := PanelContainer.new()
	bar.name = "InventoryBar"
	bar.position = Vector2(18, 594)
	bar.custom_minimum_size = Vector2(1244, 108)
	canvas.add_child(bar)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	bar.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	margin.add_child(row)

	money_value_label = _add_inventory_slot(row, "MoneySlot", "金币", "MoneyValue", Color("#e3b340"))

	for seed_item_id in SEED_ITEMS:
		var value_name := _seed_value_name(seed_item_id)
		var label := _add_inventory_slot(row, "%sSlot" % seed_item_id.to_pascal_case(), _item_name(seed_item_id), value_name, Color("#6da34d"), true, seed_item_id)
		seed_value_labels[seed_item_id] = label

	for crop_item_id in CROP_ITEMS:
		var value_name := _crop_value_name(crop_item_id)
		var label := _add_inventory_slot(row, "%sSlot" % crop_item_id.to_pascal_case(), _item_name(crop_item_id), value_name, _crop_swatch(crop_item_id))
		crop_value_labels[crop_item_id] = label


func _add_inventory_slot(
	parent: HBoxContainer,
	slot_name: String,
	label_text: String,
	value_name: String,
	swatch_color: Color,
	clickable: bool = false,
	seed_item_id: String = ""
) -> Label:
	var slot: Control
	if clickable:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_select_seed.bind(seed_item_id))
		slot = button
		seed_slot_buttons[seed_item_id] = button
	else:
		slot = PanelContainer.new()

	slot.name = slot_name
	slot.custom_minimum_size = Vector2(118, 72)
	parent.add_child(slot)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	slot.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	margin.add_child(row)

	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(18, 18)
	swatch.color = swatch_color
	row.add_child(swatch)

	var text_box := VBoxContainer.new()
	row.add_child(text_box)

	var name_label := Label.new()
	name_label.text = label_text
	text_box.add_child(name_label)

	var value_label := Label.new()
	value_label.name = value_name
	value_label.text = "0"
	text_box.add_child(value_label)

	return value_label


func _update_ui(message: String) -> void:
	status_label.text = "第 %d 天 %02d:%02d  金币: %d  当前种子: %s\n%s" % [
		time_manager.day,
		time_manager.hour,
		time_manager.minute,
		inventory.money,
		_item_name(selected_seed_item_id),
		message,
	]
	status_label.text = "%s  %s" % [_season_status_text(), status_label.text]
	if shop_message_label != null:
		shop_message_label.text = message
	_update_order_ui()
	_update_weather_ui()
	_update_milestone_ui()
	_update_journal_ui()
	_update_briefing_ui()
	_update_farm_size_ui()
	_update_animal_ui()
	_update_crafting_ui()
	_update_stats_ui()
	_update_npc_ui()
	_update_fishing_ui()
	_update_foraging_ui()
	_update_apiary_ui()


func refresh_inventory_ui() -> void:
	if money_value_label == null:
		return

	money_value_label.text = str(inventory.money)
	for seed_item_id in SEED_ITEMS:
		if seed_value_labels.has(seed_item_id):
			seed_value_labels[seed_item_id].text = str(inventory.count(seed_item_id))
		if seed_slot_buttons.has(seed_item_id):
			var button: Button = seed_slot_buttons[seed_item_id]
			button.modulate = Color("#fff1a6") if seed_item_id == selected_seed_item_id else Color.WHITE

	for crop_item_id in CROP_ITEMS:
		if crop_value_labels.has(crop_item_id):
			crop_value_labels[crop_item_id].text = str(inventory.count(crop_item_id))

	_update_shop_ui()
	_update_order_ui()
	_update_weather_ui()
	_update_milestone_ui()
	_update_journal_ui()
	_update_briefing_ui()
	_update_farm_size_ui()
	_update_animal_ui()
	_update_crafting_ui()
	_update_stats_ui()
	_update_npc_ui()
	_update_fishing_ui()
	_update_foraging_ui()
	_update_apiary_ui()


func _update_shop_ui() -> void:
	if shop_panel == null or shop_money_label == null:
		return

	shop_money_label.text = "金币：%d" % inventory.money
	for seed_item_id in SEED_ITEMS:
		var button := shop_panel.find_child("%sBuyButton" % seed_item_id.to_pascal_case(), true, false)
		if button is Button:
			var price := int(data_manager.items[seed_item_id].get("price", 0))
			button.text = "购买 %s - %d 金" % [_item_name(seed_item_id), price]
	var feed_button := shop_panel.find_child("AnimalFeedBuyButton", true, false)
	if feed_button is Button:
		var feed_price := int(data_manager.items[AnimalManagerScript.FEED_ITEM_ID].get("price", 0)) * 5
		feed_button.text = "购买 动物饲料 x5 - %d 金" % feed_price


func _update_target_hint() -> void:
	if farm_manager == null or player == null or hint_label == null:
		return

	target_info = farm_manager.get_target_info(player.facing_position(), selected_seed_item_id, time_manager.current_season())
	hint_label.text = "WASD移动 | E/空格/鼠标农田 | 1-4选种 | B商店 | H帮助 | N睡觉 | M出售 | F5/F9存读"
	if bool(target_info.get("valid", false)):
		hint_label.text += "\n当前农田: %s" % String(target_info.get("prompt", ""))
	else:
		hint_label.text += "\n当前农田: 面向或点击农田格查看操作。"


func _update_order_ui() -> void:
	if order_label == null or order_manager == null:
		return
	order_label.text = order_manager.describe_order(inventory)


func _update_weather_ui() -> void:
	if weather_label == null or weather_manager == null:
		return
	weather_label.text = weather_manager.describe()


func _update_milestone_ui() -> void:
	if milestone_label == null or milestone_manager == null:
		return
	if recent_milestone_message.is_empty():
		milestone_label.text = milestone_manager.describe()
	else:
		milestone_label.text = recent_milestone_message


func _update_journal_ui() -> void:
	if journal_value_label == null or journal_manager == null:
		return
	journal_value_label.text = journal_manager.describe_recent()


func _update_briefing_ui() -> void:
	if briefing_value_label == null or briefing_manager == null:
		return
	var milestone_text := recent_milestone_message
	if milestone_text.is_empty() and milestone_manager != null:
		milestone_text = milestone_manager.describe()
	briefing_value_label.text = briefing_manager.compose(
		time_manager.day,
		weather_manager.describe(),
		order_manager.describe_order(inventory),
		milestone_text,
		animal_manager.briefing_text(),
		_season_status_text(),
		"加工提示：按 C 打开加工坊，把收获和畜产品立即做成更值钱的加工品。",
		npc_manager.briefing_text(),
		apiary_manager.briefing_text()
	)


func _update_animal_ui() -> void:
	if animal_value_label == null or animal_manager == null:
		return
	animal_value_label.text = animal_manager.describe(inventory)
	var chicken_button := animal_panel.find_child("BuyChickenButton", true, false)
	if chicken_button is Button:
		chicken_button.text = "买鸡 - %d 金" % AnimalManagerScript.CHICKEN_PRICE
	var cow_button := animal_panel.find_child("BuyCowButton", true, false)
	if cow_button is Button:
		cow_button.text = "买牛 - %d 金" % AnimalManagerScript.COW_PRICE


func _update_crafting_ui() -> void:
	if crafting_value_label == null or crafting_manager == null:
		return
	crafting_value_label.text = crafting_manager.describe(inventory)
	for recipe_id in crafting_manager.recipe_ids():
		var button := crafting_panel.find_child("%sCraftButton" % String(recipe_id).to_pascal_case(), true, false)
		if button is Button:
			var recipe: Dictionary = data_manager.recipes.get(recipe_id, {})
			var output_item_id := String(recipe.get("output", ""))
			button.text = "加工 %s" % _item_name(output_item_id)
			button.disabled = not crafting_manager.can_craft(inventory, String(recipe_id))


func _update_npc_ui() -> void:
	if npc_value_label == null or npc_manager == null:
		return
	npc_value_label.text = npc_manager.describe()
	if npc_panel == null:
		return
	for npc_id in npc_manager.npcs.keys():
		for item_id in GIFT_ITEMS:
			var button := npc_panel.find_child("%s%sGiftButton" % [String(npc_id).to_pascal_case(), item_id.to_pascal_case()], true, false)
			if button is Button:
				button.text = npc_manager.gift_button_text(String(npc_id), item_id, _item_name(item_id), inventory)
				button.disabled = npc_manager.was_gifted_today(String(npc_id), time_manager.day) or inventory.count(item_id) <= 0


func _update_fishing_ui() -> void:
	if fishing_value_label == null or fishing_manager == null:
		return
	fishing_value_label.text = fishing_manager.describe(inventory)
	if fishing_panel == null:
		return
	var cast_button := fishing_panel.find_child("CastFishingButton", true, false)
	if cast_button is Button:
		cast_button.text = "Cast (%d/%d)" % [fishing_manager.casts_today, FishingManagerScript.MAX_CASTS_PER_DAY]
		cast_button.disabled = fishing_manager.casts_today >= FishingManagerScript.MAX_CASTS_PER_DAY


func _update_foraging_ui() -> void:
	if foraging_value_label == null or foraging_manager == null:
		return
	foraging_value_label.text = foraging_manager.describe(inventory)
	if foraging_panel == null:
		return
	var search_button := foraging_panel.find_child("SearchForagingButton", true, false)
	if search_button is Button:
		search_button.text = "Search (%d/%d)" % [foraging_manager.searches_today, ForagingManagerScript.MAX_SEARCHES_PER_DAY]
		search_button.disabled = foraging_manager.searches_today >= ForagingManagerScript.MAX_SEARCHES_PER_DAY


func _update_apiary_ui() -> void:
	if apiary_value_label == null or apiary_manager == null:
		return
	apiary_value_label.text = apiary_manager.describe(inventory)
	if apiary_panel == null:
		return
	var buy_button := apiary_panel.find_child("BuyBeehiveButton", true, false)
	if buy_button is Button:
		buy_button.text = "Buy Beehive - %d gold" % ApiaryManagerScript.BEEHIVE_PRICE
		buy_button.disabled = apiary_manager.beehives >= ApiaryManagerScript.MAX_BEEHIVES


func _update_farm_size_ui() -> void:
	if farm_size_label == null or farm_manager == null:
		return
	if farm_manager.width >= FarmManagerScript.MAX_WIDTH and farm_manager.height >= FarmManagerScript.MAX_HEIGHT:
		farm_size_label.text = "农田：%d x %d | 已达最大范围" % [farm_manager.width, farm_manager.height]
	else:
		farm_size_label.text = "农田：%d x %d | 按 X 扩建 %d 金" % [
			farm_manager.width,
			farm_manager.height,
			FarmManagerScript.EXPAND_COST,
		]


func _update_stats_ui() -> void:
	if stats_value_label == null or stats_manager == null:
		return
	stats_value_label.text = stats_manager.describe(data_manager.items)


func _item_name(item_id: String) -> String:
	var item: Dictionary = data_manager.items.get(item_id, {})
	return String(item.get("name", item_id))


func _season_status_text() -> String:
	return "%s %d/%d" % [
		time_manager.season_name(),
		time_manager.season_day(),
		TimeManagerScript.DAYS_PER_SEASON,
	]


func _seed_value_name(seed_item_id: String) -> String:
	if seed_item_id == "turnip_seed":
		return "SeedValue"
	return "%sValue" % seed_item_id.to_pascal_case()


func _crop_value_name(crop_item_id: String) -> String:
	if crop_item_id == "turnip":
		return "TurnipValue"
	return "%sValue" % crop_item_id.to_pascal_case()


func _crop_swatch(crop_item_id: String) -> Color:
	match crop_item_id:
		"turnip":
			return Color("#d6513b")
		"potato":
			return Color("#c89a5b")
		"cabbage":
			return Color("#77b95b")
		"corn":
			return Color("#f1cf4a")
	return Color("#d6513b")


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


func _record_processed_sold_changes(before_processed: Dictionary, earned: int) -> void:
	for item_id in PROCESSED_ITEMS:
		var sold_count: int = int(before_processed.get(item_id, 0)) - inventory.count(item_id)
		if sold_count > 0:
			var sell_price := int(data_manager.items[item_id].get("sell_price", 0))
			stats_manager.record_sold(item_id, sold_count, sell_price * sold_count)


func _record_fish_sold_changes(before_fish: Dictionary) -> void:
	for item_id in FISH_ITEMS:
		var sold_count: int = int(before_fish.get(item_id, 0)) - inventory.count(item_id)
		if sold_count > 0:
			var sell_price := int(data_manager.items[item_id].get("sell_price", 0))
			stats_manager.record_sold(item_id, sold_count, sell_price * sold_count)


func _record_forage_sold_changes(before_forage: Dictionary) -> void:
	for item_id in FORAGE_ITEMS:
		var sold_count: int = int(before_forage.get(item_id, 0)) - inventory.count(item_id)
		if sold_count > 0:
			var sell_price := int(data_manager.items[item_id].get("sell_price", 0))
			stats_manager.record_sold(item_id, sold_count, sell_price * sold_count)


func _record_apiary_sold_changes(before_apiary: Dictionary) -> void:
	for item_id in APIARY_ITEMS:
		var sold_count: int = int(before_apiary.get(item_id, 0)) - inventory.count(item_id)
		if sold_count > 0:
			var sell_price := int(data_manager.items[item_id].get("sell_price", 0))
			stats_manager.record_sold(item_id, sold_count, sell_price * sold_count)


func _should_auto_load() -> bool:
	for arg in OS.get_cmdline_args():
		if String(arg).contains("res://tests/"):
			return false
	return true
