extends RefCounted

const TARGET_HINT_TEXT := "WASD/方向键移动 | E/空格交互 | 鼠标点农田 | H帮助 | 1-4选种 | B商店 | L动物棚 | F喂养 | I图鉴 | J日记 | R晨报 | X扩建 | M出售 | O订单 | F5保存 | F9读档"

var seed_items: Array[String] = []
var crop_items: Array[String] = []
var feed_item_id := ""

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


func build(parent: Node, data_manager, seed_item_ids: Array[String], crop_item_ids: Array[String], animal_feed_item_id: String) -> void:
	seed_items = seed_item_ids.duplicate()
	crop_items = crop_item_ids.duplicate()
	feed_item_id = animal_feed_item_id

	var canvas := CanvasLayer.new()
	parent.add_child(canvas)

	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.custom_minimum_size = Vector2(560, 178)
	canvas.add_child(panel)

	var margin := _margin(12, 10, 12, 10)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	margin.add_child(box)

	hint_label = Label.new()
	hint_label.text = TARGET_HINT_TEXT
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

	_build_shop_panel(canvas, parent)
	_build_stats_panel(canvas)
	_build_animal_panel(canvas, parent)
	_build_help_panel(canvas)
	_build_briefing_panel(canvas)
	_build_journal_panel(canvas)
	_build_inventory_bar(canvas, parent, data_manager)


func _build_shop_panel(canvas: CanvasLayer, action_owner: Object) -> void:
	shop_panel = PanelContainer.new()
	shop_panel.name = "ShopPanel"
	shop_panel.position = Vector2(570, 18)
	shop_panel.custom_minimum_size = Vector2(360, 210)
	shop_panel.visible = false
	canvas.add_child(shop_panel)

	var margin := _margin(12, 10, 12, 10)
	shop_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var title := Label.new()
	title.text = "种子商店"
	box.add_child(title)

	shop_money_label = Label.new()
	box.add_child(shop_money_label)

	for seed_item_id in seed_items:
		var button := Button.new()
		button.name = "%sBuyButton" % seed_item_id.to_pascal_case()
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(Callable(action_owner, "_buy_seed").bind(seed_item_id))
		box.add_child(button)

	var feed_button := Button.new()
	feed_button.name = "AnimalFeedBuyButton"
	feed_button.focus_mode = Control.FOCUS_NONE
	feed_button.pressed.connect(Callable(action_owner, "_buy_animal_feed"))
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

	var margin := _margin(12, 10, 12, 10)
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


func _build_animal_panel(canvas: CanvasLayer, action_owner: Object) -> void:
	animal_panel = PanelContainer.new()
	animal_panel.name = "AnimalPanel"
	animal_panel.position = Vector2(570, 238)
	animal_panel.custom_minimum_size = Vector2(360, 238)
	animal_panel.visible = false
	canvas.add_child(animal_panel)

	var margin := _margin(12, 10, 12, 10)
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
	chicken_button.pressed.connect(Callable(action_owner, "_buy_chicken"))
	box.add_child(chicken_button)

	var cow_button := Button.new()
	cow_button.name = "BuyCowButton"
	cow_button.focus_mode = Control.FOCUS_NONE
	cow_button.pressed.connect(Callable(action_owner, "_buy_cow"))
	box.add_child(cow_button)

	var feed_button := Button.new()
	feed_button.name = "FeedAnimalsButton"
	feed_button.focus_mode = Control.FOCUS_NONE
	feed_button.text = "喂全体动物"
	feed_button.pressed.connect(Callable(action_owner, "_feed_animals"))
	box.add_child(feed_button)


func _build_help_panel(canvas: CanvasLayer) -> void:
	help_panel = PanelContainer.new()
	help_panel.name = "HelpPanel"
	help_panel.position = Vector2(320, 150)
	help_panel.custom_minimum_size = Vector2(640, 330)
	help_panel.visible = true
	canvas.add_child(help_panel)

	var margin := _margin(18, 14, 18, 14)
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
		"L 查看动物棚，F 喂全体动物，I 查看图鉴，J 查看日记，R 查看晨报，X 扩建农田。",
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

	var margin := _margin(12, 10, 12, 10)
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

	var margin := _margin(12, 10, 12, 10)
	journal_panel.add_child(margin)

	journal_value_label = Label.new()
	journal_value_label.name = "JournalValue"
	journal_value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(journal_value_label)


