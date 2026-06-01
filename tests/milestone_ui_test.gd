extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)

	await process_frame

	var milestone_label := main.find_child("MilestoneValue", true, false)
	if not milestone_label is Label:
		_fail(main, "Main scene should create a MilestoneValue label.")
		return
	if not String(milestone_label.text).contains("小里程碑"):
		_fail(main, "Milestone label should explain soft progress.")
		return

	main._select_seed("turnip_seed", false)
	main._interact_with_farm_at(Vector2(528, 296))
	main._interact_with_farm_at(Vector2(528, 296))
	await process_frame

	if not String(milestone_label.text).contains("第一粒种子"):
		_fail(main, "Planting the first crop should show a soft milestone message.")
		return

	_pass(main)


func _pass(main: Node) -> void:
	main.queue_free()
	await process_frame
	print("PASS milestone_ui_test")
	quit(0)


func _fail(main: Node, message: String) -> void:
	main.queue_free()
	await process_frame
	push_error(message)
	quit(1)
