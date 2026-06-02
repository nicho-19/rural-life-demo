extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/player/Player.tscn")
	var player: Node = scene.instantiate()
	root.add_child(player)
	var sprite: Node = player.get_node_or_null("AnimatedSprite2D")

	if sprite == null:
		_fail(player, "Player.tscn should contain an AnimatedSprite2D child for character animation.")
		return

	if not sprite is AnimatedSprite2D:
		_fail(player, "Player animated child should be an AnimatedSprite2D node.")
		return

	var animated_sprite: AnimatedSprite2D = sprite
	if player.has_method("set_walk_state"):
		player.call("set_walk_state", Vector2.DOWN, false)
	if animated_sprite.sprite_frames == null:
		_fail(player, "Player AnimatedSprite2D should have SpriteFrames assigned.")
		return

	for animation_name in ["walk_down", "walk_left", "walk_right", "walk_up"]:
		if not animated_sprite.sprite_frames.has_animation(animation_name):
			_fail(player, "Player should provide the %s animation." % animation_name)
			return
		if animated_sprite.sprite_frames.get_frame_count(animation_name) < 3:
			_fail(player, "Player %s animation should contain at least 3 frames." % animation_name)
			return

	var sample_texture := animated_sprite.sprite_frames.get_frame_texture("walk_down", 1)
	if sample_texture == null:
		_fail(player, "Player walk_down animation should expose frame textures.")
		return
	if not sample_texture is AtlasTexture:
		_fail(player, "Player walk_down frames should be atlas slices from the walking sheet.")
		return
	var atlas_texture: AtlasTexture = sample_texture
	if atlas_texture.atlas == null or not String(atlas_texture.atlas.resource_path).ends_with("walking_sprite_sheet.png"):
		_fail(player, "Player animation frames should come from walking_sprite_sheet.png.")
		return

	var runtime_image: Image = atlas_texture.get_image()
	if runtime_image == null:
		_fail(player, "Player walking frame texture should expose runtime image data.")
		return
	if runtime_image.get_pixel(40, 40).a > 0.05:
		_fail(player, "Imported player walking frame background should be transparent.")
		return

	var image := Image.new()
	var png_bytes := FileAccess.get_file_as_bytes("res://assets/characters/walking_sprite_sheet.png")
	if png_bytes.is_empty():
		_fail(player, "Player walking sprite sheet bytes should be readable.")
		return
	var load_error := image.load_png_from_buffer(png_bytes)
	if load_error != OK:
		_fail(player, "Player walking sprite sheet should be loadable.")
		return
	if image.get_pixel(0, 0).a > 0.05:
		_fail(player, "Player walking sprite sheet corner should be transparent, not white.")
		return

	player.free()
	print("PASS player_visual_test")
	quit(0)


func _fail(player: Node, message: String) -> void:
	player.free()
	push_error(message)
	quit(1)
