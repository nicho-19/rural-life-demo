extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)

	await process_frame

	var fishing_panel := main.find_child("FishingPanel", true, false)
	var fishing_label := main.find_child("FishingValue", true, false)
	var cast_button := main.find_child("CastFishingButton", true, false)
	if not fishing_panel is PanelContainer:
		_fail(main, "Main scene should create a FishingPanel.")
		return
	if not fishing_label is Label:
		_fail(main, "Main scene should create a FishingValue label.")
		return
	if not cast_button is Button:
		_fail(main, "Fishing panel should create a cast button.")
		return
	if fishing_panel.visible:
		_fail(main, "FishingPanel should start hidden.")
		return

	main._toggle_fishing()
	await process_frame
	if not fishing_panel.visible:
		_fail(main, "Toggling fishing should show the fishing panel.")
		return

	main._cast_fishing()
	await process_frame
	if main.inventory.count("pond_fish") + main.inventory.count("river_fish") + main.inventory.count("rare_fish") != 1:
		_fail(main, "Casting from the UI should add one fish to inventory.")
		return
	if not String(fishing_label.text).contains("1/3"):
		_fail(main, "Fishing panel should show today's used casts.")
		return
	if not String(main.journal_manager.describe_recent()).contains("fish"):
		_fail(main, "Successful fishing should be recorded in the journal.")
		return

	main.inventory.money = 0
	main._sell_all_crops()
	await process_frame
	if main.inventory.money <= 0:
		_fail(main, "M selling should include fish.")
		return

	main._next_day()
	await process_frame
	if not String(fishing_label.text).contains("0/3"):
		_fail(main, "Starting a new day should reset fishing casts.")
		return

	_pass(main)


func _pass(main: Node) -> void:
	main.queue_free()
	await process_frame
	print("PASS fishing_ui_test")
	quit(0)


func _fail(main: Node, message: String) -> void:
	main.queue_free()
	await process_frame
	push_error(message)
	quit(1)