func _build_inventory_bar(canvas: CanvasLayer, action_owner: Object, data_manager) -> void:
	var bar := PanelContainer.new()
	bar.name = "InventoryBar"
	bar.position = Vector2(18, 594)
	bar.custom_minimum_size = Vector2(1244, 108)
	canvas.add_child(bar)

	var margin := _margin(10, 8, 10, 8)
	bar.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	margin.add_child(row)

	money_value_label = _add_inventory_slot(row, "MoneySlot", "金币", "MoneyValue", Color("#e3b340"))

	for seed_item_id in seed_items:
		var value_name := _seed_value_name(seed_item_id)
		var label := _add_inventory_slot(row, "%sSlot" % seed_item_id.to_pascal_case(), _item_name(data_manager, seed_item_id), value_name, Color("#6da34d"), action_owner, seed_item_id)
		seed_value_labels[seed_item_id] = label

	for crop_item_id in crop_items:
		var value_name := _crop_value_name(crop_item_id)
		var label := _add_inventory_slot(row, "%sSlot" % crop_item_id.to_pascal_case(), _item_name(data_manager, crop_item_id), value_name, _crop_swatch(crop_item_id))
		crop_value_labels[crop_item_id] = label


func _add_inventory_slot(
	parent: HBoxContainer,
	slot_name: String,
	label_text: String,
	value_name: String,
	swatch_color: Color,
	action_owner: Object = null,
	seed_item_id: String = ""
) -> Label:
	var slot: Control
	if action_owner != null:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(Callable(action_owner, "_select_seed").bind(seed_item_id))
		slot = button
		seed_slot_buttons[seed_item_id] = button
	else:
		slot = PanelContainer.new()

	slot.name = slot_name
	slot.custom_minimum_size = Vector2(118, 72)
	parent.add_child(slot)

	var margin := _margin(8, 6, 8, 6)
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


func update_ui(
	message: String,
	time_manager,
	inventory,
	selected_seed_item_id: String,
	data_manager,
	order_manager,
	weather_manager,
	milestone_manager,
	recent_milestone_message: String,
	journal_manager,
	briefing_manager,
	animal_manager,
	farm_manager,
	farm_manager_script,
	animal_manager_script,
	stats_manager
) -> void:
	status_label.text = "第 %d 天 %02d:%02d  金币: %d  当前种子: %s\n%s" % [
		time_manager.day,
		time_manager.hour,
		time_manager.minute,
		inventory.money,
		_item_name(data_manager, selected_seed_item_id),
		message,
	]
	if shop_message_label != null:
		shop_message_label.text = message
	update_order(inventory, order_manager)
	update_weather(weather_manager)
	update_milestone(milestone_manager, recent_milestone_message)
	update_journal(journal_manager)
	update_briefing(time_manager, inventory, order_manager, weather_manager, milestone_manager, recent_milestone_message, briefing_manager, animal_manager)
	update_farm_size(farm_manager, farm_manager_script)
	update_animal(inventory, animal_manager, animal_manager_script)
	update_stats(stats_manager, data_manager)


func refresh_inventory(
	inventory,
	selected_seed_item_id: String,
	data_manager,
	order_manager,
	weather_manager,
	milestone_manager,
	recent_milestone_message: String,
	journal_manager,
	briefing_manager,
	animal_manager,
	time_manager,
	farm_manager,
	farm_manager_script,
	animal_manager_script,
	stats_manager
) -> void:
	if money_value_label == null:
		return

	money_value_label.text = str(inventory.money)
	for seed_item_id in seed_items:
		if seed_value_labels.has(seed_item_id):
			seed_value_labels[seed_item_id].text = str(inventory.count(seed_item_id))
		if seed_slot_buttons.has(seed_item_id):
			var button: Button = seed_slot_buttons[seed_item_id]
			button.modulate = Color("#fff1a6") if seed_item_id == selected_seed_item_id else Color.WHITE

	for crop_item_id in crop_items:
		if crop_value_labels.has(crop_item_id):
			crop_value_labels[crop_item_id].text = str(inventory.count(crop_item_id))

	update_shop(inventory, data_manager)
	update_order(inventory, order_manager)
	update_weather(weather_manager)
	update_milestone(milestone_manager, recent_milestone_message)
	update_journal(journal_manager)
	update_briefing(time_manager, inventory, order_manager, weather_manager, milestone_manager, recent_milestone_message, briefing_manager, animal_manager)
	update_farm_size(farm_manager, farm_manager_script)
	update_animal(inventory, animal_manager, animal_manager_script)
	update_stats(stats_manager, data_manager)


