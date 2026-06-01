extends SceneTree

const FarmManagerScript := preload("res://scripts/farm/FarmManager.gd")

func _init() -> void:
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)

	await process_frame

	var expansion_label := main.find_child("FarmSizeValue", true, false)
	if not expansion_label is Label:
		_fail(main, "Main scene should show current farm size.")
		return
	if not String(expansion_label.text).contains("8 x 5"):
		_fail(main, "Farm size label should show the default farm size.")
		return

	main.inventory.money = FarmManagerScript.EXPAND_COST
	main._buy_farm_expansion()
	await process_frame

	if main.farm_manager.width != 9:
		_fail(main, "Buying farm expansion should increase farm width.")
		return
	if main.inventory.money != 0:
		_fail(main, "Buying farm expansion should spend money.")
		return
	if not String(expansion_label.text).contains("9 x 5"):
		_fail(main, "Farm size label should refresh after expansion.")
		return

	_pass(main)


func _pass(main: Node) -> void:
	main.queue_free()
	await process_frame
	print("PASS farm_expansion_ui_test")
	quit(0)


func _fail(main: Node, message: String) -> void:
	main.queue_free()
	await process_frame
	push_error(message)
	quit(1)
