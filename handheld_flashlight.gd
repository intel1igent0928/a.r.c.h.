extends Node3D

const BASE_POSITION := Vector3(0.23, -0.23, -0.60)
const BASE_ROTATION := Vector3(deg_to_rad(0.0), deg_to_rad(0.0), deg_to_rad(-2.5))
const CROUCH_OFFSET := Vector3(0.0, -0.035, 0.04)
const SLIDE_OFFSET := Vector3(0.0, -0.08, 0.08)
const TIRED_OFFSET := Vector3(0.0, -0.035, 0.0)

var bob_time := 0.0
var idle_time := 0.0
var landing_shock := 0.0
var _look_lag := Vector2.ZERO
var _equipped := false

var _running := false
var _crouching := false
var _sliding := false
var _moving := false
var _sprint_locked := false
var _h_speed := 0.0

@onready var flashlight_model: Node3D = $FlashlightModel

func _ready():
	position = BASE_POSITION
	rotation = BASE_ROTATION
	_set_model_visible(false)

func update_state(running: bool, crouching: bool, sliding: bool, moving: bool, sprint_locked: bool, h_speed: float):
	_running = running
	_crouching = crouching
	_sliding = sliding
	_moving = moving
	_sprint_locked = sprint_locked
	_h_speed = h_speed

func trigger_landing(fall_speed: float):
	if fall_speed > 2.5:
		landing_shock = clamp(fall_speed * 0.018, 0.04, 0.16)

func show_flashlight(is_visible: bool):
	_equipped = is_visible
	_set_model_visible(_equipped)

func set_light_enabled(_is_enabled: bool):
	# The held model stays visible after pickup; only the SpotLight toggles.
	pass

func add_look_impulse(relative: Vector2):
	_look_lag += Vector2(relative.x, relative.y) * 0.0014
	_look_lag = _look_lag.clamp(Vector2(-0.18, -0.14), Vector2(0.18, 0.14))

func _process(delta: float):
	idle_time += delta
	_set_model_visible(_equipped)

	var bob_x = 0.0
	var bob_y = 0.0
	var bob_z = 0.0

	if _sliding:
		bob_time = move_toward(bob_time, 0.0, delta * 7.0)
	elif _running and _moving:
		bob_time += delta * 18.5
		bob_x = sin(bob_time) * 0.018
		bob_y = -abs(sin(bob_time * 0.5)) * 0.016
		bob_z = sin(bob_time * 0.5) * 0.014
	elif _moving:
		bob_time += delta * 12.0
		bob_x = sin(bob_time) * 0.010
		bob_y = -abs(sin(bob_time * 0.5)) * 0.009
	else:
		bob_time = move_toward(bob_time, 0.0, delta * 5.0)

	landing_shock = lerp(landing_shock, 0.0, delta * 9.0)
	_look_lag = _look_lag.lerp(Vector2.ZERO, delta * 7.5)

	var state_offset = Vector3.ZERO
	if _sliding:
		state_offset = SLIDE_OFFSET
	elif _crouching:
		state_offset = CROUCH_OFFSET
	elif _sprint_locked:
		state_offset = TIRED_OFFSET

	var breathe = sin(idle_time * 1.1) * 0.003
	var lag_offset = Vector3(-_look_lag.x * 0.42, _look_lag.y * 0.30, 0.0)
	var target_position = BASE_POSITION + state_offset + Vector3(bob_x, bob_y + breathe - landing_shock, bob_z) + lag_offset
	var target_rotation = BASE_ROTATION + Vector3(
		-_look_lag.y * 0.55 - landing_shock * 0.32,
		-_look_lag.x * 0.45,
		-bob_x * 1.15 - _look_lag.x * 0.35
	)

	position = position.lerp(target_position, delta * 15.0)
	rotation = rotation.lerp(target_rotation, delta * 12.0)

func _set_model_visible(is_visible: bool):
	if flashlight_model:
		flashlight_model.visible = is_visible
