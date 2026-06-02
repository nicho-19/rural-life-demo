extends CharacterBody2D
class_name PlayerController

@export var speed: float = 140.0

const WALK_CYCLE_SECONDS := 0.48
const SKELETON_OFFSET := Vector2(0, -30)
const BODY_SCALE := Vector2(0.95, 0.95)
const ARM_SWING := 0.8
const LEG_SWING := 0.6
const TORSO_SWAY := 0.08
const HEAD_SWAY := 0.05
const BODY_BOB := 1.5
const SKIN_COLOR := Color(0.96, 0.82, 0.67, 1.0)
const SHIRT_COLOR := Color(0.77, 0.38, 0.23, 1.0)
const OVERALL_COLOR := Color(0.23, 0.41, 0.7, 1.0)
const BOOT_COLOR := Color(0.39, 0.25, 0.16, 1.0)
const HAT_COLOR := Color(0.71, 0.56, 0.28, 1.0)
const HAIR_COLOR := Color(0.23, 0.17, 0.12, 1.0)

@onready var skeleton: Skeleton2D = $Skeleton2D

var _last_direction := Vector2.DOWN
var _walk_phase := 0.0
var _is_moving := false

var _torso_bone: Bone2D
var _head_bone: Bone2D
var _left_arm_bone: Bone2D
var _right_arm_bone: Bone2D
var _left_leg_bone: Bone2D
var _right_leg_bone: Bone2D


func _ready() -> void:
	_register_move_action("move_left", [KEY_A, KEY_LEFT])
	_register_move_action("move_right", [KEY_D, KEY_RIGHT])
	_register_move_action("move_up", [KEY_W, KEY_UP])
	_register_move_action("move_down", [KEY_S, KEY_DOWN])
	_ensure_rig()
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
	_ensure_rig()
	if direction.length() > 0.0:
		_last_direction = direction.normalized()
	_is_moving = is_moving
	_apply_pose()


func advance_walk_cycle(delta: float, is_moving: bool) -> void:
	_ensure_rig()
	_is_moving = is_moving
	if is_moving:
		_walk_phase = fmod(_walk_phase + TAU * delta / WALK_CYCLE_SECONDS, TAU)
	else:
		_walk_phase = 0.0
	_apply_pose()


