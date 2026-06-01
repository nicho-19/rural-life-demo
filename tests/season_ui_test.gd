extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)

	await process_frame

	var status_label := _find_status_label(main)
	if status_label == null:
		_fail(main, "Main scene should create a status label.")
		return
	if not String(status_label.text).contains("Spring 1/7"):
		_fail(main, "Status label should include the current season day.")
		return

	main.time_manager.day = 8
	main._update_ui("season test")
	await process_frame
	if not String(status_label.text).contains("Summer 1/7"):
		_fail(main, "Status label should update the displayed season.")
		return

	_pass(main)


func _find_status_label(main: Node) -> Label:
	for node in main.find_children("*", "Label", true, false):
		if String(node.text).contains("season test") or String(node.text).contains("Spring 1/7"):
			return node
	return null


func _pass(main: Node) -> void:
	main.queue_free()
	await process_frame
	print("PASS season_ui_test")
	quit(0)


func _fail(main: Node, message: String) -> void:
	main.queue_free()
	await process_frame
	push_error(message)
	quit(1)
