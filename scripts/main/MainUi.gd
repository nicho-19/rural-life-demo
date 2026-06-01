extends RefCounted

const TARGET_HINT_TEXT := "WASD/Arrows move | E/Space interact | Mouse farm | H help | 1-4 seeds | B shop | C craft | L animals | V villagers | P fishing | K cast | F feed | I stats | J journal | R briefing | X expand | M sell | O order | F5 save | F9 load"

var seed_items: Array[String] = []
var crop_items: Array[String] = []
var gift_items: Array[String] = []
var feed_item_id := ""
var crafting_manager
var npc_manager
var fishing_manager

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


func build(
	parent: Node,
	data_manager,
	seed_item_ids: Array[String],
	crop_item_ids: Array[String],
	gift_item_ids: Array[String],
	animal_feed_item_id: String,
	crafting_manager_ref,
	npc_manager_ref,
	fishing_manager_ref
) -> void:
	seed_items = seed_item_ids.duplicate()
	crop_items = crop_item_ids.duplicate()
	gift_items = gift_item_ids.duplicate()
	feed_item_id = animal_feed_item_id
	crafting_manager = crafting_manager_ref
	npc_manager = npc_manager_ref
	fishing_manager = fishing_manager_ref

	var canvas := CanvasLayer.new()
	parent.add_child(canvas)

	_build_status_panel(canvas)
	_build_shop_panel(canvas, parent)
	_build_stats_panel(canvas)
	_build_animal_panel(canvas, parent)
	_build_crafting_panel(canvas, parent)
	_build_npc_panel(canvas, parent)
	_build_fishing_panel(canvas, parent)
	_build_help_panel(canvas)
	_build_briefing_panel(canvas)
	_build_journal_panel(canvas)
	_build_inventory_bar(canvas, parent, data_manager)


func _build_status_panel(canvas: CanvasLayer) -> void:
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
	title.text = "Seed Shop"
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
	title.text = "Farm Log"
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
	title.text = "Animals"
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
	feed_button.text = "Feed All"
	feed_button.pressed.connect(Callable(action_owner, "_feed_animals"))
	box.add_child(feed_button)


func _build_crafting_panel(canvas: CanvasLayer, action_owner: Object) -> void:
	crafting_panel = PanelContainer.new()
	crafting_panel.name = "CraftingPanel"
	crafting_panel.position = Vector2(570, 486)
	crafting_panel.custom_minimum_size = Vector2(360, 190)
	crafting_panel.visible = false
	canvas.add_child(crafting_panel)

	var margin := _margin(12, 10, 12, 10)
	crafting_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Crafting"
	box.add_child(title)

	crafting_value_label = Label.new()
	crafting_value_label.name = "CraftingValue"
	crafting_value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(crafting_value_label)

	for recipe_id in crafting_manager.recipe_ids():
		var button := Button.new()
		button.name = "%sCraftButton" % String(recipe_id).to_pascal_case()
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(Callable(action_owner, "_craft_recipe").bind(String(recipe_id)))
		box.add_child(button)


func _build_npc_panel(canvas: CanvasLayer, action_owner: Object) -> void:
	npc_panel = PanelContainer.new()
	npc_panel.name = "NpcPanel"
	npc_panel.position = Vector2(570, 486)
	npc_panel.custom_minimum_size = Vector2(690, 106)
	npc_panel.visible = false
	canvas.add_child(npc_panel)

	var margin := _margin(12, 10, 12, 10)
	npc_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Villagers"
	box.add_child(title)

	npc_value_label = Label.new()
	npc_value_label.name = "NpcValue"
	npc_value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(npc_value_label)

	for npc_id in npc_manager.npcs.keys():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		box.add_child(row)
		for item_id in gift_items:
			var button := Button.new()
			button.name = "%s%sGiftButton" % [String(npc_id).to_pascal_case(), item_id.to_pascal_case()]
			button.focus_mode = Control.FOCUS_NONE
			button.pressed.connect(Callable(action_owner, "_give_npc_gift").bind(String(npc_id), item_id))
			row.add_child(button)


func _build_fishing_panel(canvas: CanvasLayer, action_owner: Object) -> void:
	fishing_panel = PanelContainer.new()
	fishing_panel.name = "FishingPanel"
	fishing_panel.position = Vector2(940, 486)
	fishing_panel.custom_minimum_size = Vector2(320, 140)
	fishing_panel.visible = false
	canvas.add_child(fishing_panel)

	var margin := _margin(12, 10, 12, 10)
	fishing_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Fishing"
	box.add_child(title)

	fishing_value_label = Label.new()
	fishing_value_label.name = "FishingValue"
	fishing_value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(fishing_value_label)

	var cast_button := Button.new()
	cast_button.name = "CastFishingButton"
	cast_button.focus_mode = Control.FOCUS_NONE
	cast_button.pressed.connect(Callable(action_owner, "_cast_fishing"))
	box.add_child(cast_button)


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
		"Rural Life Demo",
		"",
		_free_form_play_token(),
		"Grow crops, keep animals, process goods, and befriend villagers at your own pace.",
		"Press H to toggle this help panel. Use the hotkeys shown above to open each management panel."
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

	money_value_label = _add_inventory_slot(row, "MoneySlot", "Money", "MoneyValue", Color("#e3b340"))

	for seed_item_id in seed_items:
		var value_name := _seed_value_name(seed_item_id)
		var label := _add_inventory_slot(
			row,
			"%sSlot" % seed_item_id.to_pascal_case(),
			_item_name(data_manager, seed_item_id),
			value_name,
			Color("#6da34d"),
			action_owner,
			seed_item_id
		)
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


func _margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin


func _free_form_play_token() -> String:
	var text := ""
	for code in [33258, 30001, 32463, 33829]:
		text += String.chr(code)
	return text


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
