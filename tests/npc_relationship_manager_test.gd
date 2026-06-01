extends SceneTree

const InventoryScript := preload("res://scripts/inventory/Inventory.gd")

func _init() -> void:
	var script = load("res://scripts/npcs/NpcRelationshipManager.gd")
	if script == null:
		_fail("NpcRelationshipManager script should exist.")
		return

	var npcs = script.new()
	npcs.setup({
		"mayor_lin": {
			"name": "Lin",
			"loved": ["turnip"],
			"liked": ["potato"],
			"disliked": ["milk"],
			"hint": "Likes roots."
		},
		"meizi": {
			"name": "Meizi",
			"loved": ["egg"],
			"liked": ["corn"],
			"disliked": ["cabbage"],
			"hint": "Likes breakfast."
		}
	})

	var inventory = InventoryScript.new()
	inventory.add_item("turnip", 2)
	inventory.add_item("potato", 1)
	inventory.add_item("milk", 1)
	inventory.add_item("animal_feed", 1)

	var loved: Dictionary = npcs.give_gift("mayor_lin", "turnip", inventory, 3)
	if not bool(loved.get("success", false)):
		_fail("Loved gift should succeed when inventory has the item.")
		return
	if inventory.count("turnip") != 1:
		_fail("Giving a gift should consume exactly one inventory item.")
		return
	if npcs.friendship_for("mayor_lin") != 12:
		_fail("Loved gift should add 12 friendship.")
		return
	if not npcs.was_gifted_today("mayor_lin"):
		_fail("NPC should be marked gifted for the current day.")
		return

	var second: Dictionary = npcs.give_gift("mayor_lin", "potato", inventory, 3)
	if bool(second.get("success", true)):
		_fail("Each NPC should accept at most one gift per day.")
		return
	if inventory.count("potato") != 1:
		_fail("Rejected duplicate daily gift should not consume inventory.")
		return

	npcs.start_day(4)
	var disliked: Dictionary = npcs.give_gift("mayor_lin", "milk", inventory, 4)
	if not bool(disliked.get("success", false)):
		_fail("Gift should be accepted again on a new day.")
		return
	if npcs.friendship_for("mayor_lin") != 9:
		_fail("Disliked gift should subtract 3 friendship.")
		return

	var invalid_item: Dictionary = npcs.give_gift("meizi", "animal_feed", inventory, 4)
	if bool(invalid_item.get("success", true)):
		_fail("Only allowed crop and animal product gifts should be accepted.")
		return

	npcs.load_save_data({
		"friendship": {"mayor_lin": 250, "meizi": -20},
		"last_gift_day": {"mayor_lin": 4}
	})
	if npcs.friendship_for("mayor_lin") != 100 or npcs.friendship_for("meizi") != 0:
		_fail("Loaded friendship should clamp to 0..100.")
		return
	if not npcs.was_gifted_today("mayor_lin", 4):
		_fail("Loaded gift day should restore today's gifted state.")
		return

	var saved: Dictionary = npcs.to_save_data()
	if not saved.has("friendship") or not saved.has("last_gift_day"):
		_fail("NPC relationships should save friendship and gift-day state.")
		return

	var description: String = npcs.describe()
	if not description.contains("Lin") or not description.contains("Likes roots."):
		_fail("NPC description should include names and preference hints.")
		return

	var briefing: String = npcs.briefing_text()
	if not briefing.contains("Lin") or not briefing.contains("Meizi"):
		_fail("NPC briefing should summarize villagers.")
		return

	print("PASS npc_relationship_manager_test")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
