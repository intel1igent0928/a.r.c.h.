extends CharacterBody3D

const WALK_SPEED = 4.1
const RUN_SPEED = 7.4
const CROUCH_SPEED = 2.35
const EXHAUSTED_SPEED = 2.8
const SLIDE_START_SPEED = 8.6
const SLIDE_END_SPEED = 2.7
const SLIDE_DURATION = 0.72
const SLIDE_STAMINA_COST = 12.0
const ACCELERATION = 12.0
const AIR_ACCELERATION = 4.0
const DECELERATION = 34.0
const GRAVITY = 24.0
const STEP_UP_HEIGHT = 0.30
const STEP_CHECK_DISTANCE = 0.32
const STEP_COOLDOWN_TIME = 0.12

const JUMP_VELOCITY = 6.0
const RUN_JUMP_VELOCITY = 7.35
const RUN_JUMP_STAMINA_COST = 13.0

const MAX_STAMINA = 100.0
const RUN_DRAIN = 34.0
const RECOVERY_RATE = 12.0
const RECOVERY_DELAY = 0.5
const EMPTY_RECOVERY_DELAY = 0.5
const SPRINT_LOCK_UNTIL = 24.0

const NORMAL_FOV = 76.0
const RUN_FOV = 86.0
const TIRED_FOV = 72.0
const CROUCH_FOV = 73.0
const FOV_SPEED = 6.0

const STAND_CAMERA_Y = 0.72
const CROUCH_CAMERA_Y = 0.32
const SLIDE_CAMERA_Y = 0.18
const STAND_BODY_HEIGHT = 1.75
const CROUCH_BODY_HEIGHT = 1.08

const BOB_WALK_SPEED = 12.8
const BOB_RUN_SPEED = 18.6
const BOB_CROUCH_SPEED = 5.2
const BOB_WALK_AMOUNT = 0.035
const BOB_RUN_AMOUNT = 0.058
const BOB_CROUCH_AMOUNT = 0.025
const FOOTSTEP_SAMPLE_RATE = 22050

@export var mouse_sensitivity = 0.0024

var stamina = MAX_STAMINA
var recovery_timer = 0.0
var sprint_locked = false
var shift_held_empty = false
var camera_pitch = 0.0
var bob_time = 0.0
var footstep_kick = 0.0
var landing_kick = 0.0
var landing_roll = 0.0
var sprint_jump_landing_bonus = 1.0
var step_camera_offset = 0.0
var step_cooldown = 0.0
var slide_timer = 0.0
var slide_direction = Vector3.ZERO
var flashlight_on = false
var has_flashlight = false
var third_person_enabled = false
var footstep_impulse = 0.0
var last_step_hit = 0.0
var footstep_phase = 0.0
var footstep_playback: AudioStreamGeneratorPlayback

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var third_person_pivot: Node3D = $ThirdPersonPivot
@onready var third_person_camera: Camera3D = $ThirdPersonPivot/ThirdPersonCamera
@onready var flashlight: SpotLight3D = $CameraPivot/Camera3D/Flashlight
@onready var player_hands = get_node_or_null("CameraPivot/Camera3D/PlayerHands")
@onready var mixamo_body = get_node_or_null("MixamoPlayerBody")
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var stamina_bar: ProgressBar = get_node_or_null("/root/Main/CanvasLayer/StaminaBar")
@onready var state_label: Label = get_node_or_null("/root/Main/CanvasLayer/StateLabel")
@onready var wind_left: ColorRect = get_node_or_null("/root/Main/CanvasLayer/WindLeft")
@onready var wind_right: ColorRect = get_node_or_null("/root/Main/CanvasLayer/WindRight")

func _ready():
	_ensure_default_input()
	if flashlight:
		flashlight.visible = false
	_build_footstep_audio()
	_set_camera_mode(false)
	_update_ui("Walk")

