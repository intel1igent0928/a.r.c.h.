extends CharacterBody3D

enum FollowStyle { CLOSE, CAUTIOUS, STEADY, SPRINTER }

const GRAVITY = 24.0
const TURN_SPEED = 9.0

@export var player_path: NodePath
@export var maze_builder_path: NodePath
@export_file("*.gltf", "*.glb", "*.tscn") var character_model_path := ""
@export var character_height := 1.65
@export var model_yaw_degrees := 0.0
@export var follow_style := FollowStyle.CLOSE
@export var follow_distance := 3.0
@export var side_offset := 0.0
@export var move_speed := 4.4
@export var sprint_speed := 6.1
@export var repath_interval := 0.32
@export var teleport_distance := 38.0
@export var bob_strength := 0.035
@export var floor_clearance := 0.03
@export var separation_radius := 1.85
@export var separation_force := 2.6

var path: Array[Vector3] = []
var path_index := 0
var _player: Node3D
var _maze_builder: Node
var _body_root: Node3D
var _imported_model: Node3D
var _animation_player: AnimationPlayer
var _current_animation := ""
var _repath_timer := 0.0
var _pulse := 0.0
var _spawned_near_player := false

func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("followers")
	_player = get_node_or_null(player_path) as Node3D
	_maze_builder = get_node_or_null(maze_builder_path)
	_build_character()
	call_deferred("_spawn_near_player")

func _physics_process(delta: float):
	if not _player or not _maze_builder:
		return

	_pulse += delta
	_repath_timer = max(_repath_timer - delta, 0.0)
	if not _spawned_near_player:
		_spawn_near_player()

	var target = _get_follow_target()
	if global_position.distance_to(_player.global_position) > teleport_distance:
		global_position = target
		path.clear()
		path_index = 0

	if _repath_timer <= 0.0:
		_repath_to(target)
		_repath_timer = repath_interval

	_follow_path(delta, target)
	_update_visuals(delta)

func _spawn_near_player():
	if not _player:
		return
	global_position = _get_follow_target()
	_spawned_near_player = true

func _get_follow_target() -> Vector3:
	var forward = -_player.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized() if forward.length() > 0.01 else Vector3.FORWARD
	var right = _player.global_transform.basis.x
	right.y = 0.0
	right = right.normalized() if right.length() > 0.01 else Vector3.RIGHT

	var distance = follow_distance
	var lateral = side_offset
	match follow_style:
		FollowStyle.CAUTIOUS:
			distance = follow_distance + 1.8
			lateral += sin(_pulse * 0.9) * 1.4
		FollowStyle.STEADY:
			distance = follow_distance + 0.7
			lateral += sin(_pulse * 0.55 + side_offset) * 0.35
		FollowStyle.SPRINTER:
			distance = follow_distance if _player.global_position.distance_to(global_position) < 10.0 else follow_distance * 0.6

	var target = _player.global_position - forward * distance + right * lateral
	target.y = 0.05
	if _maze_builder and _maze_builder.has_method("is_world_walkable") and _maze_builder.is_world_walkable(target):
		return target
	if _maze_builder and _maze_builder.has_method("get_nearest_walkable_world"):
		target = _maze_builder.get_nearest_walkable_world(target, 0.05)
	return target

func _repath_to(target: Vector3):
	if _maze_builder.has_method("find_path_world"):
		path = _maze_builder.find_path_world(global_position, target)
		if path.is_empty():
			path = [target]
	else:
		path = [target]
	path_index = 0

func _follow_path(delta: float, target: Vector3):
	var desired = target
	if not path.is_empty() and path_index < path.size():
		desired = path[path_index]
		var flat_to_waypoint = Vector3(desired.x - global_position.x, 0.0, desired.z - global_position.z)
		if flat_to_waypoint.length() < 0.45 and path_index < path.size() - 1:
			path_index += 1
			desired = path[path_index]

	var flat = Vector3(desired.x - global_position.x, 0.0, desired.z - global_position.z)
	var distance_to_player = global_position.distance_to(_player.global_position)
	var stop_distance = max(1.0, follow_distance * 0.45)
	if flat.length() < stop_distance and distance_to_player <= follow_distance + 1.0:
		velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)
		_play_animation("Idle")
	else:
		var direction = flat.normalized() if flat.length() > 0.05 else Vector3.ZERO
		var speed = sprint_speed if distance_to_player > follow_distance + 5.0 or follow_style == FollowStyle.SPRINTER else move_speed
		velocity.x = move_toward(velocity.x, direction.x * speed, 22.0 * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, 22.0 * delta)
		if direction.length() > 0.01:
			var target_yaw = atan2(-direction.x, -direction.z)
			rotation.y = lerp_angle(rotation.y, target_yaw, TURN_SPEED * delta)
		_play_animation("Run" if speed > move_speed + 0.2 else "Walk")

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	_apply_separation(delta)
	move_and_slide()

func _apply_separation(delta: float):
	var push = Vector3.ZERO
	for node in get_tree().get_nodes_in_group("followers"):
		if node == self:
			continue
		var other = node as Node3D
		if not other:
			continue
		var flat = Vector3(global_position.x - other.global_position.x, 0.0, global_position.z - other.global_position.z)
		var distance = flat.length()
		if distance <= 0.001 or distance >= separation_radius:
			continue
		push += flat.normalized() * (1.0 - distance / separation_radius)
	if push.length() <= 0.001:
		return
	velocity.x += push.x * separation_force
	velocity.z += push.z * separation_force

