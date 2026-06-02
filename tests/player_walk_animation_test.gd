extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/player/Player.tscn")
	var player: Node = scene.instantiate()
	root.add_child(player)
	var sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D")

	if sprite == null:
		_fail(player, "Player should expose an AnimatedSprite2D node.")
		return

	if not player.has_method("set_walk_state"):
		_fail(player, "PlayerController should expose set_walk_state(direction, is_moving).")
		return
	if not player.has_method("advance_walk_cycle"):
		_fail(player, "PlayerController should expose advance_walk_cycle(delta, is_moving).")
		return

	player.call("set_walk_state", Vector2.RIGHT, true)
	if sprite.animation != &"walk_right":
		_fail(player, "Moving right should select the walk_right animation.")
		return
	if not sprite.is_playing():
		_fail(player, "Moving player should play the walk animation.")
		return

	var before_frame := sprite.frame
	player.call("advance_walk_cycle", 0.25, true)
	if sprite.frame == before_frame:
		_fail(player, "Walking animation should advance frames over time.")
		return

	player.call("set_walk_state", Vector2.UP, true)
	if sprite.animation != &"walk_up":
		_fail(player, "Moving up should select the walk_up animation.")
		return

	player.call("set_walk_state", Vector2.LEFT, false)
	if sprite.animation != &"idle_left":
		_fail(player, "Stopping while facing left should select the idle_left animation.")
		return
	if sprite.is_playing():
		_fail(player, "Idle player should stop the walk animation.")
		return
	if sprite.frame != 1:
		_fail(player, "Idle animation should rest on the middle standing frame.")
		return

	player.free()
	print("PASS player_walk_animation_test")
	quit(0)


func _fail(player: Node, message: String) -> void:
	player.free()
	push_error(message)
	quit(1)
