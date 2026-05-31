extends Node2D

const FarmManagerScript := preload("res://scripts/farm/FarmManager.gd")
const InventoryScript := preload("res://scripts/inventory/Inventory.gd")
const DataManagerScript := preload("res://scripts/core/DataManager.gd")
const TimeManagerScript := preload("res://scripts/core/TimeManager.gd")

@onready var player: CharacterBody2D = $Player

var data_manager
var time_manager
var farm_manager
var inventory
var status_label: Label
var hint_label: Label
var money_value_label: Label
var seed_value_label: Label
var turnip_value_label: Label
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

	_build_ui()
	_update_ui("早上好。靠近农田按 E 或空格开始干活。")
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
			_interact_with_farm()
		KEY_N:
			_next_day()
		KEY_M:
			_sell_turnips()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("#89c779"))
	draw_rect(Rect2(Vector2(0, 500), Vector2(1280, 220)), Color("#d9b77f"))
	draw_rect(Rect2(Vector2(0, 0), Vector2(1280, 90)), Color("#8fc9ef"))
	draw_rect(Rect2(Vector2(420, 210), Vector2(380, 280)), Color("#9b7043"))
	var highlighted_cell = target_info.get("cell") if bool(target_info.get("valid", false)) else null
	farm_manager.draw_farm(self, highlighted_cell)


func _interact_with_farm() -> void:
	var target_position: Vector2 = player.facing_position()
	var result: String = farm_manager.interact_at(target_position, inventory)
	_update_ui(result)
	refresh_inventory_ui()
	_update_target_hint()


func _next_day() -> void:
	time_manager.next_day()
	farm_manager.advance_day()
	_update_ui("睡了一觉。第 %d 天开始，作物结算完成。" % time_manager.day)
	refresh_inventory_ui()
	_update_target_hint()


func _sell_turnips() -> void:
	var amount: int = inventory.count("turnip")
	if amount <= 0:
		_update_ui("背包里没有萝卜可以卖。")
		return

	var price := int(data_manager.items["turnip"].get("sell_price", 0))
	inventory.remove_item("turnip", amount)
	inventory.money += amount * price
	_update_ui("卖出 %d 个萝卜，收入 %d 金。" % [amount, amount * price])
	refresh_inventory_ui()
	_update_target_hint()


func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.custom_minimum_size = Vector2(430, 122)
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
	hint_label.text = "WASD/方向键移动 | E/空格交互 | N 下一天 | M 卖萝卜"
	box.add_child(hint_label)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(status_label)

	_build_inventory_bar(canvas)


func _build_inventory_bar(canvas: CanvasLayer) -> void:
	var bar := PanelContainer.new()
	bar.name = "InventoryBar"
	bar.position = Vector2(18, 610)
	bar.custom_minimum_size = Vector2(500, 82)
	canvas.add_child(bar)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	bar.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)

	money_value_label = _add_inventory_slot(row, "MoneySlot", "Gold", "MoneyValue", Color("#e3b340"))
	seed_value_label = _add_inventory_slot(row, "SeedSlot", "Seeds", "SeedValue", Color("#6da34d"))
	turnip_value_label = _add_inventory_slot(row, "TurnipSlot", "Turnips", "TurnipValue", Color("#d6513b"))


func _add_inventory_slot(parent: HBoxContainer, slot_name: String, label_text: String, value_name: String, swatch_color: Color) -> Label:
	var slot := PanelContainer.new()
	slot.name = slot_name
	slot.custom_minimum_size = Vector2(148, 58)
	parent.add_child(slot)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	slot.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)

	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(24, 24)
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
	status_label.text = "第 %d 天  %02d:%02d  金钱: %d  种子: %d  萝卜: %d\n%s" % [
		time_manager.day,
		time_manager.hour,
		time_manager.minute,
		inventory.money,
		inventory.count("turnip_seed"),
		inventory.count("turnip"),
		message,
	]


func refresh_inventory_ui() -> void:
	if money_value_label == null or seed_value_label == null or turnip_value_label == null:
		return

	money_value_label.text = str(inventory.money)
	seed_value_label.text = str(inventory.count("turnip_seed"))
	turnip_value_label.text = str(inventory.count("turnip"))


func _update_target_hint() -> void:
	if farm_manager == null or player == null or hint_label == null:
		return

	target_info = farm_manager.get_target_info(player.facing_position())
	var prompt := String(target_info.get("prompt", ""))
	hint_label.text = "WASD/方向键移动 | E/空格交互 | N 下一天 | M 卖萝卜"
	if bool(target_info.get("valid", false)):
		hint_label.text += "\n当前农田: %s" % prompt
	else:
		hint_label.text += "\n当前农田: 面向农田格子可查看操作提示"
