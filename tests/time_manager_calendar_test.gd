extends SceneTree

const TimeManagerScript := preload("res://scripts/core/TimeManager.gd")

func _init() -> void:
	var time_manager = TimeManagerScript.new()

	var cases: Array[Dictionary] = [
		{"day": 1, "season": "spring", "season_day": 1, "name": "Spring"},
		{"day": 7, "season": "spring", "season_day": 7, "name": "Spring"},
		{"day": 8, "season": "summer", "season_day": 1, "name": "Summer"},
		{"day": 14, "season": "summer", "season_day": 7, "name": "Summer"},
		{"day": 15, "season": "autumn", "season_day": 1, "name": "Autumn"},
		{"day": 22, "season": "winter", "season_day": 1, "name": "Winter"},
		{"day": 28, "season": "winter", "season_day": 7, "name": "Winter"},
		{"day": 29, "season": "spring", "season_day": 1, "name": "Spring"},
	]

	for test_case in cases:
		time_manager.day = int(test_case["day"])
		if time_manager.current_season() != String(test_case["season"]):
			_fail(time_manager, "Day %d should be %s." % [time_manager.day, test_case["season"]])
			return
		if time_manager.season_day() != int(test_case["season_day"]):
			_fail(time_manager, "Day %d should be season day %d." % [time_manager.day, test_case["season_day"]])
			return
		if time_manager.season_name() != String(test_case["name"]):
			_fail(time_manager, "Day %d should display %s." % [time_manager.day, test_case["name"]])
			return

	time_manager.free()
	print("PASS time_manager_calendar_test")
	quit(0)


func _fail(time_manager: Node, message: String) -> void:
	time_manager.free()
	push_error(message)
	quit(1)
