extends CharacterBody2D
class_name PlayerController

@export var speed: float = 140.0

const FRAME_SIZE := Vector2(128, 256)
const FRAME_COUNT := 3
const BASE_SCALE := Vector2(0.22, 0.22)
const WALK_FRAME_SECONDS := 0.14

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _last_direction := Vector2.DOWN
var _animation_time := 0.0


func _ready() -> void:
	_register_move_action("move_left", [KEY_A, KEY_LEFT])
	_register_move_action("move_right", [KEY_D, KEY_RIGHT])
	_register_move_action("move_up", [KEY_W, KEY_UP])
	_register_move_action("move_down", [KEY_S, KEY_DOWN])
	_setup_sprite_frames()
	set_walk_state(_last_direction, false)


func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var is_moving := input_vector.length() > 0.0
	if is_moving:
		_last_direction = input_vector.normalized()
	advance_walk_cycle(delta, is_moving)

	velocity = input_vector * speed
	move_and_slide()
	set_walk_state(_last_direction, is_moving)


func facing_position(distance: float = 24.0) -> Vector2:
	return global_position + _last_direction * distance


func set_walk_state(direction: Vector2, is_moving: bool) -> void:
	if animated_sprite == null:
		animated_sprite = get_node_or_null("AnimatedSprite2D")
	if animated_sprite == null:
		return
	_setup_sprite_frames()

	var facing := _direction_to_name(direction)
	animated_sprite.flip_h = facing == "right"
	var animation_name := "%s_%s" % ["walk" if is_moving else "idle", facing]

	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)

	if is_moving:
		animated_sprite.speed_scale = 1.0
		if not animated_sprite.is_playing():
			animated_sprite.play(animation_name)
		return

	animated_sprite.stop()
	animated_sprite.frame = 1
	animated_sprite.frame_progress = 0.0


func advance_walk_cycle(delta: float, is_moving: bool) -> void:
	if animated_sprite == null:
		animated_sprite = get_node_or_null("AnimatedSprite2D")
	if animated_sprite == null:
		return
	if not is_moving:
		_animation_time = 0.0
		animated_sprite.frame = 1
		return

	_animation_time += delta
	while _animation_time >= WALK_FRAME_SECONDS:
		_animation_time -= WALK_FRAME_SECONDS
		animated_sprite.frame = (animated_sprite.frame + 1) % FRAME_COUNT


func _setup_sprite_frames() -> void:
	if animated_sprite == null:
		return
	if animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation("walk_down"):
		return

	var sheet: Texture2D = load("res://assets/characters/walking_sprite_sheet.png")
	var frames := SpriteFrames.new()
	_add_direction_frames(frames, sheet, "down", 0)
	_add_direction_frames(frames, sheet, "left", 1)
	_add_direction_frames(frames, sheet, "right", 1)
	_add_direction_frames(frames, sheet, "up", 3)
	animated_sprite.sprite_frames = frames
	animated_sprite.scale = BASE_SCALE


func _add_direction_frames(frames: SpriteFrames, sheet: Texture2D, direction_name: String, row: int) -> void:
	var walk_name := "walk_%s" % direction_name
	var idle_name := "idle_%s" % direction_name
	frames.add_animation(walk_name)
	frames.set_animation_loop(walk_name, true)
	frames.set_animation_speed(walk_name, 7.5)
	frames.add_animation(idle_name)
	frames.set_animation_loop(idle_name, false)
	frames.set_animation_speed(idle_name, 0.0)

	for frame_index in FRAME_COUNT:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(Vector2(frame_index * FRAME_SIZE.x, row * FRAME_SIZE.y), FRAME_SIZE)
		frames.add_frame(walk_name, atlas)
		frames.add_frame(idle_name, atlas)


func _direction_to_name(direction: Vector2) -> String:
	if absf(direction.x) > absf(direction.y):
		return "right" if direction.x > 0.0 else "left"
	return "up" if direction.y < 0.0 else "down"


func _register_move_action(action_name: StringName, keys: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for key in keys:
		var already_registered := false
		for event in InputMap.action_get_events(action_name):
			if event is InputEventKey and event.physical_keycode == key:
				already_registered = true
				break

		if not already_registered:
			var input_event := InputEventKey.new()
			input_event.physical_keycode = key
			InputMap.action_add_event(action_name, input_event)
