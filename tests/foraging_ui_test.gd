extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)

	await process_frame

	var foraging_panel := main.find_child("ForagingPanel", true, false)
	var foraging_label := main.find_child("ForagingValue", true, false)
	var search_button := main.find_child("SearchForagingButton", true, false)
	if not foraging_panel is PanelContainer:
		_fail(main, "Main scene should create a ForagingPanel.")
		return
	if not foraging_label is Label:
		_fail(main, "Main scene should create a ForagingValue label.")
		return
	if not search_button is Button:
		_fail(main, "Foraging panel should create a search button.")
		return
	if foraging_panel.visible:
		_fail(main, "ForagingPanel should start hidden.")
		return

	main._toggle_foraging()
	await process_frame
	if not foraging_panel.visible:
		_fail(main, "Toggling foraging should show the foraging panel.")
		return

	main._search_foraging()
	await process_frame
	if main.inventory.count("wild_berry") + main.inventory.count("mushroom") + main.inventory.count("wild_herb") != 1:
		_fail(main, "Searching from the UI should add one forage item to inventory.")
		return
	if not String(foraging_label.text).contains("1/2"):
		_fail(main, "Foraging panel should show today's used searches.")
		return
	if not String(main.journal_manager.describe_recent()).contains("forage"):
		_fail(main, "Successful foraging should be recorded in the journal.")
		return

	main.inventory.money = 0
	main._sell_all_crops()
	await process_frame
	if main.inventory.money <= 0:
		_fail(main, "M selling should include forage items.")
		return

	main._next_day()
	await process_frame
	if not String(foraging_label.text).contains("0/2"):
		_fail(main, "Starting a new day should reset foraging searches.")
		return

	_pass(main)


func _pass(main: Node) -> void:
	main.queue_free()
	await process_frame
	print("PASS foraging_ui_test")
	quit(0)


func _fail(main: Node, message: String) -> void:
	main.queue_free()
	await process_frame
	push_error(message)
	quit(1)
