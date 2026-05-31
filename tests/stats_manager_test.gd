extends SceneTree

const StatsManagerScript := preload("res://scripts/stats/StatsManager.gd")

func _init() -> void:
	var stats = StatsManagerScript.new()

	stats.record_planted("turnip")
	stats.record_planted("turnip")
	stats.record_harvested("turnip", 2)
	stats.record_sold("turnip", 1, 60)
	stats.record_order_completed(150)

	if stats.count_planted("turnip") != 2:
		_fail("Stats should count planted crops.")
		return
	if stats.count_harvested("turnip") != 2:
		_fail("Stats should count harvested crops.")
		return
	if stats.count_sold("turnip") != 1:
		_fail("Stats should count sold crops.")
		return
	if stats.total_earned != 210:
		_fail("Stats should add sold money and order rewards.")
		return
	if stats.orders_completed != 1:
		_fail("Stats should count completed optional orders.")
		return

	var summary: String = stats.describe({
		"turnip": {"name": "萝卜"},
		"potato": {"name": "土豆"},
	})
	if not summary.contains("萝卜") or not summary.contains("种植 2") or not summary.contains("总收入 210"):
		_fail("Stats summary should describe discovered crop progress.")
		return

	var saved: Dictionary = stats.to_save_data()
	var restored = StatsManagerScript.new()
	restored.load_save_data(saved)
	if restored.count_planted("turnip") != 2 or restored.total_earned != 210:
		_fail("Stats should round-trip through save data.")
		return

	print("PASS stats_manager_test")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
