extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)

	await process_frame

	var npc_panel := main.find_child("NpcPanel", true, false)
	var npc_label := main.find_child("NpcValue", true, false)
	if not npc_panel is PanelContainer:
		_fail(main, "Main scene should create an NpcPanel.")
		return
	if not npc_label is Label:
		_fail(main, "Main scene should create an NpcValue label.")
		return
	if npc_panel.visible:
		_fail(main, "NpcPanel should start hidden.")
		return

	main._toggle_npcs()
	await process_frame
	if not npc_panel.visible:
		_fail(main, "Toggling NPCs should show the villager panel.")
		return
	if not String(npc_label.text).contains("林村长") or not String(npc_label.text).contains("梅子") or not String(npc_label.text).contains("阿川"):
		_fail(main, "NPC panel should list all fixed villagers.")
		return

	main.inventory.add_item("turnip", 1)
	main._give_npc_gift("mayor_lin", "turnip")
	await process_frame
	if main.inventory.count("turnip") != 0:
		_fail(main, "NPC gift button action should consume the selected gift item.")
		return
	if main.npc_manager.friendship_for("mayor_lin") != 12:
		_fail(main, "NPC gift button action should update friendship.")
		return
	if not String(npc_label.text).contains("今日已送"):
		_fail(main, "NPC panel should show today's gifted state.")
		return
	if not String(main.journal_manager.describe_recent()).contains("林村长"):
		_fail(main, "Successful NPC gifts should be recorded in the journal.")
		return

	main._next_day()
	await process_frame
	if not String(npc_label.text).contains("今日未送"):
		_fail(main, "Starting a new day should reset NPC gifted state.")
		return
	if not String(main.briefing_value_label.text).contains("林村长"):
		_fail(main, "Daily briefing should include NPC relationship context.")
		return

	_pass(main)


func _pass(main: Node) -> void:
	main.queue_free()
	await process_frame
	print("PASS npc_relationship_ui_test")
	quit(0)


func _fail(main: Node, message: String) -> void:
	main.queue_free()
	await process_frame
	push_error(message)
	quit(1)
