extends SceneTree

const FRAME_SIZE := Vector2(128, 256)

func _init() -> void:
	var scene: PackedScene = load("res://scenes/player/Player.tscn")
	var player: Node = scene.instantiate()
	var sprite: Sprite2D = player.get_node("Sprite2D")

	if sprite.texture == null or not sprite.texture.resource_path.ends_with("walking_sprite_sheet.png"):
		_fail(player, "Player should use walking_sprite_sheet.png for directional movement frames.")
		return

	if sprite.region_rect.size != FRAME_SIZE:
		_fail(player, "Player sprite region should use 128x256 frames from the walking sheet.")
		return

	if not player.has_method("apply_walk_visual"):
		_fail(player, "PlayerController should expose apply_walk_visual(direction, frame_index).")
		return

	player.call("apply_walk_visual", Vector2.RIGHT, 2)
	if sprite.region_rect.position != Vector2(256, 512):
		_fail(player, "Right-facing frame 2 should select column 2, row 2 from the sprite sheet.")
		return

	player.call("apply_walk_visual", Vector2.UP, 1)
	if sprite.region_rect.position != Vector2(128, 768):
		_fail(player, "Up-facing frame 1 should select column 1, row 3 from the sprite sheet.")
		return

	player.free()
	print("PASS player_walk_animation_test")
	quit(0)


func _fail(player: Node, message: String) -> void:
	player.free()
	push_error(message)
	quit(1)
