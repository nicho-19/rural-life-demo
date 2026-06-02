extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/player/Player.tscn")
	var player: Node = scene.instantiate()
	root.add_child(player)

	if player.get_node_or_null("AnimatedSprite2D") != null:
		_fail(player, "Player should no longer use AnimatedSprite2D for the character body.")
		return
	if player.get_node_or_null("Sprite2D") != null:
		_fail(player, "Player should no longer use a single Sprite2D body image.")
		return

	var skeleton: Skeleton2D = player.get_node_or_null("Skeleton2D")
	if skeleton == null:
		_fail(player, "Player.tscn should contain a Skeleton2D rig.")
		return
	if player.has_method("set_walk_state"):
		player.call("set_walk_state", Vector2.DOWN, false)

	var bone_paths := {
		"TorsoBone": "TorsoBone",
		"HeadBone": "TorsoBone/HeadBone",
		"LeftArmBone": "TorsoBone/LeftArmBone",
		"RightArmBone": "TorsoBone/RightArmBone",
		"LeftLegBone": "TorsoBone/LeftLegBone",
		"RightLegBone": "TorsoBone/RightLegBone",
	}
	for bone_name in bone_paths.keys():
		var bone := skeleton.get_node_or_null(bone_paths[bone_name])
		if bone == null:
			_fail(player, "Player skeleton should provide the %s bone." % bone_name)
			return
		if not bone is Bone2D:
			_fail(player, "Player %s should be a Bone2D node." % bone_name)
			return

	var head_shape := skeleton.get_node_or_null("TorsoBone/HeadBone/HeadShape")
	if head_shape == null or not head_shape is Polygon2D:
		_fail(player, "Player head should be rendered from a Polygon2D shape attached to the skeleton.")
		return

	var torso_shape := skeleton.get_node_or_null("TorsoBone/TorsoShape")
	if torso_shape == null or not torso_shape is Polygon2D:
		_fail(player, "Player torso should be rendered from a Polygon2D shape attached to the skeleton.")
		return

	player.free()
	print("PASS player_visual_test")
	quit(0)


func _fail(player: Node, message: String) -> void:
	player.free()
	push_error(message)
	quit(1)
