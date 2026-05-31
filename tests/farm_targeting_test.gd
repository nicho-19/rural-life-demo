extends SceneTree

const FarmManagerScript := preload("res://scripts/farm/FarmManager.gd")

func _init() -> void:
	var farm = FarmManagerScript.new()
	farm.setup({
		"turnip": {
			"name": "Turnip",
			"grow_days": 3,
		}
	})

	if not farm.has_method("get_target_info"):
		_fail("FarmManager should expose get_target_info(world_position).")
		return

	var first_tile: Dictionary = farm.get_target_info(Vector2(528, 296))
	if not bool(first_tile.get("valid", false)):
		_fail("A position inside the first farm tile should be targetable.")
		return
	if first_tile.get("cell") != Vector2i(0, 0):
		_fail("The first farm tile should resolve to cell (0, 0).")
		return
	if first_tile.get("rect") != Rect2(Vector2(512, 280), Vector2(30, 30)):
		_fail("The first farm tile should expose its draw rectangle for highlighting.")
		return
	if not String(first_tile.get("prompt", "")).contains("Till"):
		_fail("An empty tile should prompt the player to till soil.")
		return

	var outside: Dictionary = farm.get_target_info(Vector2(320, 160))
	if bool(outside.get("valid", true)):
		_fail("A position outside the farm should not be targetable.")
		return

	farm.free()
	print("PASS farm_targeting_test")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
