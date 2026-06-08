extends Node3D

const VIEWMODEL_SCALE = 0.25
const BASE_POSITION = Vector3(0.0, -0.52, -0.82)
const BASE_ROTATION = Vector3(deg_to_rad(-74.0), 0.0, 0.0)
const CROUCH_OFFSET = Vector3(0.0, -0.02, 0.05)
const SLIDE_OFFSET = Vector3(0.0, -0.09, 0.08)
const TIRED_OFFSET = Vector3(0.0, -0.035, 0.0)

var bob_time = 0.0
var idle_time = 0.0
var landing_shock = 0.0

var _running = false
var _crouching = false
var _sliding = false
var _moving = false
var _sprint_locked = false
var _h_speed = 0.0
var _flashlight_visible = false
var _pose_ready = false

@onready var arms_model: Node3D = $ArmsModel

func _ready():
	arms_model.scale = Vector3.ONE * VIEWMODEL_SCALE
	arms_model.position = BASE_POSITION
	arms_model.rotation = BASE_ROTATION
	_configure_view_model(arms_model)
	call_deferred("_setup_arm_pose")

func update_state(running: bool, crouching: bool, sliding: bool, moving: bool, sprint_locked: bool, h_speed: float):
	_running = running
	_crouching = crouching
	_sliding = sliding
	_moving = moving
	_sprint_locked = sprint_locked
	_h_speed = h_speed

func trigger_landing(fall_speed: float):
	if fall_speed > 2.5:
		landing_shock = clamp(fall_speed * 0.018, 0.05, 0.18)

func show_flashlight(is_visible: bool):
	_flashlight_visible = is_visible

func _setup_arm_pose():
	if _pose_ready:
		return

	_pose_ready = true
	var skeleton = _find_skeleton(arms_model)
	if not skeleton:
		return

	_pose_bone(skeleton, "Bicep.R", Vector3(deg_to_rad(-6.0), deg_to_rad(-18.0), deg_to_rad(8.0)))
	_pose_bone(skeleton, "Forearm.R", Vector3(deg_to_rad(0.0), deg_to_rad(-12.0), deg_to_rad(4.0)))
	_pose_bone(skeleton, "Palm.R", Vector3(deg_to_rad(-4.0), deg_to_rad(-8.0), deg_to_rad(6.0)))
	_pose_bone(skeleton, "R_arm", Vector3(deg_to_rad(-4.0), deg_to_rad(-16.0), deg_to_rad(7.0)))
	_pose_bone(skeleton, "R_elbow", Vector3(deg_to_rad(0.0), deg_to_rad(-10.0), deg_to_rad(4.0)))
	_pose_bone(skeleton, "R_wrist", Vector3(deg_to_rad(-3.0), deg_to_rad(-7.0), deg_to_rad(5.0)))

	_pose_bone(skeleton, "Bicep.L", Vector3(deg_to_rad(-6.0), deg_to_rad(18.0), deg_to_rad(-8.0)))
	_pose_bone(skeleton, "Forearm.L", Vector3(deg_to_rad(0.0), deg_to_rad(12.0), deg_to_rad(-4.0)))
	_pose_bone(skeleton, "Palm.L", Vector3(deg_to_rad(-4.0), deg_to_rad(8.0), deg_to_rad(-6.0)))
	_pose_bone(skeleton, "L_arm", Vector3(deg_to_rad(-4.0), deg_to_rad(16.0), deg_to_rad(-7.0)))
	_pose_bone(skeleton, "L_elbow", Vector3(deg_to_rad(0.0), deg_to_rad(10.0), deg_to_rad(-4.0)))
	_pose_bone(skeleton, "L_wrist", Vector3(deg_to_rad(-3.0), deg_to_rad(7.0), deg_to_rad(-5.0)))

func _pose_bone(skeleton: Skeleton3D, name_prefix: String, euler: Vector3):
	var bone_index = _find_bone_by_prefix(skeleton, name_prefix)
	if bone_index == -1:
		return

	skeleton.set_bone_pose_rotation(bone_index, Quaternion.from_euler(euler))

func _find_bone_by_prefix(skeleton: Skeleton3D, name_prefix: String) -> int:
	for index in range(skeleton.get_bone_count()):
		if skeleton.get_bone_name(index).begins_with(name_prefix):
			return index
	return -1

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D

	for child in node.get_children():
		var found = _find_skeleton(child)
		if found:
			return found

	return null

func _process(delta: float):
	idle_time += delta
	visible = true
	arms_model.visible = true

	var bob_speed = 0.0
	var bob_x = 0.0
	var bob_y = 0.0
	var bob_z = 0.0

	if _sliding:
		bob_time = move_toward(bob_time, 0.0, delta * 7.0)
	elif _running and _moving:
		bob_speed = 18.0
		bob_time += delta * bob_speed
		bob_x = sin(bob_time) * 0.018
		bob_y = -abs(sin(bob_time * 0.5)) * 0.018
		bob_z = sin(bob_time * 0.5) * 0.018
	elif _moving:
		bob_speed = 12.0
		bob_time += delta * bob_speed
		bob_x = sin(bob_time) * 0.01
		bob_y = -abs(sin(bob_time * 0.5)) * 0.01
	else:
		bob_time = move_toward(bob_time, 0.0, delta * 5.0)

	landing_shock = lerp(landing_shock, 0.0, delta * 8.0)

	var state_offset = Vector3.ZERO
	if _sliding:
		state_offset = SLIDE_OFFSET
	elif _crouching:
		state_offset = CROUCH_OFFSET
	elif _sprint_locked:
		state_offset = TIRED_OFFSET

	var breathe = sin(idle_time * 1.15) * 0.003
	var target_position = BASE_POSITION + state_offset + Vector3(bob_x, bob_y + breathe - landing_shock, bob_z)
	var target_rotation = BASE_ROTATION + Vector3(-landing_shock * 0.45, 0.0, -bob_x * 1.4)

	arms_model.position = arms_model.position.lerp(target_position, delta * 18.0)
	arms_model.rotation = arms_model.rotation.lerp(target_rotation, delta * 14.0)
	arms_model.scale = arms_model.scale.lerp(Vector3.ONE * VIEWMODEL_SCALE, delta * 18.0)

func _configure_view_model(node: Node):
	if node is GeometryInstance3D:
		node.visible = true
		node.layers = 1
		node.extra_cull_margin = 2.0
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	for child in node.get_children():
		_configure_view_model(child)
