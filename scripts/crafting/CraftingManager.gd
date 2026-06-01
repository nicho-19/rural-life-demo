extends RefCounted
class_name CraftingManager

var recipes: Dictionary = {}
var items: Dictionary = {}

func setup(recipe_data: Dictionary, item_data: Dictionary) -> void:
	recipes = recipe_data
	items = item_data


func craft(inventory, recipe_id: String) -> Dictionary:
	var recipe: Dictionary = recipes.get(recipe_id, {})
	if recipe.is_empty():
		return {
			"success": false,
			"message": "没有这个加工配方。",
		}

	var ingredients: Dictionary = recipe.get("ingredients", {})
	for item_id in ingredients.keys():
		var required := int(ingredients[item_id])
		if inventory.count(String(item_id)) < required:
			return {
				"success": false,
				"message": "原料不足，不能加工%s。" % _recipe_name(recipe_id),
			}

	for item_id in ingredients.keys():
		inventory.remove_item(String(item_id), int(ingredients[item_id]))

	var output_item_id := String(recipe.get("output", ""))
	var output_amount: int = max(1, int(recipe.get("output_amount", 1)))
	inventory.add_item(output_item_id, output_amount)

	return {
		"success": true,
		"message": "加工完成：%s x%d。" % [_item_name(output_item_id), output_amount],
		"recipe_id": recipe_id,
		"output_item_id": output_item_id,
		"output_amount": output_amount,
	}


func describe(inventory) -> String:
	var lines: Array[String] = ["加工坊"]
	for recipe_id in recipes.keys():
		var recipe: Dictionary = recipes[recipe_id]
		var output_item_id := String(recipe.get("output", ""))
		var output_amount: int = max(1, int(recipe.get("output_amount", 1)))
		lines.append("%s -> %s x%d%s" % [
			_ingredients_text(recipe.get("ingredients", {}), inventory),
			_item_name(output_item_id),
			output_amount,
			"（可做）" if can_craft(inventory, String(recipe_id)) else "",
		])
	return "\n".join(lines)


func can_craft(inventory, recipe_id: String) -> bool:
	var recipe: Dictionary = recipes.get(recipe_id, {})
	if recipe.is_empty():
		return false
	var ingredients: Dictionary = recipe.get("ingredients", {})
	for item_id in ingredients.keys():
		if inventory.count(String(item_id)) < int(ingredients[item_id]):
			return false
	return true


func recipe_ids() -> Array[String]:
	var ids: Array[String] = []
	for recipe_id in recipes.keys():
		ids.append(String(recipe_id))
	return ids


func _ingredients_text(ingredients_value, inventory) -> String:
	var ingredients: Dictionary = ingredients_value if ingredients_value is Dictionary else {}
	var parts: Array[String] = []
	for item_id in ingredients.keys():
		var id := String(item_id)
		var required := int(ingredients[item_id])
		parts.append("%s %d/%d" % [_item_name(id), inventory.count(id), required])
	return " + ".join(parts)


func _recipe_name(recipe_id: String) -> String:
	var recipe: Dictionary = recipes.get(recipe_id, {})
	return String(recipe.get("name", recipe_id))


func _item_name(item_id: String) -> String:
	var item: Dictionary = items.get(item_id, {})
	return String(item.get("name", item_id))
