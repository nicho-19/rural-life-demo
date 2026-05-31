extends Node
class_name TimeManager

var day := 1
var hour := 6
var minute := 0
var _minute_accumulator := 0.0

func tick(delta: float) -> void:
	_minute_accumulator += delta * 12.0
	while _minute_accumulator >= 1.0:
		_minute_accumulator -= 1.0
		_add_minute()


func next_day() -> void:
	day += 1
	hour = 6
	minute = 0
	_minute_accumulator = 0.0


func _add_minute() -> void:
	minute += 1
	if minute >= 60:
		minute = 0
		hour += 1
	if hour >= 24:
		next_day()


func to_save_data() -> Dictionary:
	return {
		"day": day,
		"hour": hour,
		"minute": minute,
	}


func load_save_data(data: Dictionary) -> void:
	day = max(1, int(data.get("day", 1)))
	hour = clampi(int(data.get("hour", 6)), 0, 23)
	minute = clampi(int(data.get("minute", 0)), 0, 59)
	_minute_accumulator = 0.0
