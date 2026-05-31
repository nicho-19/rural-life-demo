extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)

	await process_frame

	var money_label := _find_label(main, "MoneyValue")
	var seed_label := _find_label(main, "SeedValue")
	var turnip_label := _find_label(main, "TurnipValue")

	if money_label == null:
		_fail(main, "Main scene should create a MoneyValue label in the inventory bar.")
		return
	if seed_label == null:
		_fail(main, "Main scene should create a SeedValue label in the inventory bar.")
		return
	if turnip_label == null:
		_fail(main, "Main scene should create a TurnipValue label in the inventory bar.")
		return

	if money_label.text != "100":
		_fail(main, "MoneyValue should show the starter money amount.")
		return
	if seed_label.text != "8":
		_fail(main, "SeedValue should show the starter seed count.")
		return
	if turnip_label.text != "0":
		_fail(main, "TurnipValue should show zero harvested turnips at game start.")
		return

	main.inventory.add_item("turnip", 2)
	main.inventory.remove_item("turnip_seed", 3)
	main.inventory.money = 220
	main.refresh_inventory_ui()

	if money_label.text != "220" or seed_label.text != "5" or turnip_label.text != "2":
		_fail(main, "refresh_inventory_ui should update money, seed, and turnip labels.")
		return

	_pass(main)


func _find_label(root_node: Node, node_name: String) -> Label:
	var found := root_node.find_child(node_name, true, false)
	if found is Label:
		return found
	return null


func _pass(main: Node) -> void:
	main.queue_free()
	await process_frame
	print("PASS inventory_ui_test")
	quit(0)


func _fail(main: Node, message: String) -> void:
	main.queue_free()
	await process_frame
	push_error(message)
	quit(1)
