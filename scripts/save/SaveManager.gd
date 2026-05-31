extends RefCounted
class_name SaveManager

const SAVE_PATH := "user://rural_life_demo_save.json"
const SAVE_VERSION := 1

func save_game(
	path: String,
	inventory,
	farm_manager,
	time_manager,
	order_manager,
	selected_seed_item_id: String
) -> Dictionary:
	var data := {
		"version": SAVE_VERSION,
		"selected_seed_item_id": selected_seed_item_id,
		"inventory": inventory.to_save_data(),
		"farm": farm_manager.to_save_data(),
		"time": time_manager.to_save_data(),
		"order": order_manager.to_save_data(),
	}

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {
			"success": false,
			"message": "存档失败：无法写入文件。",
		}

	file.store_string(JSON.stringify(data, "\t"))
	return {
		"success": true,
		"message": "游戏已保存。",
	}


func load_game(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {
			"success": false,
			"message": "没有找到存档。",
			"data": {},
		}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {
			"success": false,
			"message": "读档失败：无法打开文件。",
			"data": {},
		}

	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {
			"success": false,
			"message": "读档失败：存档格式不正确。",
			"data": {},
		}

	return {
		"success": true,
		"message": "存档已读取。",
		"data": parsed,
	}


func apply_save_data(
	data: Dictionary,
	inventory,
	farm_manager,
	time_manager,
	order_manager
) -> Dictionary:
	inventory.load_save_data(_dictionary_from(data.get("inventory", {})))
	farm_manager.load_save_data(_dictionary_from(data.get("farm", {})))
	time_manager.load_save_data(_dictionary_from(data.get("time", {})))
	order_manager.load_save_data(_dictionary_from(data.get("order", {})))

	return {
		"success": true,
		"message": "读档完成。",
		"selected_seed_item_id": String(data.get("selected_seed_item_id", "turnip_seed")),
	}


func _dictionary_from(value) -> Dictionary:
	if value is Dictionary:
		return value
	return {}
