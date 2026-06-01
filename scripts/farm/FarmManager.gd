extends Node
class_name FarmManager

const CELL_SIZE := 32
const FARM_ORIGIN := Vector2(512, 280)
const BASE_WIDTH := 8
const BASE_HEIGHT := 5
const MAX_WIDTH := 10
const MAX_HEIGHT := 6
const FARM_WIDTH := BASE_WIDTH
const FARM_HEIGHT := BASE_HEIGHT
const EXPAND_COST := 250

enum TileState {
	EMPTY,
	TILLED,
	PLANTED,
	WATERED,
	READY,
}

var crops: Dictionary = {}
var tiles: Dictionary = {}
var width := BASE_WIDTH
var height := BASE_HEIGHT

func setup(crop_data: Dictionary) -> void:
	crops = crop_data
	width = BASE_WIDTH
	height = BASE_HEIGHT
	_initialize_tiles()


func interact_at(world_position: Vector2, inventory, seed_item_id: String = "turnip_seed", current_season: String = "spring") -> String:
	var cell := world_to_cell(world_position)
	if not tiles.has(cell):
		return "这里不是农田。站在农田旁边，或用鼠标点击农田格。"

	var tile: Dictionary = tiles[cell]
	match int(tile["state"]):
		TileState.EMPTY:
			tile["state"] = TileState.TILLED
			return "开垦了一块土地。"
		TileState.TILLED:
			var crop_id := crop_id_for_seed(seed_item_id)
			if crop_id.is_empty():
				return "先选择一种可以种植的种子。"
			if not can_plant_in_season(crop_id, current_season):
				return "%s cannot be planted in %s season." % [seed_name_for_crop(crop_id), current_season]
			if not inventory.remove_item(seed_item_id, 1):
				return "%s 不够了，去商店买一些吧。" % seed_name_for_crop(crop_id)
			tile["state"] = TileState.PLANTED
			tile["crop_id"] = crop_id
			tile["growth"] = 0
			return "种下了%s。" % seed_name_for_crop(crop_id)
		TileState.PLANTED:
			tile["state"] = TileState.WATERED
			return "浇水完成。睡觉后作物会成长。"
		TileState.WATERED:
			return "今天已经浇过水了。"
		TileState.READY:
			var crop_id := String(tile["crop_id"])
			inventory.add_item(crop_id, 1)
			tile["state"] = TileState.TILLED
			tile["crop_id"] = ""
			tile["growth"] = 0
			return "收获了 1 个%s。" % crop_name(crop_id)

	return "这里暂时不能操作。"


func get_target_info(world_position: Vector2, seed_item_id: String = "turnip_seed", current_season: String = "spring") -> Dictionary:
	var cell := world_to_cell(world_position)
	if not tiles.has(cell):
		return {
			"valid": false,
			"cell": Vector2i(-1, -1),
			"rect": Rect2(),
			"prompt": "面向或点击农田格查看操作。",
		}

	var tile: Dictionary = tiles[cell]
	return {
		"valid": true,
		"cell": cell,
		"rect": cell_to_rect(cell),
		"prompt": _prompt_for_tile(tile, seed_item_id, current_season),
	}


func advance_day() -> void:
	for cell in tiles.keys():
		var tile: Dictionary = tiles[cell]
		if int(tile["state"]) != TileState.WATERED:
			continue

		var crop_id := String(tile["crop_id"])
		tile["growth"] = int(tile["growth"]) + 1
		if int(tile["growth"]) >= int(crops[crop_id].get("grow_days", 1)):
			tile["state"] = TileState.READY
		else:
			tile["state"] = TileState.PLANTED


func water_all_planted() -> int:
	var watered_count := 0
	for cell in tiles.keys():
		var tile: Dictionary = tiles[cell]
		if int(tile["state"]) == TileState.PLANTED:
			tile["state"] = TileState.WATERED
			watered_count += 1
	return watered_count


func buy_expansion(inventory) -> Dictionary:
	if width >= MAX_WIDTH and height >= MAX_HEIGHT:
		return {
			"success": false,
			"message": "农田已经扩建到当前 demo 的最大范围了。",
		}
	if inventory.money < EXPAND_COST:
		return {
			"success": false,
			"message": "扩建农田需要 %d 金，先多卖一些作物吧。" % EXPAND_COST,
		}

	inventory.money -= EXPAND_COST
	if width < MAX_WIDTH:
		width += 1
	else:
		height += 1
	_add_missing_tiles()
	return {
		"success": true,
		"message": "扩建完成。现在农田是 %d x %d，可以种更多作物了。" % [width, height],
	}


func crop_id_for_seed(seed_item_id: String) -> String:
	for crop_id in crops.keys():
		var crop: Dictionary = crops[crop_id]
		if String(crop.get("seed_item", "%s_seed" % crop_id)) == seed_item_id:
			return String(crop_id)
	return ""


func crop_name(crop_id: String) -> String:
	var crop: Dictionary = crops.get(crop_id, {})
	return String(crop.get("name", crop_id))


func seed_name_for_crop(crop_id: String) -> String:
	return "%s种子" % crop_name(crop_id)


func can_plant_in_season(crop_id: String, current_season: String) -> bool:
	var crop: Dictionary = crops.get(crop_id, {})
	var seasons = crop.get("season", [])
	if not seasons is Array or seasons.is_empty():
		return true
	return seasons.has(current_season)


