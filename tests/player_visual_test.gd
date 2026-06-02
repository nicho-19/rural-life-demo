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
	if not String(sprite.texture.resource_path).ends_with("walking_sprite_sheet.png"):
		_fail("Player should use the walking sprite sheet for movement.")
		return

	var image := Image.new()
	var png_bytes := FileAccess.get_file_as_bytes("res://assets/characters/walking_sprite_sheet.png")
	if png_bytes.is_empty():
		_fail("Player walking sprite sheet bytes should be readable.")
		return
	var load_error := image.load_png_from_buffer(png_bytes)
	if load_error != OK:
		_fail("Player walking sprite sheet should be loadable.")
		return
	if image.get_pixel(0, 0).a > 0.05:
		_fail("Player walking sprite sheet corner should be transparent, not white.")
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
