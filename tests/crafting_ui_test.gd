extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)

	await process_frame

	var crafting_panel := main.find_child("CraftingPanel", true, false)
	var crafting_label := main.find_child("CraftingValue", true, false)
	var dried_turnip_button := main.find_child("DriedTurnipCraftButton", true, false)
	if not crafting_panel is PanelContainer:
		_fail(main, "Main scene should create a CraftingPanel.")
		return
	if not crafting_label is Label:
		_fail(main, "Main scene should create a CraftingValue label.")
		return
	if not dried_turnip_button is Button:
		_fail(main, "Crafting panel should create a dried turnip craft button.")
		return
	if crafting_panel.visible:
		_fail(main, "CraftingPanel should start hidden.")
		return

	main._toggle_crafting()
	await process_frame
	if not crafting_panel.visible:
		_fail(main, "Toggling crafting should show the crafting panel.")
		return
	if not String(crafting_label.text).contains("萝卜干"):
		_fail(main, "Crafting panel should list the dried turnip recipe.")
		return

	main.inventory.add_item("turnip", 1)
	main._craft_recipe("dried_turnip")
	await process_frame
	if main.inventory.count("turnip") != 0 or main.inventory.count("dried_turnip") != 1:
		_fail(main, "Crafting from the UI should immediately consume ingredients and add output.")
		return
	if not main.journal_manager.describe_recent().contains("萝卜干"):
		_fail(main, "Successful crafting should write a journal entry.")
		return
	if not String(main.briefing_value_label.text).contains("加工"):
		_fail(main, "Daily briefing should show a crafting tip.")
		return

	main.inventory.money = 0
	main._sell_all_crops()
	await process_frame
	if main.inventory.money <= 0 or main.inventory.count("dried_turnip") != 0:
		_fail(main, "M selling should include processed goods.")
		return

	_pass(main)


func _pass(main: Node) -> void:
	main.queue_free()
	await process_frame
	print("PASS crafting_ui_test")
	quit(0)


func _fail(main: Node, message: String) -> void:
	main.queue_free()
	await process_frame
	push_error(message)
	quit(1)
