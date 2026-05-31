extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)

	await process_frame

	var weather_label := main.find_child("WeatherValue", true, false)
	if not weather_label is Label:
		_fail(main, "Main scene should create a WeatherValue label.")
		return
	if not String(weather_label.text).contains("天气"):
		_fail(main, "Weather label should describe today's weather.")
		return

	main.weather_manager.start_day(3)
	main._update_weather_ui()
	if not String(weather_label.text).contains("雨"):
		_fail(main, "Weather label should show rainy weather.")
		return

	_pass(main)


func _pass(main: Node) -> void:
	main.queue_free()
	await process_frame
	print("PASS weather_ui_test")
	quit(0)


func _fail(main: Node, message: String) -> void:
	main.queue_free()
	await process_frame
	push_error(message)
	quit(1)
