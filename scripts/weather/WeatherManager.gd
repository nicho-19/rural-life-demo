extends RefCounted
class_name WeatherManager

var current_day := 1
var current_weather_id := "sunny"

func start_day(day: int) -> void:
	current_day = max(1, day)
	current_weather_id = _weather_for_day(current_day)


func is_rainy() -> bool:
	return current_weather_id == "rainy"


func describe() -> String:
	match current_weather_id:
		"sunny":
			return "天气：晴天。适合慢慢打理农田。"
		"cloudy":
			return "天气：多云。今天很安静。"
		"rainy":
			return "天气：雨天。雨水会自动浇灌已种下的作物，没有惩罚。"
	return "天气：未知。"


func sky_color() -> Color:
	match current_weather_id:
		"sunny":
			return Color("#8fc9ef")
		"cloudy":
			return Color("#b8c7cf")
		"rainy":
			return Color("#7f9fb5")
	return Color("#8fc9ef")


func to_save_data() -> Dictionary:
	return {
		"current_day": current_day,
		"current_weather_id": current_weather_id,
	}


func load_save_data(data: Dictionary) -> void:
	current_day = max(1, int(data.get("current_day", 1)))
	current_weather_id = String(data.get("current_weather_id", _weather_for_day(current_day)))
	if not ["sunny", "cloudy", "rainy"].has(current_weather_id):
		current_weather_id = _weather_for_day(current_day)


func _weather_for_day(day: int) -> String:
	if day == 1:
		return "sunny"
	if day % 3 == 0:
		return "rainy"
	if day % 2 == 0:
		return "cloudy"
	return "sunny"
