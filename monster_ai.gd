extends CharacterBody3D

enum State { SLEEP, PATROL, INVESTIGATE, CHASE }

const PATROL_SPEED = 2.15
const CHASE_SPEED = 5.25
const TURN_SPEED = 7.0
const GRAVITY = 24.0
const DETECT_RANGE = 22.0
const CATCH_RANGE = 1.35
const LOSE_RANGE = 34.0

@export var maze_builder_path: NodePath
@export var player_path: NodePath

var state = State.SLEEP
var target_world = Vector3.ZERO
var path: Array[Vector3] = []
var path_index = 0
var _maze_builder: Node
var _player: Node3D
var _body_root: Node3D
var _pulse := 0.0
var _repath_timer := 0.0
var _growl_timer := 0.0

func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_maze_builder = get_node_or_null(maze_builder_path)
	_player = get_node_or_null(player_path) as Node3D
	_build_creature()
	set_active(false)

func set_active(enabled: bool):
	state = State.PATROL if enabled else State.SLEEP
	visible = enabled
	set_physics_process(enabled)
	if enabled:
		_choose_patrol_target()

func alert_to_player():
	if state == State.SLEEP:
		set_active(true)
	state = State.CHASE
	_repath_to_player()

func _physics_process(delta: float):
	if not _player or not _maze_builder:
		return

	_pulse += delta
	_repath_timer = max(_repath_timer - delta, 0.0)
	_growl_timer = max(_growl_timer - delta, 0.0)
	_update_state()
	_follow_path(delta)
	_update_visuals(delta)

func _update_state():
	var distance_to_player = global_position.distance_to(_player.global_position)
	if distance_to_player <= CATCH_RANGE:
		var manager = get_tree().root.find_child("GameManager", true, false)
		if manager and manager.has_method("kill_player"):
			manager.kill_player("It found you in the maze.")
		return

	if _can_see_player(distance_to_player):
		state = State.CHASE
		if _repath_timer <= 0.0:
			_repath_to_player()
			_repath_timer = 0.35
		_scare_player(0.012)
	elif state == State.CHASE and distance_to_player > LOSE_RANGE:
		state = State.PATROL
		_choose_patrol_target()
	elif state == State.PATROL and (path.is_empty() or path_index >= path.size()):
		_choose_patrol_target()

func _follow_path(delta: float):
	if path.is_empty() or path_index >= path.size():
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
	else:
		var target = path[path_index]
		var flat_to_target = Vector3(target.x - global_position.x, 0.0, target.z - global_position.z)
		if flat_to_target.length() < 0.35:
			path_index += 1
		else:
			var speed = CHASE_SPEED if state == State.CHASE else PATROL_SPEED
			var direction = flat_to_target.normalized()
			velocity.x = move_toward(velocity.x, direction.x * speed, 16.0 * delta)
			velocity.z = move_toward(velocity.z, direction.z * speed, 16.0 * delta)
			var target_yaw = atan2(-direction.x, -direction.z)
			rotation.y = lerp_angle(rotation.y, target_yaw, TURN_SPEED * delta)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func _repath_to_player():
	if not _maze_builder.has_method("find_path_world"):
		return
	path = _maze_builder.find_path_world(global_position, _player.global_position)
	path_index = 0

func _choose_patrol_target():
	if not _maze_builder or not _maze_builder.has_method("get_monster_patrol_point"):
		return
	var point = _maze_builder.get_monster_patrol_point(global_position)
	path = _maze_builder.find_path_world(global_position, point) if _maze_builder.has_method("find_path_world") else [point]
	path_index = 0

func _can_see_player(distance_to_player: float) -> bool:
	if distance_to_player > DETECT_RANGE:
		return false
	var from = global_position + Vector3.UP * 1.2
	var to = _player.global_position + Vector3.UP * 0.75
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == _player

func _scare_player(amount: float):
	var manager = get_tree().root.find_child("GameManager", true, false)
	if manager and manager.has_method("scare_pulse"):
		manager.scare_pulse(amount)

func _update_visuals(delta: float):
	if not _body_root:
		return
	var intensity = 1.0 if state == State.CHASE else 0.45
	_body_root.position.y = 0.08 + sin(_pulse * (8.0 if state == State.CHASE else 3.5)) * 0.08 * intensity
	_body_root.rotation.z = sin(_pulse * 5.0) * 0.04 * intensity

func _build_creature():
	_body_root = Node3D.new()
	_body_root.name = "CreatureModel"
	add_child(_body_root)

	var skin = StandardMaterial3D.new()
	skin.albedo_color = Color(0.42, 0.58, 0.30, 1.0)
	skin.roughness = 0.88
	var dark = StandardMaterial3D.new()
	dark.albedo_color = Color(0.05, 0.045, 0.04, 1.0)
	var glow = StandardMaterial3D.new()
	glow.albedo_color = Color(1.0, 0.78, 0.24, 1.0)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.60, 0.12, 1.0)
	glow.emission_energy_multiplier = 1.8

	_add_sphere("Body", Vector3(0, 0.95, 0), Vector3(0.72, 0.95, 0.58), skin)
	_add_sphere("Head", Vector3(0, 1.88, -0.06), Vector3(0.58, 0.48, 0.50), skin)
	_add_sphere("Mouth", Vector3(0, 1.72, -0.46), Vector3(0.32, 0.10, 0.08), dark)
	_add_sphere("EyeL", Vector3(-0.19, 1.96, -0.48), Vector3(0.10, 0.13, 0.06), glow)
	_add_sphere("EyeR", Vector3(0.19, 1.96, -0.48), Vector3(0.10, 0.13, 0.06), glow)
	_add_sphere("BackPack", Vector3(0, 1.03, 0.44), Vector3(0.44, 0.62, 0.22), dark)

	_add_limb("ArmL", Vector3(-0.62, 1.10, -0.06), Vector3(0.20, 0.82, 0.20), skin, -0.32)
	_add_limb("ArmR", Vector3(0.62, 1.10, -0.06), Vector3(0.20, 0.82, 0.20), skin, 0.32)
	_add_limb("LegL", Vector3(-0.28, 0.32, 0.02), Vector3(0.22, 0.62, 0.22), skin, 0.12)
	_add_limb("LegR", Vector3(0.28, 0.32, 0.02), Vector3(0.22, 0.62, 0.22), skin, -0.12)

	var light = OmniLight3D.new()
	light.name = "EyeGlow"
	light.position = Vector3(0, 1.9, -0.6)
	light.light_color = Color(1.0, 0.62, 0.18)
	light.light_energy = 1.0
	light.omni_range = 7.0
	add_child(light)

func _add_sphere(node_name: String, pos: Vector3, scale_value: Vector3, material: Material):
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh = SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 16
	mesh.rings = 8
	mesh.material = material
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.scale = scale_value
	_body_root.add_child(mesh_instance)

func _add_limb(node_name: String, pos: Vector3, scale_value: Vector3, material: Material, tilt: float):
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh = CapsuleMesh.new()
	mesh.radius = 0.28
	mesh.height = 1.1
	mesh.radial_segments = 10
	mesh.rings = 4
	mesh.material = material
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.rotation.z = tilt
	mesh_instance.scale = scale_value
	_body_root.add_child(mesh_instance)