func _ensure_rig() -> void:
	if skeleton == null:
		skeleton = get_node_or_null("Skeleton2D")
	if skeleton == null:
		skeleton = Skeleton2D.new()
		skeleton.name = "Skeleton2D"
		add_child(skeleton)

	skeleton.position = SKELETON_OFFSET
	if skeleton.get_node_or_null("TorsoBone") == null:
		_torso_bone = _make_bone("TorsoBone", Vector2.ZERO, 18.0)
		_head_bone = _make_bone("HeadBone", Vector2(0, -20), 8.0)
		_left_arm_bone = _make_bone("LeftArmBone", Vector2(-9, -11), 18.0)
		_right_arm_bone = _make_bone("RightArmBone", Vector2(9, -11), 18.0)
		_left_leg_bone = _make_bone("LeftLegBone", Vector2(-5, 14), 20.0)
		_right_leg_bone = _make_bone("RightLegBone", Vector2(5, 14), 20.0)

		_head_bone.add_child(_make_bone("HeadEndBone", Vector2(0, 8), 2.0))
		_left_arm_bone.add_child(_make_bone("LeftHandBone", Vector2(0, 18), 2.0))
		_right_arm_bone.add_child(_make_bone("RightHandBone", Vector2(0, 18), 2.0))
		_left_leg_bone.add_child(_make_bone("LeftFootBone", Vector2(0, 20), 2.0))
		_right_leg_bone.add_child(_make_bone("RightFootBone", Vector2(0, 20), 2.0))

		_torso_bone.add_child(_head_bone)
		_torso_bone.add_child(_left_arm_bone)
		_torso_bone.add_child(_right_arm_bone)
		_torso_bone.add_child(_left_leg_bone)
		_torso_bone.add_child(_right_leg_bone)
		skeleton.add_child(_torso_bone)
	else:
		_torso_bone = skeleton.get_node_or_null("TorsoBone")
		_head_bone = skeleton.get_node_or_null("TorsoBone/HeadBone")
		_left_arm_bone = skeleton.get_node_or_null("TorsoBone/LeftArmBone")
		_right_arm_bone = skeleton.get_node_or_null("TorsoBone/RightArmBone")
		_left_leg_bone = skeleton.get_node_or_null("TorsoBone/LeftLegBone")
		_right_leg_bone = skeleton.get_node_or_null("TorsoBone/RightLegBone")

	_ensure_polygon(_torso_bone, "TorsoShape", OVERALL_COLOR, PackedVector2Array([
		Vector2(-9, -14), Vector2(9, -14), Vector2(10, 14), Vector2(-10, 14)
	]))
	_ensure_polygon(_torso_bone, "ShirtShape", SHIRT_COLOR, PackedVector2Array([
		Vector2(-9, -14), Vector2(9, -14), Vector2(8, -5), Vector2(-8, -5)
	]))
	_ensure_polygon(_head_bone, "HeadShape", SKIN_COLOR, PackedVector2Array([
		Vector2(-7, -8), Vector2(7, -8), Vector2(9, -2), Vector2(8, 6),
		Vector2(0, 9), Vector2(-8, 6), Vector2(-9, -2)
	]))
	_ensure_polygon(_head_bone, "HairShape", HAIR_COLOR, PackedVector2Array([
		Vector2(-7, -8), Vector2(7, -8), Vector2(5, -12), Vector2(-4, -11)
	]))
	_ensure_polygon(_head_bone, "HatBrim", HAT_COLOR, PackedVector2Array([
		Vector2(-11, -11), Vector2(11, -11), Vector2(9, -8), Vector2(-9, -8)
	]))
	_ensure_polygon(_head_bone, "HatTop", HAT_COLOR, PackedVector2Array([
		Vector2(-7, -16), Vector2(6, -16), Vector2(8, -11), Vector2(-8, -11)
	]))
	_ensure_polygon(_left_arm_bone, "LeftArmShape", SHIRT_COLOR, PackedVector2Array([
		Vector2(-2, 0), Vector2(2, 0), Vector2(3, 18), Vector2(-3, 18)
	]))
	_ensure_polygon(_right_arm_bone, "RightArmShape", SHIRT_COLOR, PackedVector2Array([
		Vector2(-2, 0), Vector2(2, 0), Vector2(3, 18), Vector2(-3, 18)
	]))
	_ensure_polygon(_left_leg_bone, "LeftLegShape", OVERALL_COLOR, PackedVector2Array([
		Vector2(-3, 0), Vector2(3, 0), Vector2(4, 18), Vector2(-4, 18)
	]))
	_ensure_polygon(_right_leg_bone, "RightLegShape", OVERALL_COLOR, PackedVector2Array([
		Vector2(-3, 0), Vector2(3, 0), Vector2(4, 18), Vector2(-4, 18)
	]))
	_ensure_polygon(_left_leg_bone, "LeftBootShape", BOOT_COLOR, PackedVector2Array([
		Vector2(-5, 16), Vector2(5, 16), Vector2(6, 20), Vector2(-4, 20)
	]))
	_ensure_polygon(_right_leg_bone, "RightBootShape", BOOT_COLOR, PackedVector2Array([
		Vector2(-5, 16), Vector2(5, 16), Vector2(6, 20), Vector2(-4, 20)
	]))


func _apply_pose() -> void:
	if _torso_bone == null:
		return

	var direction_name := _direction_to_name(_last_direction)
	var walk_wave := sin(_walk_phase)
	var counter_wave := sin(_walk_phase + PI)
	var body_tilt := 0.0
	var body_bob := 0.0

	if _is_moving:
		body_tilt = walk_wave * TORSO_SWAY
		body_bob = absf(cos(_walk_phase)) * BODY_BOB

	skeleton.position = SKELETON_OFFSET + Vector2(0, body_bob)
	skeleton.scale = Vector2(-BODY_SCALE.x if direction_name == "left" else BODY_SCALE.x, BODY_SCALE.y)

	_torso_bone.rotation = body_tilt
	_head_bone.rotation = -walk_wave * HEAD_SWAY
	_left_arm_bone.rotation = walk_wave * ARM_SWING
	_right_arm_bone.rotation = counter_wave * ARM_SWING
	_left_leg_bone.rotation = counter_wave * LEG_SWING
	_right_leg_bone.rotation = walk_wave * LEG_SWING

	match direction_name:
		"up":
			_torso_bone.rotation -= 0.05
			_head_bone.rotation -= 0.05
		"down":
			_torso_bone.rotation += 0.03
		_:
			pass

	if not _is_moving:
		_torso_bone.rotation = 0.0
		_head_bone.rotation = 0.0
		_left_arm_bone.rotation = 0.0
		_right_arm_bone.rotation = 0.0
		_left_leg_bone.rotation = 0.0
		_right_leg_bone.rotation = 0.0


func _make_bone(bone_name: String, bone_position: Vector2, bone_length: float) -> Bone2D:
	var bone := Bone2D.new()
	bone.name = bone_name
	bone.position = bone_position
	bone.set("length", bone_length)
	bone.set("autocalculate_length_and_angle", false)
	return bone


func _ensure_polygon(parent: Node, polygon_name: String, color: Color, points: PackedVector2Array) -> void:
	var polygon: Polygon2D = parent.get_node_or_null(polygon_name)
	if polygon == null:
		polygon = Polygon2D.new()
		polygon.name = polygon_name
		parent.add_child(polygon)
	polygon.color = color
	polygon.polygon = points


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
