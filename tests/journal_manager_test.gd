extends SceneTree

const JournalManagerScript := preload("res://scripts/journal/JournalManager.gd")

func _init() -> void:
	var journal = JournalManagerScript.new()
	journal.add_entry(1, "种下了萝卜种子。")
	journal.add_entry(1, "收获了萝卜。")
	journal.add_entry(2, "雨水帮忙浇灌了作物。")

	var summary: String = journal.describe_recent()
	if not summary.contains("农场日记"):
		_fail("Journal summary should have a readable title.")
		return
	if not summary.contains("第 1 天") or not summary.contains("第 2 天"):
		_fail("Journal summary should include day labels.")
		return
	if not summary.contains("雨水"):
		_fail("Journal summary should include recent events.")
		return

	var saved: Dictionary = journal.to_save_data()
	var restored = JournalManagerScript.new()
	restored.load_save_data(saved)
	if not restored.describe_recent().contains("收获了萝卜"):
		_fail("Journal should round-trip through save data.")
		return

	print("PASS journal_manager_test")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
