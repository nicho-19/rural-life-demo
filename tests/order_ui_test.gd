extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)

	await process_frame

	var order_label := main.find_child("OrderValue", true, false)
	if not order_label is Label:
		_fail(main, "Main scene should show an optional order label.")
		return
	if not String(order_label.text).contains("可选订单"):
		_fail(main, "Order label should make the daily order clearly optional.")
		return

	main.inventory.add_item("turnip", 2)
	main._deliver_order()
	await process_frame

	if main.inventory.money <= 100:
		_fail(main, "Delivering an optional order with enough crops should reward money.")
		return
	if not String(order_label.text).contains("已完成"):
		_fail(main, "Order label should show completion after delivery.")
		return

	_pass(main)


func _pass(main: Node) -> void:
	main.queue_free()
	await process_frame
	print("PASS order_ui_test")
	quit(0)


func _fail(main: Node, message: String) -> void:
	main.queue_free()
	await process_frame
	push_error(message)
	quit(1)
