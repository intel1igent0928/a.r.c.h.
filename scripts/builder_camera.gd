extends Camera3D

@export var move_speed := 28.0
@export var fast_multiplier := 5.0
@export var mouse_sensitivity := 0.0025

var _yaw := 0.0
var _pitch := -0.25


func _ready() -> void:
	current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_update_rotation()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clamp(_pitch, deg_to_rad(-89.0), deg_to_rad(89.0))
		_update_rotation()


func _physics_process(delta: float) -> void:
	var direction := Vector3.ZERO
	var basis := global_transform.basis

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

	var speed := move_speed
	if Input.is_key_pressed(KEY_SHIFT):
		speed *= fast_multiplier

	global_position += direction.normalized() * speed * delta


func _update_rotation() -> void:
	rotation = Vector3(_pitch, _yaw, 0.0)