func _update_visuals(delta: float):
	if not _body_root:
		return
	var speed = Vector2(velocity.x, velocity.z).length()
	var speed_ratio = clamp(speed / sprint_speed, 0.0, 1.0)
	var bob = (0.5 + sin(_pulse * lerp(4.5, 9.5, speed_ratio)) * 0.5) * bob_strength * speed_ratio
	_body_root.position.y = lerp(_body_root.position.y, bob, delta * 8.0)
	_body_root.rotation.z = lerp(_body_root.rotation.z, sin(_pulse * 5.0) * 0.025 * clamp(speed / move_speed, 0.0, 1.0), delta * 7.0)
	_ground_imported_model()

func _build_character():
	_body_root = Node3D.new()
	_body_root.name = "CharacterModel"
	add_child(_body_root)

	var packed_scene = load(character_model_path) as PackedScene
	if packed_scene:
		var model = packed_scene.instantiate() as Node3D
		if model:
			model.name = "ImportedFollowerModel"
			model.rotation_degrees.y = model_yaw_degrees
			_body_root.add_child(model)
			_imported_model = model
			_normalize_imported_model(model)
			_prepare_visuals(model)
			_animation_player = _find_animation_player(model)
			_configure_animations()
			_play_animation("Idle")
			return

	var fallback = MeshInstance3D.new()
	fallback.name = "FallbackFollower"
	var mesh = CapsuleMesh.new()
	mesh.radius = 0.35
	mesh.height = character_height
	fallback.mesh = mesh
	fallback.position.y = character_height * 0.5
	_body_root.add_child(fallback)

func _normalize_imported_model(model: Node3D):
	var bounds = _get_visual_bounds(model)
	if bounds.size.y <= 0.01:
		return
	var scale_factor = character_height / bounds.size.y
	model.scale *= scale_factor
	bounds = _get_visual_bounds(model)
	model.global_position.y += (global_position.y + floor_clearance) - bounds.position.y
	_ground_imported_model()

func _ground_imported_model():
	if not _imported_model or not _imported_model.is_inside_tree():
		return
	var bounds = _get_visual_bounds(_imported_model)
	if bounds.size.y <= 0.01:
		return
	_imported_model.global_position.y += (global_position.y + floor_clearance) - bounds.position.y

func _get_visual_bounds(root: Node3D) -> AABB:
	var bounds := AABB()
	var has_bounds := false
	for child in root.find_children("*", "GeometryInstance3D", true, false):
		var visual = child as GeometryInstance3D
		if not visual:
			continue
		var global_aabb = _transform_aabb(visual.global_transform, visual.get_aabb())
		bounds = bounds.merge(global_aabb) if has_bounds else global_aabb
		has_bounds = true
	return bounds

func _transform_aabb(transform: Transform3D, aabb: AABB) -> AABB:
	var corners = [
		aabb.position,
		aabb.position + Vector3(aabb.size.x, 0.0, 0.0),
		aabb.position + Vector3(0.0, aabb.size.y, 0.0),
		aabb.position + Vector3(0.0, 0.0, aabb.size.z),
		aabb.position + Vector3(aabb.size.x, aabb.size.y, 0.0),
		aabb.position + Vector3(aabb.size.x, 0.0, aabb.size.z),
		aabb.position + Vector3(0.0, aabb.size.y, aabb.size.z),
		aabb.position + aabb.size,
	]
	var min_point = transform * corners[0]
	var max_point = min_point
	for i in range(1, corners.size()):
		var point = transform * corners[i]
		min_point = min_point.min(point)
		max_point = max_point.max(point)
	return AABB(min_point, max_point - min_point)

func _prepare_visuals(root: Node3D):
	for child in root.find_children("*", "GeometryInstance3D", true, false):
		var geometry = child as GeometryInstance3D
		if geometry:
			geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found = _find_animation_player(child)
		if found:
			return found
	return null

func _configure_animations():
	if not _animation_player:
		return
	var animation_list = _animation_player.get_animation_list()
	for candidate in animation_list:
		var animation = _animation_player.get_animation(candidate)
		if animation:
			animation.loop_mode = Animation.LOOP_LINEAR

func _play_animation(anim_name: String):
	if not _animation_player:
		return
	var animation_name = _pick_animation(anim_name)
	if animation_name.is_empty() or animation_name == _current_animation:
		return
	_animation_player.play(animation_name, 0.16)
	_current_animation = animation_name

func _pick_animation(anim_name: String) -> String:
	if _animation_player.has_animation(anim_name):
		return anim_name
	var desired = anim_name.to_lower()
	var animation_list = _animation_player.get_animation_list()
	for candidate in _animation_player.get_animation_list():
		var lower = candidate.to_lower()
		if lower == desired or lower.contains(desired):
			return candidate
	if desired == "run":
		for candidate in animation_list:
			var lower = candidate.to_lower()
			if lower.contains("walk") or lower.contains("action") or lower.contains("run"):
				return candidate
	if desired == "walk":
		for candidate in animation_list:
			var lower = candidate.to_lower()
			if lower.contains("walk") or lower.contains("run") or lower.contains("action"):
				return candidate
	for candidate in animation_list:
		var lower = candidate.to_lower()
		if lower.contains("take") or lower.contains("action"):
			return candidate
	return animation_list[0] if not animation_list.is_empty() else ""
