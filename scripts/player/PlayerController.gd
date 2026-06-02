extends CharacterBody2D
class_name PlayerController

@export var speed: float = 140.0

const FRAME_SIZE := Vector2(128, 256)
const FRAME_COUNT := 3
const ANIMATION_STEP_SECONDS := 0.16
const BASE_SPRITE_Y := -34.0
const BASE_SCALE := Vector2(0.22, 0.22)
const WALK_BOB_AMPLITUDE := 3.5
const WALK_SWAY_AMPLITUDE := 0.12
const WALK_SQUASH_AMPLITUDE := 0.08
const WALK_LEAN_AMPLITUDE := 0.03

@onready var sprite: Sprite2D = $Sprite2D

var _last_direction := Vector2.DOWN
var _animation_time := 0.0
var _frame_index := 0
var _walk_cycle_phase := 0.0
var _is_walking := false

func _ready() -> void:
	_register_move_action("move_left", [KEY_A, KEY_LEFT])
	_register_move_action("move_right", [KEY_D, KEY_RIGHT])
	_register_move_action("move_up", [KEY_W, KEY_UP])
	_register_move_action("move_down", [KEY_S, KEY_DOWN])
	apply_walk_visual(_last_direction, 1)


func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var is_moving := input_vector.length() > 0.0
	if is_moving:
		_last_direction = input_vector.normalized()
	advance_walk_animation(is_moving, delta)

	velocity = input_vector * speed
	move_and_slide()
	apply_walk_visual(_last_direction, _frame_index)


func facing_position(distance: float = 24.0) -> Vector2:
	return global_position + _last_direction * distance


func advance_walk_animation(is_moving: bool, delta: float) -> void:
	_is_walking = is_moving
	if is_moving:
		_animation_time += delta
		_walk_cycle_phase += TAU * delta / (ANIMATION_STEP_SECONDS * FRAME_COUNT)
		if _walk_cycle_phase >= TAU:
			_walk_cycle_phase = fmod(_walk_cycle_phase, TAU)
		while _animation_time >= ANIMATION_STEP_SECONDS:
			_animation_time -= ANIMATION_STEP_SECONDS
			_frame_index = (_frame_index + 1) % FRAME_COUNT
	else:
		_animation_time = 0.0
		_frame_index = 1
		_walk_cycle_phase = PI * 0.5


func apply_walk_visual(direction: Vector2, frame_index: int) -> void:
	if sprite == null:
		sprite = get_node_or_null("Sprite2D")
	if sprite == null:
		return

	var row := _direction_to_row(direction)
	var clamped_frame := clampi(frame_index, 0, FRAME_COUNT - 1)
	sprite.region_rect = Rect2(Vector2(clamped_frame * FRAME_SIZE.x, row * FRAME_SIZE.y), FRAME_SIZE)
	sprite.flip_h = direction.x > 0.0
	if not _is_walking:
		sprite.position.y = BASE_SPRITE_Y
		sprite.scale = BASE_SCALE
		sprite.rotation = 0.0
		return
	var walk_wave := sin(_walk_cycle_phase)
	var stride_wave := cos(_walk_cycle_phase)
	sprite.position.y = BASE_SPRITE_Y + walk_wave * WALK_BOB_AMPLITUDE
	var scale_x := 1.0 + stride_wave * WALK_SQUASH_AMPLITUDE
	var scale_y := 1.0 - stride_wave * WALK_SQUASH_AMPLITUDE
	sprite.scale = Vector2(BASE_SCALE.x * scale_x, BASE_SCALE.y * scale_y)
	var direction_sign := -1.0 if direction.x < 0.0 else 1.0
	if absf(direction.x) <= absf(direction.y):
		direction_sign = 1.0
	sprite.rotation = walk_wave * WALK_SWAY_AMPLITUDE + stride_wave * WALK_LEAN_AMPLITUDE * direction_sign


func _direction_to_row(direction: Vector2) -> int:
	if absf(direction.x) > absf(direction.y):
		return 1
	return 3 if direction.y < 0.0 else 0


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
