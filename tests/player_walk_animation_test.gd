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
	if sprite.region_rect.position != Vector2(256, 256):
		_fail(player, "Side-facing movement should select frame 2 from the side-view row.")
		return
	if not sprite.flip_h:
		_fail(player, "Right-facing movement should mirror the side-view sprite.")
		return

	player.call("apply_walk_visual", Vector2.UP, 1)
	if sprite.region_rect.position != Vector2(128, 768):
		_fail(player, "Up-facing movement should select frame 1 from the back-view row.")
		return
	if sprite.flip_h:
		_fail(player, "Up-facing movement should not keep the sprite mirrored.")
		return

	player.free()
	print("PASS player_walk_animation_test")
	quit(0)


func _fail(player: Node, message: String) -> void:
	player.free()
	push_error(message)
	quit(1)