func world_to_cell(world_position: Vector2) -> Vector2i:
	var local := world_position - FARM_ORIGIN
	return Vector2i(floori(local.x / CELL_SIZE), floori(local.y / CELL_SIZE))


func cell_to_rect(cell: Vector2i) -> Rect2:
	return Rect2(FARM_ORIGIN + Vector2(cell) * CELL_SIZE, Vector2(CELL_SIZE - 2, CELL_SIZE - 2))


func draw_farm(canvas: CanvasItem, highlighted_cell = null) -> void:
	for y in height:
		for x in width:
			var cell := Vector2i(x, y)
			var tile: Dictionary = tiles[cell]
			var rect := cell_to_rect(cell)
			var color := _tile_color(int(tile["state"]))
			canvas.draw_rect(rect, color)
			canvas.draw_rect(rect, Color("#5f4328"), false, 1.0)

			if int(tile["state"]) in [TileState.PLANTED, TileState.WATERED, TileState.READY]:
				_draw_crop(canvas, rect, String(tile["crop_id"]), int(tile["growth"]), int(tile["state"]) == TileState.READY)

			if highlighted_cell != null and cell == highlighted_cell:
				canvas.draw_rect(rect.grow(2.0), Color("#ffd85a"), false, 3.0)


func _tile_color(state: int) -> Color:
	match state:
		TileState.EMPTY:
			return Color("#7a5a36")
		TileState.TILLED:
			return Color("#5b3922")
		TileState.PLANTED:
			return Color("#49301e")
		TileState.WATERED:
			return Color("#3d2c27")
		TileState.READY:
			return Color("#4b3520")
	return Color("#7a5a36")


func _prompt_for_tile(tile: Dictionary, seed_item_id: String, current_season: String) -> String:
	match int(tile["state"]):
		TileState.EMPTY:
			return "按 E 或点击：开垦土地"
		TileState.TILLED:
			var crop_id := crop_id_for_seed(seed_item_id)
			if crop_id.is_empty():
				return "先选择一种种子"
			if not can_plant_in_season(crop_id, current_season):
				return "%s is out of season for %s." % [seed_name_for_crop(crop_id), current_season]
			return "按 E 或点击：种植%s" % seed_name_for_crop(crop_id)
		TileState.PLANTED:
			return "按 E 或点击：浇水"
		TileState.WATERED:
			return "今天已经浇过水"
		TileState.READY:
			return "按 E 或点击：收获%s" % crop_name(String(tile["crop_id"]))
	return "无可用操作"


func _draw_crop(canvas: CanvasItem, rect: Rect2, crop_id: String, growth: int, ready: bool) -> void:
	var center := rect.get_center()
	var height := 7.0 + growth * 3.0
	var crop_color := _crop_color(crop_id)
	canvas.draw_line(center + Vector2(0, 8), center + Vector2(0, 8 - height), Color("#2f7d32"), 3.0)
	canvas.draw_circle(center + Vector2(-5, 2 - height * 0.45), 4.0, Color("#66a844"))
	canvas.draw_circle(center + Vector2(5, 2 - height * 0.45), 4.0, Color("#66a844"))
	if ready:
		canvas.draw_circle(center + Vector2(0, 7), 7.0, crop_color)


func _crop_color(crop_id: String) -> Color:
	match crop_id:
		"turnip":
			return Color("#d6513b")
		"potato":
			return Color("#c89a5b")
		"cabbage":
			return Color("#77b95b")
		"corn":
			return Color("#f1cf4a")
	return Color("#d6513b")


func to_save_data() -> Dictionary:
	var saved_tiles: Array[Dictionary] = []
	for cell in tiles.keys():
		var tile: Dictionary = tiles[cell]
		saved_tiles.append({
			"x": cell.x,
			"y": cell.y,
			"state": int(tile.get("state", TileState.EMPTY)),
			"crop_id": String(tile.get("crop_id", "")),
			"growth": int(tile.get("growth", 0)),
		})

	return {
		"width": width,
		"height": height,
		"tiles": saved_tiles,
	}


func load_save_data(data: Dictionary) -> void:
	width = min(MAX_WIDTH, max(BASE_WIDTH, int(data.get("width", BASE_WIDTH))))
	height = min(MAX_HEIGHT, max(BASE_HEIGHT, int(data.get("height", BASE_HEIGHT))))
	_initialize_tiles()

	var saved_tiles = data.get("tiles", [])
	if not saved_tiles is Array:
		return

	for saved_tile in saved_tiles:
		if not saved_tile is Dictionary:
			continue
		var cell := Vector2i(int(saved_tile.get("x", -1)), int(saved_tile.get("y", -1)))
		if not tiles.has(cell):
			continue
		tiles[cell] = {
			"state": int(saved_tile.get("state", TileState.EMPTY)),
			"crop_id": String(saved_tile.get("crop_id", "")),
			"growth": int(saved_tile.get("growth", 0)),
		}


func _initialize_tiles() -> void:
	tiles.clear()
	_add_missing_tiles()


func _add_missing_tiles() -> void:
	for y in height:
		for x in width:
			var cell := Vector2i(x, y)
			if tiles.has(cell):
				continue
			tiles[cell] = {
				"state": TileState.EMPTY,
				"crop_id": "",
				"growth": 0,
			}
