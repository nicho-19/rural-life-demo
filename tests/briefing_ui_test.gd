extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)

	await process_frame

	var briefing_panel := main.find_child("BriefingPanel", true, false)
	var briefing_label := main.find_child("BriefingValue", true, false)
	if not briefing_panel is PanelContainer:
		_fail(main, "Main scene should create a BriefingPanel.")
		return
	if not briefing_label is Label:
		_fail(main, "Main scene should create a BriefingValue label.")
		return
	if not briefing_panel.visible:
		_fail(main, "BriefingPanel should start visible.")
		return
	if not String(briefing_label.text).contains("今日简报"):
		_fail(main, "Briefing panel should show a daily briefing.")
		return

	main._toggle_briefing()
	await process_frame
	if briefing_panel.visible:
		_fail(main, "Toggling briefing should hide the panel.")
		return

	main._next_day()
	await process_frame
	if not briefing_panel.visible:
		_fail(main, "Starting a new day should show the briefing again.")
		return
	if not String(briefing_label.text).contains("第 2 天"):
		_fail(main, "Briefing should refresh when the day changes.")
		return

	_pass(main)


func _pass(main: Node) -> void:
	main.queue_free()
	await process_frame
	print("PASS briefing_ui_test")
	quit(0)


func _fail(main: Node, message: String) -> void:
	main.queue_free()
	await process_frame
	push_error(message)
	quit(1)
