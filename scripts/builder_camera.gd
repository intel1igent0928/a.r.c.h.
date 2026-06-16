extends CharacterBody3D

@export var fly_speed := 28.0
@export var fly_fast_multiplier := 5.0
@export var walk_speed := 6.0
@export var run_speed := 10.5
@export var jump_velocity := 5.2
@export var mouse_sensitivity := 0.0025
@export var eye_height := 1.65

@onready var camera: Camera3D = $Camera3D

var _yaw := 0.0
var _pitch := -0.25
var _movement_enabled := true
var _test_mode := false
var _gravity := ProjectSettings.get_setting("physics/3d/default_gravity") as float


func _ready() -> void:
	camera.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_update_rotation()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			release_mouse()
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			capture_mouse()
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clamp(_pitch, deg_to_rad(-89.0), deg_to_rad(89.0))
		_update_rotation()


func _physics_process(delta: float) -> void:
	if not _movement_enabled:
		return
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return

	if _test_mode:
		_walk_physics(delta)
	else:
		_fly_physics(delta)


func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _capture_mouse_deferred() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func set_movement_enabled(enabled: bool) -> void:
	_movement_enabled = enabled


func set_test_mode(enabled: bool) -> void:
	if _test_mode == enabled:
		return

	var view_position := camera.global_position
	_test_mode = enabled
	if _test_mode:
		global_position = view_position - Vector3.UP * eye_height
		camera.position = Vector3.UP * eye_height
		velocity = Vector3.ZERO
	else:
		global_position = view_position
		camera.position = Vector3.ZERO
		velocity = Vector3.ZERO


func get_view_camera() -> Camera3D:
	return camera


func _fly_physics(delta: float) -> void:
	var direction := Vector3.ZERO
	var basis := camera.global_transform.basis

	if Input.is_key_pressed(KEY_W):
		direction -= basis.z
	if Input.is_key_pressed(KEY_S):
		direction += basis.z
	if Input.is_key_pressed(KEY_A):
		direction -= basis.x
	if Input.is_key_pressed(KEY_D):
		direction += basis.x
	if Input.is_key_pressed(KEY_SPACE):
		direction += Vector3.UP
	if Input.is_key_pressed(KEY_CTRL):
		direction -= Vector3.UP

	if direction == Vector3.ZERO:
		return

	var speed := fly_speed
	if Input.is_key_pressed(KEY_SHIFT):
		speed *= fly_fast_multiplier

	global_position += direction.normalized() * speed * delta


func _walk_physics(delta: float) -> void:
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1.0
	input_dir = input_dir.normalized()

	var basis := global_transform.basis
	var forward := -basis.z
	var right := basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()

	var wish_dir := (right * input_dir.x + forward * -input_dir.y).normalized()
	var speed := run_speed if Input.is_key_pressed(KEY_SHIFT) else walk_speed
	velocity.x = wish_dir.x * speed
	velocity.z = wish_dir.z * speed

	if is_on_floor():
		if Input.is_key_pressed(KEY_SPACE):
			velocity.y = jump_velocity
	else:
		velocity.y -= _gravity * delta

	move_and_slide()


func _update_rotation() -> void:
	rotation.y = _yaw
	camera.rotation.x = _pitch
