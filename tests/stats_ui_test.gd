extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)

	await process_frame

	var stats_label := main.find_child("StatsValue", true, false)
	if not stats_label is Label:
		_fail(main, "Main scene should create a StatsValue label.")
		return

	main._select_seed("turnip_seed", false)
	main._interact_with_farm_at(Vector2(528, 296))
	main._interact_with_farm_at(Vector2(528, 296))
	main._interact_with_farm_at(Vector2(528, 296))
	for _day in 3:
		main.farm_manager.advance_day()
		main._interact_with_farm_at(Vector2(528, 296))

	main.refresh_inventory_ui()

	var stats_text := String(stats_label.text)
	if not stats_text.contains("图鉴") or not stats_text.contains("种植 1") or not stats_text.contains("收获 1"):
		_fail(main, "Stats UI should show planted and harvested crop counts.")
		return

	_pass(main)


func _pass(main: Node) -> void:
	main.queue_free()
	await process_frame
	print("PASS stats_ui_test")
	quit(0)


func _fail(main: Node, message: String) -> void:
	main.queue_free()
	await process_frame
	push_error(message)
	quit(1)
