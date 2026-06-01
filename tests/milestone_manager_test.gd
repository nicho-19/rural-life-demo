extends SceneTree

const InventoryScript := preload("res://scripts/inventory/Inventory.gd")
const StatsManagerScript := preload("res://scripts/stats/StatsManager.gd")
const MilestoneManagerScript := preload("res://scripts/milestones/MilestoneManager.gd")

func _init() -> void:
	var inventory = InventoryScript.new()
	inventory.setup_starter_items()

	var stats = StatsManagerScript.new()
	var milestones = MilestoneManagerScript.new()

	var no_messages: Array[String] = milestones.check(stats, inventory)
	if not no_messages.is_empty():
		_fail("Milestones should not fire before the player has done anything.")
		return

	stats.record_planted("turnip")
	var planted_messages: Array[String] = milestones.check(stats, inventory)
	if planted_messages.size() != 1 or not planted_messages[0].contains("第一粒种子"):
		_fail("Milestones should celebrate the first planted crop.")
		return
	if not milestones.check(stats, inventory).is_empty():
		_fail("Milestones should only fire once.")
		return

	stats.record_harvested("turnip")
	stats.record_sold("turnip", 1, 60)
	stats.record_order_completed(150)
	inventory.money = 500
	var later_messages: Array[String] = milestones.check(stats, inventory)
	if later_messages.size() != 4:
		_fail("Milestones should detect harvest, sale, order, and 500 gold.")
		return

	var saved: Dictionary = milestones.to_save_data()
	var restored = MilestoneManagerScript.new()
	restored.load_save_data(saved)
	if not restored.check(stats, inventory).is_empty():
		_fail("Loaded milestones should not fire again.")
		return

	print("PASS milestone_manager_test")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
