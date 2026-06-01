extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)

	await process_frame

	var help_panel := main.find_child("HelpPanel", true, false)
	var help_text := main.find_child("HelpText", true, false)
	if not help_panel is PanelContainer:
		_fail(main, "Main scene should create a HelpPanel.")
		return
	if not help_text is Label:
		_fail(main, "Main scene should create a HelpText label.")
		return
	if help_panel.visible:
		_fail(main, "HelpPanel should start hidden so it does not cover the farm.")
		return
	if not String(help_text.text).contains("自由经营"):
		_fail(main, "HelpText should explain the game as free-form play.")
		return
	if not String(help_text.text).contains("H"):
		_fail(main, "HelpText should mention the H toggle.")
		return

	main._toggle_help()
	if not help_panel.visible:
		_fail(main, "Toggling help should show the panel.")
		return
	main._toggle_help()
	if help_panel.visible:
		_fail(main, "Toggling help again should hide the panel.")
		return

	_pass(main)


func _pass(main: Node) -> void:
	main.queue_free()
	await process_frame
	print("PASS help_panel_test")
	quit(0)


func _fail(main: Node, message: String) -> void:
	main.queue_free()
	await process_frame
	push_error(message)
	quit(1)
