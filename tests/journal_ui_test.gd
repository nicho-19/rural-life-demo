extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)

	await process_frame

	var journal_panel := main.find_child("JournalPanel", true, false)
	var journal_label := main.find_child("JournalValue", true, false)
	if not journal_panel is PanelContainer:
		_fail(main, "Main scene should create a JournalPanel.")
		return
	if not journal_label is Label:
		_fail(main, "Main scene should create a JournalValue label.")
		return
	if journal_panel.visible:
		_fail(main, "JournalPanel should start hidden.")
		return

	main._record_journal("测试记录。")
	main._toggle_journal()
	await process_frame

	if not journal_panel.visible:
		_fail(main, "Toggling journal should show the panel.")
		return
	if not String(journal_label.text).contains("测试记录"):
		_fail(main, "Journal panel should show recorded entries.")
		return

	_pass(main)


func _pass(main: Node) -> void:
	main.queue_free()
	await process_frame
	print("PASS journal_ui_test")
	quit(0)


func _fail(main: Node, message: String) -> void:
	main.queue_free()
	await process_frame
	push_error(message)
	quit(1)
