extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/player/Player.tscn")
	var player: Node = scene.instantiate()
	root.add_child(player)

	if not player.has_method("set_walk_state"):
		_fail(player, "PlayerController should expose set_walk_state(direction, is_moving).")
		return
	if not player.has_method("advance_walk_cycle"):
		_fail(player, "PlayerController should expose advance_walk_cycle(delta, is_moving).")
		return

	var skeleton: Skeleton2D = player.get_node_or_null("Skeleton2D")
	if skeleton == null:
		_fail(player, "Player should expose a Skeleton2D node.")
		return
	player.call("set_walk_state", Vector2.DOWN, false)

	var left_arm: Bone2D = skeleton.get_node_or_null("TorsoBone/LeftArmBone")
	var left_forearm: Bone2D = skeleton.get_node_or_null("TorsoBone/LeftArmBone/LeftForearmBone")
	var right_arm: Bone2D = skeleton.get_node_or_null("TorsoBone/RightArmBone")
	var right_forearm: Bone2D = skeleton.get_node_or_null("TorsoBone/RightArmBone/RightForearmBone")
	var left_leg: Bone2D = skeleton.get_node_or_null("TorsoBone/LeftLegBone")
	var left_calf: Bone2D = skeleton.get_node_or_null("TorsoBone/LeftLegBone/LeftCalfBone")
	var right_leg: Bone2D = skeleton.get_node_or_null("TorsoBone/RightLegBone")
	var right_calf: Bone2D = skeleton.get_node_or_null("TorsoBone/RightLegBone/RightCalfBone")
	if left_arm == null or left_forearm == null or right_arm == null or right_forearm == null or left_leg == null or left_calf == null or right_leg == null or right_calf == null:
		_fail(player, "Player skeleton should expose upper and lower limb bones for walking animation.")
		return

	player.call("set_walk_state", Vector2.RIGHT, false)
	var idle_left_arm := left_arm.rotation
	var idle_left_forearm := left_forearm.rotation
	var idle_right_arm := right_arm.rotation
	var idle_right_forearm := right_forearm.rotation
	var idle_left_leg := left_leg.rotation
	var idle_left_calf := left_calf.rotation
	var idle_right_leg := right_leg.rotation
	var idle_right_calf := right_calf.rotation

	player.call("set_walk_state", Vector2.RIGHT, true)
	player.call("advance_walk_cycle", 0.18, true)
	if is_equal_approx(left_arm.rotation, idle_left_arm):
		_fail(player, "Walking right should rotate the left arm bone.")
		return
	if is_equal_approx(right_arm.rotation, idle_right_arm):
		_fail(player, "Walking right should rotate the right arm bone.")
		return
	if is_equal_approx(left_forearm.rotation, idle_left_forearm) or is_equal_approx(right_forearm.rotation, idle_right_forearm):
		_fail(player, "Walking right should bend both forearm bones.")
		return
	if is_equal_approx(left_leg.rotation, idle_left_leg):
		_fail(player, "Walking right should rotate the left leg bone.")
		return
	if is_equal_approx(right_leg.rotation, idle_right_leg):
		_fail(player, "Walking right should rotate the right leg bone.")
		return
	if is_equal_approx(left_calf.rotation, idle_left_calf) or is_equal_approx(right_calf.rotation, idle_right_calf):
		_fail(player, "Walking right should bend both calf bones.")
		return
	if signf(left_arm.rotation) == signf(right_arm.rotation):
		_fail(player, "Walking arms should swing in opposite directions.")
		return
	if signf(left_leg.rotation) == signf(right_leg.rotation):
		_fail(player, "Walking legs should swing in opposite directions.")
		return

	player.call("set_walk_state", Vector2.LEFT, false)
	if not is_zero_approx(left_arm.rotation) or not is_zero_approx(right_arm.rotation) or not is_zero_approx(left_forearm.rotation) or not is_zero_approx(right_forearm.rotation):
		_fail(player, "Idle player should settle arm bones back near the resting pose.")
		return

	player.free()
	print("PASS player_walk_animation_test")
	quit(0)


func _fail(player: Node, message: String) -> void:
	player.free()
	push_error(message)
	quit(1)