func _input(event):
	if not _can_accept_play_input():
		return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pitch = clamp(camera_pitch - event.relative.y * mouse_sensitivity, deg_to_rad(-84.0), deg_to_rad(84.0))
		camera_pivot.rotation.x = camera_pitch
		third_person_pivot.rotation.x = camera_pitch

	if event.is_action_pressed("toggle_mouse"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event.is_action_pressed("toggle_flashlight"):
		if has_flashlight:
			flashlight_on = not flashlight_on
			if flashlight:
				flashlight.visible = flashlight_on

	if event.is_action_pressed("toggle_camera"):
		_set_camera_mode(not third_person_enabled)

func pickup_flashlight():
	has_flashlight = true
	flashlight_on = true
	if flashlight:
		flashlight.visible = true
	if player_hands and player_hands.has_method("show_flashlight"):
		player_hands.show_flashlight(true)

func _physics_process(delta):
	if not _can_accept_play_input():
		velocity = Vector3.ZERO
		return

	step_cooldown = max(step_cooldown - delta, 0.0)
	var was_on_floor = is_on_floor()
	var previous_y_velocity = velocity.y
	var input_vector = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wish_direction = (global_transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
	var is_trying_to_move = wish_direction.length() > 0.01
	var wants_to_run = Input.is_action_pressed("run")
	var wants_to_crouch = Input.is_action_pressed("crouch")
	var wants_to_start_slide = Input.is_action_just_pressed("crouch")
	var wants_to_jump = Input.is_action_just_pressed("jump")
	_try_start_slide(wants_to_start_slide, wants_to_run, is_trying_to_move, wish_direction)
	var is_sliding = slide_timer > 0.0
	var can_run = wants_to_run and is_trying_to_move and not wants_to_crouch and not is_sliding and not sprint_locked and stamina > 0.0
	var is_running = can_run
	var is_crouching = wants_to_crouch and not is_sliding
	var target_speed = _get_target_speed(is_running, is_crouching, is_sliding)

	_update_stamina(delta, is_running, wants_to_run)
	_update_crouch(delta, is_crouching, is_sliding)
	_update_velocity(delta, wish_direction, target_speed, is_trying_to_move, is_sliding)
	_try_jump(wants_to_jump, wants_to_run, is_crouching or is_sliding)
	_try_step_up(wish_direction, is_trying_to_move, is_sliding)
	move_and_slide()
	_update_slide(delta)

	if not was_on_floor and is_on_floor():
		_start_landing(abs(previous_y_velocity))

	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	_update_camera_motion(delta, horizontal_speed, is_running, is_crouching, is_sliding, is_trying_to_move)
	_update_speed_effect(delta, is_running or is_sliding)
	_update_footstep_audio()
	_update_ui(_get_state_text(is_running, is_crouching, is_sliding, is_trying_to_move))
	if player_hands and player_hands.has_method("update_state"):
		player_hands.update_state(is_running, is_crouching, is_sliding, is_trying_to_move, sprint_locked, horizontal_speed)
	if mixamo_body and mixamo_body.has_method("update_locomotion"):
		mixamo_body.update_locomotion(is_running, is_crouching, is_sliding, is_trying_to_move, is_on_floor(), velocity.y)

func _get_target_speed(is_running: bool, wants_to_crouch: bool, is_sliding: bool) -> float:
	if is_sliding:
		var slide_progress = 1.0 - clamp(slide_timer / SLIDE_DURATION, 0.0, 1.0)
		return lerp(SLIDE_START_SPEED, SLIDE_END_SPEED, slide_progress)
	if wants_to_crouch:
		return CROUCH_SPEED
	if sprint_locked:
		return EXHAUSTED_SPEED
	if is_running:
		return RUN_SPEED
	return WALK_SPEED

func _update_velocity(delta: float, wish_direction: Vector3, target_speed: float, is_trying_to_move: bool, is_sliding: bool):
	if is_sliding:
		var steer = wish_direction * target_speed * 0.25
		var target_velocity = slide_direction * target_speed + steer
		velocity.x = move_toward(velocity.x, target_velocity.x, ACCELERATION * 0.65 * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, ACCELERATION * 0.65 * delta)
		if is_on_floor():
			velocity.y = 0.0
		else:
			velocity.y -= GRAVITY * delta
		return

	var target_velocity = wish_direction * target_speed
	var accel = ACCELERATION if is_on_floor() else AIR_ACCELERATION

	if is_trying_to_move:
		velocity.x = move_toward(velocity.x, target_velocity.x, accel * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, DECELERATION * delta)
		velocity.z = move_toward(velocity.z, 0.0, DECELERATION * delta)
		if abs(velocity.x) < 0.08:
			velocity.x = 0.0
		if abs(velocity.z) < 0.08:
			velocity.z = 0.0

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta

func _try_jump(wants_to_jump: bool, wants_to_run: bool, wants_to_crouch: bool):
	if not wants_to_jump or not is_on_floor() or wants_to_crouch:
		return

	var sprint_jump = wants_to_run and not sprint_locked and stamina >= RUN_JUMP_STAMINA_COST
	if sprint_jump:
		velocity.y = RUN_JUMP_VELOCITY
		_spend_stamina(RUN_JUMP_STAMINA_COST)
		sprint_jump_landing_bonus = 1.45
	else:
		velocity.y = JUMP_VELOCITY
		sprint_jump_landing_bonus = 1.0

	landing_kick = max(landing_kick, 0.035)

func _try_step_up(wish_direction: Vector3, is_trying_to_move: bool, is_sliding: bool):
	if not is_on_floor() or not is_trying_to_move or is_sliding:
		return
	if step_cooldown > 0.0:
		return
	if wish_direction.length() < 0.01:
		return

	var forward_motion = wish_direction.normalized() * STEP_CHECK_DISTANCE
	if not test_move(global_transform, forward_motion):
		return

	var current_ground_y = _get_ground_y_at(global_position)
	var target_ground_y = _get_ground_y_at(global_position + forward_motion)
	var step_height = target_ground_y - current_ground_y
	if step_height < 0.06 or step_height > STEP_UP_HEIGHT:
		return

	var raised_transform = global_transform
	raised_transform.origin.y += step_height + 0.04
	if test_move(raised_transform, forward_motion):
		return

	global_position.y += step_height
	step_camera_offset -= step_height
	step_cooldown = STEP_COOLDOWN_TIME

func _get_ground_y_at(point: Vector3) -> float:
	var from = point + Vector3.UP * 0.75
	var to = point + Vector3.DOWN * 1.25
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return -1000000.0
	return hit["position"].y

func _update_stamina(delta: float, is_running: bool, wants_to_run: bool):
	if is_running:
		stamina = max(stamina - RUN_DRAIN * delta, 0.0)
		recovery_timer = EMPTY_RECOVERY_DELAY if stamina <= 0.0 else RECOVERY_DELAY
		if stamina <= 0.0:
			sprint_locked = true
			shift_held_empty = wants_to_run
		return

	if wants_to_run and sprint_locked and stamina <= 0.0:
		shift_held_empty = true
		return

	if not wants_to_run and shift_held_empty:
		shift_held_empty = false
		recovery_timer = EMPTY_RECOVERY_DELAY

	if recovery_timer > 0.0:
		recovery_timer = max(recovery_timer - delta, 0.0)
		return

	stamina = min(stamina + RECOVERY_RATE * delta, MAX_STAMINA)
	if sprint_locked and stamina >= SPRINT_LOCK_UNTIL:
		sprint_locked = false

func _spend_stamina(amount: float):
	stamina = max(stamina - amount, 0.0)
	recovery_timer = RECOVERY_DELAY
	if stamina <= 0.0:
		sprint_locked = true
		shift_held_empty = Input.is_action_pressed("run")

func _try_start_slide(wants_to_start_slide: bool, wants_to_run: bool, is_trying_to_move: bool, wish_direction: Vector3):
	if not wants_to_start_slide or not wants_to_run or not is_trying_to_move or not is_on_floor():
		return
	if sprint_locked or stamina < SLIDE_STAMINA_COST:
		return

	slide_timer = SLIDE_DURATION
	slide_direction = wish_direction.normalized()
	velocity.x = slide_direction.x * SLIDE_START_SPEED
	velocity.z = slide_direction.z * SLIDE_START_SPEED
	_spend_stamina(SLIDE_STAMINA_COST)
	landing_kick = max(landing_kick, 0.08)

func _update_slide(delta: float):
	if slide_timer <= 0.0:
		return

	slide_timer = max(slide_timer - delta, 0.0)
	if slide_timer <= 0.0:
		slide_direction = Vector3.ZERO

func _update_crouch(delta: float, wants_to_crouch: bool, is_sliding: bool):
	var target_y = STAND_CAMERA_Y
	if is_sliding:
		target_y = SLIDE_CAMERA_Y
	elif wants_to_crouch:
		target_y = CROUCH_CAMERA_Y
	camera_pivot.position.y = lerp(camera_pivot.position.y, target_y, delta * 12.0)

	var capsule = collision_shape.shape as CapsuleShape3D
	if capsule:
		var target_height = CROUCH_BODY_HEIGHT if wants_to_crouch or is_sliding else STAND_BODY_HEIGHT
		capsule.height = lerp(capsule.height, target_height, delta * 14.0)

func _update_camera_motion(delta: float, horizontal_speed: float, is_running: bool, wants_to_crouch: bool, is_sliding: bool, is_trying_to_move: bool):
	var target_fov = NORMAL_FOV
	if is_sliding:
		target_fov = RUN_FOV + 2.0
	elif is_running:
		target_fov = RUN_FOV
	elif wants_to_crouch:
		target_fov = CROUCH_FOV
	elif sprint_locked:
		target_fov = TIRED_FOV
	camera.fov = lerp(camera.fov, target_fov, FOV_SPEED * delta)

	var bob_amount = BOB_WALK_AMOUNT
	var bob_speed = BOB_WALK_SPEED
	if is_running:
		bob_amount = BOB_RUN_AMOUNT
		bob_speed = BOB_RUN_SPEED
	elif wants_to_crouch:
		bob_amount = BOB_CROUCH_AMOUNT
		bob_speed = BOB_CROUCH_SPEED

	if is_sliding:
		bob_time = lerp(bob_time, 0.0, delta * 10.0)
		footstep_kick = lerp(footstep_kick, 0.0, delta * 18.0)
		last_step_hit = 0.0
	elif is_trying_to_move and is_on_floor() and horizontal_speed > 0.2:
		bob_time += delta * bob_speed
		var step_hit = pow(max(sin(bob_time * 2.0), 0.0), 8.0)
		if step_hit > 0.72 and last_step_hit <= 0.72:
			footstep_impulse = max(footstep_impulse, 0.95 if is_running else 0.62)
		footstep_kick = lerp(footstep_kick, step_hit * bob_amount * 1.35, delta * 34.0)
		last_step_hit = step_hit
	else:
		bob_time = lerp(bob_time, 0.0, delta * 8.0)
		footstep_kick = lerp(footstep_kick, 0.0, delta * 12.0)
		last_step_hit = 0.0

	landing_kick = lerp(landing_kick, 0.0, delta * 7.0)
	landing_roll = lerp(landing_roll, 0.0, delta * 7.0)
	step_camera_offset = lerp(step_camera_offset, 0.0, delta * 10.0)

	var step_lift = pow(max(-sin(bob_time * 2.0), 0.0), 5.0) * bob_amount * 0.55
	var side_sway = sin(bob_time) * bob_amount * 0.08
	var forward_dip = -footstep_kick - landing_kick
	var tired_drop = 0.04 if sprint_locked else 0.0
	var slide_drop = -0.04 if is_sliding else 0.0
	camera.position = camera.position.lerp(Vector3(side_sway, step_lift + forward_dip - tired_drop + slide_drop + step_camera_offset, 0.0), delta * 24.0)
	camera.rotation.z = lerp(camera.rotation.z, -side_sway * 1.35 + landing_roll, delta * 18.0)

func _start_landing(fall_speed: float):
	if fall_speed < 3.0:
		return

	var impact = fall_speed * 0.032 * sprint_jump_landing_bonus
	landing_kick = clamp(impact, 0.11, 0.42)
	landing_roll = randf_range(-0.04, 0.04) * sprint_jump_landing_bonus
	sprint_jump_landing_bonus = 1.0
	if player_hands and player_hands.has_method("trigger_landing"):
		player_hands.trigger_landing(fall_speed)
	if mixamo_body and mixamo_body.has_method("trigger_land"):
		mixamo_body.trigger_land(fall_speed)

func _update_speed_effect(delta: float, is_running: bool):
	var target_alpha = 0.34 if is_running else 0.0
	for wind in [wind_left, wind_right]:
		if wind:
			wind.modulate.a = lerp(wind.modulate.a, target_alpha, delta * 7.0)

func _build_footstep_audio():
	var audio_player = AudioStreamPlayer.new()
	audio_player.name = "ProceduralFootsteps"
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = FOOTSTEP_SAMPLE_RATE
	stream.buffer_length = 0.18
	audio_player.stream = stream
	audio_player.volume_db = -14.0
	add_child(audio_player)
	audio_player.play()
	footstep_playback = audio_player.get_stream_playback() as AudioStreamGeneratorPlayback

func _update_footstep_audio():
	if not footstep_playback:
		return
	var frames = footstep_playback.get_frames_available()
	for i in range(frames):
		footstep_phase += 1.0 / float(FOOTSTEP_SAMPLE_RATE)
		var thump = sin(footstep_phase * TAU * 92.0) * footstep_impulse
		var grit = (randf() * 2.0 - 1.0) * footstep_impulse * 0.18
		var sample = (thump + grit) * 0.12
		footstep_impulse = max(footstep_impulse - 0.0045, 0.0)
		footstep_playback.push_frame(Vector2(sample, sample))

func _get_state_text(is_running: bool, wants_to_crouch: bool, is_sliding: bool, is_trying_to_move: bool) -> String:
	if is_sliding:
		return "Slide"
	if wants_to_crouch:
		return "SneakWalk" if is_trying_to_move else "Crouch"
	if sprint_locked:
		return "Tired"
	if is_running:
		return "Run"
	if is_trying_to_move:
		return "Walk"
	return "Idle"

func _update_ui(state_text: String):
	if stamina_bar:
		stamina_bar.value = stamina

	if state_label:
		var lock_text = ""
		if shift_held_empty:
			lock_text = " | release Shift"
		elif recovery_timer > 0.0:
			lock_text = " | recovery"
		state_label.text = "%s | stamina %d%s" % [state_text, int(stamina), lock_text]

func _set_camera_mode(use_third_person: bool):
	third_person_enabled = use_third_person

	if camera:
		camera.current = not third_person_enabled
	if third_person_camera:
		third_person_camera.current = third_person_enabled

	if player_hands:
		player_hands.visible = not third_person_enabled

	if mixamo_body and mixamo_body.has_method("set_first_person_mode"):
		mixamo_body.set_first_person_mode(not third_person_enabled)

func _ensure_default_input():
	_ensure_key_action("move_forward", KEY_W)
	_ensure_key_action("move_back", KEY_S)
	_ensure_key_action("move_left", KEY_A)
	_ensure_key_action("move_right", KEY_D)
	_ensure_key_action("run", KEY_SHIFT)
	_ensure_key_action("jump", KEY_SPACE)
	_ensure_key_action("crouch", KEY_CTRL)
	_ensure_key_action("toggle_camera", KEY_V)
	_ensure_key_action("toggle_flashlight", KEY_F)
	_ensure_key_action("toggle_mouse", KEY_TAB)

func _ensure_key_action(action_name: String, keycode: Key):
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.physical_keycode == keycode:
			return

	var key_event = InputEventKey.new()
	key_event.physical_keycode = keycode
	key_event.keycode = keycode
	InputMap.action_add_event(action_name, key_event)

func _can_accept_play_input() -> bool:
	var manager = get_tree().root.find_child("GameManager", true, false)
	if manager and manager.has_method("is_playing"):
		return manager.is_playing()
	return true
