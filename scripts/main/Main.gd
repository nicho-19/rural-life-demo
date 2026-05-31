extends Node2D

const FarmManagerScript := preload("res://scripts/farm/FarmManager.gd")
const InventoryScript := preload("res://scripts/inventory/Inventory.gd")
const DataManagerScript := preload("res://scripts/core/DataManager.gd")
const TimeManagerScript := preload("res://scripts/core/TimeManager.gd")
const ShopManagerScript := preload("res://scripts/shop/ShopManager.gd")
const OrderManagerScript := preload("res://scripts/orders/OrderManager.gd")
const SaveManagerScript := preload("res://scripts/save/SaveManager.gd")
const StatsManagerScript := preload("res://scripts/stats/StatsManager.gd")

const SEED_ITEMS: Array[String] = ["turnip_seed", "potato_seed", "cabbage_seed", "corn_seed"]
const CROP_ITEMS: Array[String] = ["turnip", "potato", "cabbage", "corn"]

@onready var player: CharacterBody2D = $Player

var data_manager
var time_manager
var farm_manager
var inventory
var shop_manager
var order_manager
var save_manager
var stats_manager
var selected_seed_item_id := "turnip_seed"
var status_label: Label
var hint_label: Label
var order_label: Label
var money_value_label: Label
var seed_value_labels: Dictionary = {}
var crop_value_labels: Dictionary = {}
var seed_slot_buttons: Dictionary = {}
var shop_panel: PanelContainer
var shop_money_label: Label
var shop_message_label: Label
var stats_panel: PanelContainer
var stats_value_label: Label
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
	draw_rect(Rect2(Vector2(0, 0), Vector2(1280, 90)), Color("#8fc9ef"))
	draw_rect(Rect2(Vector2(420, 210), Vector2(380, 280)), Color("#9b7043"))
	var highlighted_cell = target_info.get("cell") if bool(target_info.get("valid", false)) else null
	farm_manager.draw_farm(self, highlighted_cell)


func _interact_with_farm_at(world_position: Vector2) -> void:
	var before_seeds := _counts_for(SEED_ITEMS)
	var before_crops := _counts_for(CROP_ITEMS)
	var result: String = farm_manager.interact_at(world_position, inventory, selected_seed_item_id)
	_record_farm_changes(before_seeds, before_crops)
	_update_ui(result)
	refresh_inventory_ui()
	_update_target_hint()


func _next_day() -> void:
	time_manager.next_day()
	farm_manager.advance_day()
	order_manager.start_day(time_manager.day)
	_update_ui("睡了一觉。第 %d 天开始，新的可选订单来了；不做也没关系。" % time_manager.day)
	refresh_inventory_ui()
	_update_target_hint()


func _sell_all_crops() -> void:
	var before_crops := _counts_for(CROP_ITEMS)
	var money_before: int = inventory.money
	var result: Dictionary = shop_manager.sell_all_crops(inventory, CROP_ITEMS)
	if bool(result.get("success", false)):
		_record_sold_changes(before_crops, inventory.money - money_before)
	_update_ui(String(result.get("message", "没有可以出售的作物。")))
	refresh_inventory_ui()
	_update_target_hint()


func _deliver_order() -> void:
	var money_before: int = inventory.money
	var result: Dictionary = order_manager.deliver_order(inventory)
	if bool(result.get("success", false)):
		stats_manager.record_order_completed(inventory.money - money_before)
	_update_ui(String(result.get("message", "订单交付失败。")))
	refresh_inventory_ui()
	_update_target_hint()


func _save_game() -> void:
	var result: Dictionary = save_manager.save_game(
		SaveManagerScript.SAVE_PATH,
		inventory,
		farm_manager,
		time_manager,
		order_manager,
		selected_seed_item_id,
		stats_manager
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
		stats_manager
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


func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.custom_minimum_size = Vector2(560, 158)
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
	hint_label.text = "WASD/方向键移动 | E/空格交互 | 鼠标点农田 | 1-4选种 | B商店 | I图鉴 | M出售 | O订单 | F5保存 | F9读档"
	box.add_child(hint_label)

	order_label = Label.new()
	order_label.name = "OrderValue"
	order_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(order_label)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(status_label)

	_build_shop_panel(canvas)
	_build_stats_panel(canvas)
	_build_inventory_bar(canvas)


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
	if shop_message_label != null:
		shop_message_label.text = message
	_update_order_ui()
	_update_stats_ui()


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
	_update_stats_ui()


func _update_shop_ui() -> void:
	if shop_panel == null or shop_money_label == null:
		return

	shop_money_label.text = "金币：%d" % inventory.money
	for seed_item_id in SEED_ITEMS:
		var button := shop_panel.find_child("%sBuyButton" % seed_item_id.to_pascal_case(), true, false)
		if button is Button:
			var price := int(data_manager.items[seed_item_id].get("price", 0))
			button.text = "购买 %s - %d 金" % [_item_name(seed_item_id), price]


func _update_target_hint() -> void:
	if farm_manager == null or player == null or hint_label == null:
		return

	target_info = farm_manager.get_target_info(player.facing_position(), selected_seed_item_id)
	hint_label.text = "WASD/方向键移动 | E/空格交互 | 鼠标点农田 | 1-4选种 | B商店 | I图鉴 | M出售 | O订单 | F5保存 | F9读档"
	if bool(target_info.get("valid", false)):
		hint_label.text += "\n当前农田: %s" % String(target_info.get("prompt", ""))
	else:
		hint_label.text += "\n当前农田: 面向或点击农田格查看操作。"


func _update_order_ui() -> void:
	if order_label == null or order_manager == null:
		return
	order_label.text = order_manager.describe_order(inventory)


func _update_stats_ui() -> void:
	if stats_value_label == null or stats_manager == null:
		return
	stats_value_label.text = stats_manager.describe(data_manager.items)


func _item_name(item_id: String) -> String:
	var item: Dictionary = data_manager.items.get(item_id, {})
	return String(item.get("name", item_id))


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
