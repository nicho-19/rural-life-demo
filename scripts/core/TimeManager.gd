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
