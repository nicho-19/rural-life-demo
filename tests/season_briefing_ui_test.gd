extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)

	await process_frame

	var briefing_label := main.find_child("BriefingValue", true, false)
	if not briefing_label is Label:
		_fail(main, "Main scene should create a BriefingValue label.")
		return
	if not String(briefing_label.text).contains("Spring 1/7"):
		_fail(main, "Briefing panel should include the current season day.")
		return

	main.time_manager.day = 15
	main._update_briefing_ui()
	await process_frame
	if not String(briefing_label.text).contains("Autumn 1/7"):
		_fail(main, "Briefing panel should update the displayed season day.")
		return

	_pass(main)


func _pass(main: Node) -> void:
	main.queue_free()
	await process_frame
	print("PASS season_briefing_ui_test")
	quit(0)


func _fail(main: Node, message: String) -> void:
	main.queue_free()
	await process_frame
	push_error(message)
	quit(1)