func update_shop(inventory, data_manager) -> void:
	if shop_panel == null or shop_money_label == null:
		return

	shop_money_label.text = "金币：%d" % inventory.money
	for seed_item_id in seed_items:
		var button := shop_panel.find_child("%sBuyButton" % seed_item_id.to_pascal_case(), true, false)
		if button is Button:
			var price := int(data_manager.items[seed_item_id].get("price", 0))
			button.text = "购买 %s - %d 金" % [_item_name(data_manager, seed_item_id), price]
	var feed_button := shop_panel.find_child("AnimalFeedBuyButton", true, false)
	if feed_button is Button:
		var feed_price := int(data_manager.items[feed_item_id].get("price", 0)) * 5
		feed_button.text = "购买 动物饲料 x5 - %d 金" % feed_price


func update_target_hint(farm_manager, player, selected_seed_item_id: String) -> Dictionary:
	if farm_manager == null or player == null or hint_label == null:
		return {}

	var target_info: Dictionary = farm_manager.get_target_info(player.facing_position(), selected_seed_item_id)
	hint_label.text = TARGET_HINT_TEXT
	if bool(target_info.get("valid", false)):
		hint_label.text += "\n当前农田: %s" % String(target_info.get("prompt", ""))
	else:
		hint_label.text += "\n当前农田: 面向或点击农田格查看操作。"
	return target_info


func update_order(inventory, order_manager) -> void:
	if order_label == null or order_manager == null:
		return
	order_label.text = order_manager.describe_order(inventory)


func update_weather(weather_manager) -> void:
	if weather_label == null or weather_manager == null:
		return
	weather_label.text = weather_manager.describe()


func update_milestone(milestone_manager, recent_milestone_message: String) -> void:
	if milestone_label == null or milestone_manager == null:
		return
	if recent_milestone_message.is_empty():
		milestone_label.text = milestone_manager.describe()
	else:
		milestone_label.text = recent_milestone_message


func update_journal(journal_manager) -> void:
	if journal_value_label == null or journal_manager == null:
		return
	journal_value_label.text = journal_manager.describe_recent()


func update_briefing(
	time_manager,
	inventory,
	order_manager,
	weather_manager,
	milestone_manager,
	recent_milestone_message: String,
	briefing_manager,
	animal_manager
) -> void:
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
		animal_manager.briefing_text()
	)


func update_animal(inventory, animal_manager, animal_manager_script) -> void:
	if animal_value_label == null or animal_manager == null:
		return
	animal_value_label.text = animal_manager.describe(inventory)
	var chicken_button := animal_panel.find_child("BuyChickenButton", true, false)
	if chicken_button is Button:
		chicken_button.text = "买鸡 - %d 金" % animal_manager_script.CHICKEN_PRICE
	var cow_button := animal_panel.find_child("BuyCowButton", true, false)
	if cow_button is Button:
		cow_button.text = "买牛 - %d 金" % animal_manager_script.COW_PRICE


func update_farm_size(farm_manager, farm_manager_script) -> void:
	if farm_size_label == null or farm_manager == null:
		return
	if farm_manager.width >= farm_manager_script.MAX_WIDTH and farm_manager.height >= farm_manager_script.MAX_HEIGHT:
		farm_size_label.text = "农田：%d x %d | 已达最大范围" % [farm_manager.width, farm_manager.height]
	else:
		farm_size_label.text = "农田：%d x %d | 按 X 扩建 %d 金" % [
			farm_manager.width,
			farm_manager.height,
			farm_manager_script.EXPAND_COST,
		]


func update_stats(stats_manager, data_manager) -> void:
	if stats_value_label == null or stats_manager == null:
		return
	stats_value_label.text = stats_manager.describe(data_manager.items)


func _margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin


func _item_name(data_manager, item_id: String) -> String:
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
