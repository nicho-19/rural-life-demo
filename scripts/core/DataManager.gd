extends RefCounted
class_name DataManager

var crops: Dictionary = {}
var items: Dictionary = {}
var recipes: Dictionary = {}
var npcs: Dictionary = {}

func load_all() -> void:
	crops = _load_json_dictionary("res://data/crops.json")
	items = _load_json_dictionary("res://data/items.json")
	recipes = _load_json_dictionary("res://data/recipes.json")
	npcs = _load_json_dictionary("res://data/npcs.json")


func _load_json_dictionary(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open data file: %s" % path)
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed

	push_error("Data file is not a JSON object: %s" % path)
	return {}
