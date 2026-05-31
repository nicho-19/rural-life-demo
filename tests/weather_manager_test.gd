extends SceneTree

const WeatherManagerScript := preload("res://scripts/weather/WeatherManager.gd")

func _init() -> void:
	var weather = WeatherManagerScript.new()
	weather.start_day(1)
	if weather.current_weather_id != "sunny":
		_fail("Day 1 should start sunny for a gentle opening.")
		return
	if weather.is_rainy():
		_fail("Sunny days should not be rainy.")
		return

	weather.start_day(3)
	if not weather.is_rainy():
		_fail("Day 3 should be rainy in the deterministic weather cycle.")
		return
	if not weather.describe().contains("雨"):
		_fail("Rainy weather should describe the helpful rain.")
		return

	var saved: Dictionary = weather.to_save_data()
	var restored = WeatherManagerScript.new()
	restored.load_save_data(saved)
	if restored.current_weather_id != "rainy" or not restored.is_rainy():
		_fail("Weather should round-trip through save data.")
		return

	print("PASS weather_manager_test")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
