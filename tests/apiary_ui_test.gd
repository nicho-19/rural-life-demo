extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)

	await process_frame

	var apiary_panel := main.find_child("ApiaryPanel", true, false)
	var apiary_label := main.find_child("ApiaryValue", true, false)
	var buy_button := main.find_child("BuyBeehiveButton", true, false)
	if not apiary_panel is PanelContainer:
		_fail(main, "Main scene should create an ApiaryPanel.")
		return
	if not apiary_label is Label:
		_fail(main, "Main scene should create an ApiaryValue label.")
		return
	if not buy_button is Button:
		_fail(main, "Apiary panel should create a buy beehive button.")
		return
	if apiary_panel.visible:
		_fail(main, "ApiaryPanel should start hidden.")
		return

	main._toggle_apiary()
	await process_frame
	if not apiary_panel.visible:
		_fail(main, "Toggling apiary should show the apiary panel.")
		return

	main.inventory.money = 400
	main._buy_beehive()
	await process_frame
	if main.apiary_manager.beehives != 1 or main.inventory.money != 100:
		_fail(main, "Buying from the UI should add one beehive and deduct gold.")
		return
	if not String(apiary_label.text).contains("1/3"):
		_fail(main, "Apiary panel should show beehive count.")
		return

	main._next_day()
	await process_frame
	if main.inventory.count("honey") != 1:
		_fail(main, "Beehives should add honey after sleeping.")
		return
	if not String(apiary_label.text).contains("honey 1"):
		_fail(main, "Apiary panel should show produced honey.")
		return

	main.inventory.money = 0
	main._sell_all_crops()
	await process_frame
	if main.inventory.money <= 0 or main.inventory.count("honey") != 0:
		_fail(main, "M selling should include honey.")
		return

	_pass(main)


func _pass(main: Node) -> void:
	main.queue_free()
	await process_frame
	print("PASS apiary_ui_test")
	quit(0)


func _fail(main: Node, message: String) -> void:
	main.queue_free()
	await process_frame
	push_error(message)
	quit(1)
