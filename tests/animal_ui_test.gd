extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)

	await process_frame

	var animal_panel := main.find_child("AnimalPanel", true, false)
	var animal_label := main.find_child("AnimalValue", true, false)
	if not animal_panel is PanelContainer:
		_fail(main, "Main scene should create an AnimalPanel.")
		return
	if not animal_label is Label:
		_fail(main, "Main scene should create an AnimalValue label.")
		return
	if animal_panel.visible:
		_fail(main, "AnimalPanel should start hidden.")
		return

	main._toggle_animals()
	await process_frame
	if not animal_panel.visible:
		_fail(main, "Toggling animals should show the animal panel.")
		return

	main.inventory.money = 1200
	main._buy_chicken()
	main._buy_cow()
	main._buy_animal_feed()
	main._feed_animals()
	await process_frame

	if main.animal_manager.chickens != 1 or main.animal_manager.cows != 1:
		_fail(main, "Animal UI actions should buy one chicken and one cow.")
		return
	if main.animal_manager.fed_chickens != 1 or main.animal_manager.fed_cows != 1:
		_fail(main, "Feeding from the UI should feed bought animals when feed is available.")
		return
	if not String(animal_label.text).contains("鸡 1/4") or not String(animal_label.text).contains("牛 1/2"):
		_fail(main, "Animal panel should show bought chicken and cow counts.")
		return

	main._next_day()
	await process_frame
	if main.inventory.count("egg") != 1 or main.inventory.count("milk") != 1:
		_fail(main, "Fed animals should produce egg and milk after sleeping.")
		return
	if not String(animal_label.text).contains("鸡蛋 1") or not String(animal_label.text).contains("牛奶 1"):
		_fail(main, "Animal panel should show produced eggs and milk.")
		return

	_pass(main)


func _pass(main: Node) -> void:
	main.queue_free()
	await process_frame
	print("PASS animal_ui_test")
	quit(0)


func _fail(main: Node, message: String) -> void:
	main.queue_free()
	await process_frame
	push_error(message)
	quit(1)
