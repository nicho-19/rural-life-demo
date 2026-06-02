extends SceneTree

const FRAME_SIZE := Vector2(128, 256)
const ANIMATION_STEP_SECONDS := 0.16

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

	if not player.has_method("advance_walk_animation"):
		_fail(player, "PlayerController should expose advance_walk_animation(is_moving, delta).")
		return

	player.call("advance_walk_animation", true, ANIMATION_STEP_SECONDS + 0.01)
	player.call("advance_walk_animation", true, ANIMATION_STEP_SECONDS + 0.01)
	player.call("apply_walk_visual", Vector2.RIGHT, player.get("_frame_index"))
	var moving_frame := sprite.region_rect.position
	var moving_offset_y := sprite.position.y
	if moving_frame == Vector2(128, 256):
		_fail(player, "Moving right should advance beyond the idle side-facing frame.")
		return
	if is_equal_approx(moving_offset_y, -34.0):
		_fail(player, "Moving walk animation should visibly bob the sprite.")
		return

	player.call("advance_walk_animation", false, 0.0)
	player.call("apply_walk_visual", Vector2.RIGHT, 1)
	var idle_rotation := sprite.rotation
	var idle_scale := sprite.scale
	player.call("advance_walk_animation", true, ANIMATION_STEP_SECONDS * 0.5)
	player.call("apply_walk_visual", Vector2.RIGHT, player.get("_frame_index"))
	if is_equal_approx(sprite.rotation, idle_rotation):
		_fail(player, "Walking animation should sway continuously between frame changes.")
		return
	if sprite.scale.is_equal_approx(idle_scale):
		_fail(player, "Walking animation should squash or stretch continuously while moving.")
		return

	player.free()
	print("PASS player_walk_animation_test")
	quit(0)


func _fail(player: Node, message: String) -> void:
	player.free()
	push_error(message)
	quit(1)
