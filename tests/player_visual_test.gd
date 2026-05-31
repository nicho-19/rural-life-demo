extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/player/Player.tscn")
	var player: Node = scene.instantiate()
	var sprite: Node = player.get_node_or_null("Sprite2D")

	if sprite == null:
		_fail("Player.tscn should contain a Sprite2D child for pixel-art visuals.")
		return

	if not sprite is Sprite2D:
		_fail("Player Sprite2D child should be a Sprite2D node.")
		return

	if sprite.texture == null:
		_fail("Player Sprite2D should have a texture assigned.")
		return

	var source := FileAccess.get_file_as_string("res://scripts/player/PlayerController.gd")
	if source.contains("func _draw()"):
		_fail("PlayerController.gd should not manually draw the player once Sprite2D is used.")
		player.free()
		return

	print("PASS player_visual_test")
	player.free()
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
