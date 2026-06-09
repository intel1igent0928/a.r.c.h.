extends CharacterBody3D

enum State { SLEEP, PATROL, INVESTIGATE, CHASE }

const TURN_SPEED = 7.0
const GRAVITY = 24.0
const MONSTER_SOUND_SAMPLE_RATE = 22050

@export var maze_builder_path: NodePath
@export var player_path: NodePath
@export_file("*.gltf", "*.glb", "*.tscn") var monster_model_path := "res://assets/monsters/stalker/monster.glb"
@export var imported_model_height := 2.35
@export var patrol_speed := 2.35
@export var investigate_speed := 3.2
@export var chase_speed := 6.15
@export var detect_range := 30.0
@export var hearing_range := 17.5
@export var near_sense_range := 8.5
@export var catch_range := 1.55
@export var lose_range := 42.0
@export var memory_time := 8.0
@export var scare_power := 1.0
@export var voice_pitch := 1.0
@export var hunt_interval_min := 5.0
@export var hunt_interval_max := 9.0
@export var hunt_accuracy := 0.62
@export var pack_alert_range := 70.0
@export var stuck_repath_time := 1.15
@export var direct_chase_range := 13.0
@export var floor_clearance := 0.08

var state = State.SLEEP
var target_world = Vector3.ZERO
var path: Array[Vector3] = []
var path_index = 0
var _maze_builder: Node
var _player: Node3D
var _body_root: Node3D
var _imported_model: Node3D
var _pulse := 0.0
var _repath_timer := 0.0
var _direct_chase_timer := 0.0
var _growl_timer := 0.0
var _memory_timer := 0.0
var _close_scare_cooldown := 0.0
var _hunt_timer := 0.0
var _pack_alert_cooldown := 0.0
var _stuck_timer := 0.0
var _last_step_position := Vector3.ZERO
var _last_known_player_position := Vector3.ZERO
var _animation_player: AnimationPlayer
var _current_animation := ""
var _imported_model_active := false
var _monster_audio_player: AudioStreamPlayer3D
var _monster_audio_playback: AudioStreamGeneratorPlayback
var _monster_audio_phase := 0.0
var _monster_audio_pulse := 0.0

func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("monsters")
	_maze_builder = get_node_or_null(maze_builder_path)
	_player = get_node_or_null(player_path) as Node3D
	_build_creature()
	_build_monster_audio()
	_reset_hunt_timer()
	set_active(false)

func set_active(enabled: bool):
	state = State.PATROL if enabled else State.SLEEP
	visible = enabled
	set_physics_process(enabled)
	if enabled:
		_last_step_position = global_position
		_reset_hunt_timer()
		_choose_patrol_target()

func alert_to_player():
	if state == State.SLEEP:
		set_active(true)
	state = State.CHASE
	_broadcast_player_spotted()
	_repath_to_player()

func receive_pack_alert(world_position: Vector3):
	if state == State.SLEEP:
		set_active(true)
	if state != State.CHASE:
		state = State.INVESTIGATE
		_last_known_player_position = world_position
		_memory_timer = memory_time * 0.75
		_repath_to_position(world_position)

func _physics_process(delta: float):
	if not _player or not _maze_builder:
		return

	_pulse += delta
	_repath_timer = max(_repath_timer - delta, 0.0)
	_direct_chase_timer = max(_direct_chase_timer - delta, 0.0)
	_growl_timer = max(_growl_timer - delta, 0.0)
	_memory_timer = max(_memory_timer - delta, 0.0)
	_close_scare_cooldown = max(_close_scare_cooldown - delta, 0.0)
	_hunt_timer = max(_hunt_timer - delta, 0.0)
	_pack_alert_cooldown = max(_pack_alert_cooldown - delta, 0.0)
	_update_state()
	_follow_path(delta)
	_update_visuals(delta)
	_update_monster_audio()

func _update_state():
	var distance_to_player = global_position.distance_to(_player.global_position)
	if distance_to_player <= catch_range:
		_play_animation("Attack")
		var manager = get_tree().root.find_child("GameManager", true, false)
		if manager and manager.has_method("kill_player"):
			manager.kill_player("It found you in the maze.")
		return

	var can_see = _can_see_player(distance_to_player)
	var can_hear = _can_hear_player(distance_to_player)
	if can_see or distance_to_player <= near_sense_range:
		_remember_player()
		state = State.CHASE
		if can_see and distance_to_player <= direct_chase_range:
			_direct_chase_timer = 0.45
		_broadcast_player_spotted()
		if _repath_timer <= 0.0:
			_repath_to_player()
			_repath_timer = 0.22
		_scare_player(0.02 * scare_power)
		if distance_to_player < 6.0 and _close_scare_cooldown <= 0.0:
			_scare_player(0.45 * scare_power)
			_close_scare_cooldown = 2.5
	elif can_hear:
		_remember_player()
		state = State.INVESTIGATE
		if _repath_timer <= 0.0:
			_repath_to_position(_last_known_player_position)
			_repath_timer = 0.45
		_scare_player(0.008 * scare_power)
	elif state == State.CHASE and distance_to_player <= lose_range and _memory_timer > 0.0:
		if _repath_timer <= 0.0:
			_repath_to_position(_last_known_player_position)
			_repath_timer = 0.55
		_scare_player(0.01 * scare_power)
	elif state == State.CHASE or state == State.INVESTIGATE:
		if _memory_timer > 0.0 and (path.is_empty() or path_index >= path.size()):
			_repath_to_position(_last_known_player_position)
		elif _memory_timer <= 0.0 or distance_to_player > lose_range:
			state = State.PATROL
			_choose_patrol_target()
	elif state == State.PATROL and (path.is_empty() or path_index >= path.size()):
		_choose_patrol_target()
	elif state == State.PATROL and _hunt_timer <= 0.0:
		_start_hunt()

	if visible and distance_to_player < 11.0:
		_scare_player(0.006 * scare_power)

func _follow_path(delta: float):
	var before_move = global_position
	var direct_flat = Vector3.ZERO
	if _player:
		direct_flat = Vector3(_player.global_position.x - global_position.x, 0.0, _player.global_position.z - global_position.z)

	if state == State.CHASE and _direct_chase_timer > 0.0 and direct_flat.length() > catch_range * 0.55:
		_move_towards_flat(_player.global_position, chase_speed, 28.0, delta, "Run")
	elif path.is_empty() or path_index >= path.size():
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
		_play_animation("Idle")
	else:
		while path_index < path.size() - 1:
			var waypoint = path[path_index]
			var flat_to_waypoint = Vector3(waypoint.x - global_position.x, 0.0, waypoint.z - global_position.z)
			if flat_to_waypoint.length() >= 0.62:
				break
			path_index += 1

		var target = path[path_index]
		var flat_to_target = Vector3(target.x - global_position.x, 0.0, target.z - global_position.z)
		if flat_to_target.length() < 0.35:
			path_index += 1
		else:
			var speed = _get_move_speed()
			_move_towards_flat(target, speed, 18.0, delta, "Run" if state == State.CHASE else "Walk")

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	_handle_stuck(delta, before_move)

func _move_towards_flat(world_position: Vector3, speed: float, acceleration: float, delta: float, animation_name: String):
	var flat = Vector3(world_position.x - global_position.x, 0.0, world_position.z - global_position.z)
	var direction = flat.normalized() if flat.length() > 0.05 else Vector3.ZERO
	velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	if direction.length() > 0.01:
		var target_yaw = atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, TURN_SPEED * delta)
	_play_animation(animation_name)

func _repath_to_player():
	_remember_player()
	_repath_to_position(_player.global_position)

func _repath_to_position(world_position: Vector3):
	if _maze_builder and _maze_builder.has_method("get_nearest_walkable_world"):
		world_position = _maze_builder.get_nearest_walkable_world(world_position, 0.05)
	if _maze_builder.has_method("find_path_world"):
		path = _maze_builder.find_path_world(global_position, world_position)
		if path.is_empty():
			path = [world_position]
	else:
		path = [world_position]
	path_index = 0

func _choose_patrol_target():
	if not _maze_builder or not _maze_builder.has_method("get_monster_patrol_point"):
		return
	var point = _maze_builder.get_monster_patrol_point(global_position)
	if _maze_builder.has_method("get_nearest_walkable_world"):
		point = _maze_builder.get_nearest_walkable_world(point, 0.05)
	path = _maze_builder.find_path_world(global_position, point) if _maze_builder.has_method("find_path_world") else [point]
	path_index = 0
	_reset_hunt_timer()

func _can_see_player(distance_to_player: float) -> bool:
	if distance_to_player > detect_range:
		return false
	var from = global_position + Vector3.UP * 1.2
	var to = _player.global_position + Vector3.UP * 0.75
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == _player

func _can_hear_player(distance_to_player: float) -> bool:
	if distance_to_player > hearing_range:
		return false
	var player_body = _player as CharacterBody3D
	var player_speed = 0.0
	if player_body:
		player_speed = Vector2(player_body.velocity.x, player_body.velocity.z).length()
	var loud_radius = lerp(near_sense_range, hearing_range, clamp(player_speed / 6.0, 0.0, 1.0))
	return distance_to_player <= loud_radius

func _remember_player():
	_last_known_player_position = _player.global_position
	_memory_timer = memory_time

func _start_hunt():
	if not _player:
		return
	state = State.INVESTIGATE
	var offset_radius = lerp(10.0, 2.5, clamp(hunt_accuracy, 0.0, 1.0))
	var offset = Vector3(randf_range(-offset_radius, offset_radius), 0.0, randf_range(-offset_radius, offset_radius))
	_last_known_player_position = _player.global_position + offset
	_memory_timer = memory_time * 0.65
	_repath_to_position(_last_known_player_position)
	_scare_player(0.16 * scare_power)
	_reset_hunt_timer()

func _reset_hunt_timer():
	_hunt_timer = randf_range(hunt_interval_min, hunt_interval_max)

func _broadcast_player_spotted():
	if _pack_alert_cooldown > 0.0:
		return
	_pack_alert_cooldown = 1.2
	for node in get_tree().get_nodes_in_group("monsters"):
		if node == self:
			continue
		var monster = node as Node3D
		if not monster:
			continue
		if global_position.distance_to(monster.global_position) > pack_alert_range:
			continue
		if node.has_method("receive_pack_alert"):
			node.receive_pack_alert(_player.global_position)

func _handle_stuck(delta: float, before_move: Vector3):
	var flat_velocity = Vector2(velocity.x, velocity.z).length()
	if flat_velocity < 0.35 or path.is_empty() or path_index >= path.size():
		_stuck_timer = 0.0
		_last_step_position = global_position
		return

	var moved = Vector2(global_position.x - before_move.x, global_position.z - before_move.z).length()
	if moved < 0.025:
		_stuck_timer += delta
	else:
		_stuck_timer = 0.0
		_last_step_position = global_position
		return

	if _stuck_timer < stuck_repath_time:
		return
	_stuck_timer = 0.0
	if path_index < path.size() - 1:
		path_index += 1
	elif state == State.CHASE and _player:
		_repath_to_player()
	elif state == State.INVESTIGATE:
		_repath_to_position(_last_known_player_position)
	else:
		_choose_patrol_target()

func _get_move_speed() -> float:
	if state == State.CHASE:
		return chase_speed
	if state == State.INVESTIGATE:
		return investigate_speed
	return patrol_speed

func _scare_player(amount: float):
	var manager = get_tree().root.find_child("GameManager", true, false)
	if manager and manager.has_method("scare_pulse"):
		manager.scare_pulse(amount)

func _update_visuals(delta: float):
	if not _body_root:
		return
	if _imported_model_active:
		var intensity = 1.0 if state == State.CHASE else 0.45
		_body_root.rotation.z = lerp(_body_root.rotation.z, sin(_pulse * 8.0) * 0.035 * intensity, delta * 6.0)
		_ground_imported_model()
		return
	var intensity = 1.0 if state == State.CHASE else 0.45
	_body_root.position.y = 0.08 + sin(_pulse * (8.0 if state == State.CHASE else 3.5)) * 0.08 * intensity
	_body_root.rotation.z = sin(_pulse * 5.0) * 0.04 * intensity

func _build_creature():
	if _try_build_imported_creature():
		return

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

func _try_build_imported_creature() -> bool:
	if monster_model_path.is_empty():
		return false
	var packed_scene = load(monster_model_path) as PackedScene
	if not packed_scene:
		return false

	_body_root = Node3D.new()
	_body_root.name = "CreatureModel"
	add_child(_body_root)

	var model = packed_scene.instantiate() as Node3D
	if not model:
		_body_root.queue_free()
		_body_root = null
		return false

	model.name = "ImportedMonsterModel"
	_body_root.add_child(model)
	_imported_model = model
	_normalize_imported_model(model)
	_prepare_imported_visuals(model)
	_animation_player = _find_animation_player(model)
	_configure_imported_animations()
	_imported_model_active = true
	_play_animation("Idle")

	var light = OmniLight3D.new()
	light.name = "MonsterWarningGlow"
	light.position = Vector3(0.0, 1.55, -0.45)
	light.light_color = Color(1.0, 0.22, 0.08)
	light.light_energy = 0.7
	light.omni_range = 6.0
	add_child(light)
	return true

func _normalize_imported_model(model: Node3D):
	var bounds = _get_visual_bounds(model)
	if bounds.size.y <= 0.01:
		return
	var scale_factor = imported_model_height / bounds.size.y
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
		var local_aabb = visual.get_aabb()
		var global_aabb = _transform_aabb(visual.global_transform, local_aabb)
		if has_bounds:
			bounds = bounds.merge(global_aabb)
		else:
			bounds = global_aabb
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

func _prepare_imported_visuals(root: Node3D):
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

func _configure_imported_animations():
	if not _animation_player:
		return
	var animation_list = _animation_player.get_animation_list()
	for candidate in _animation_player.get_animation_list():
		var animation = _animation_player.get_animation(candidate)
		if not animation:
			continue
		var lower = candidate.to_lower()
		if animation_list.size() == 1 or lower.contains("idle") or lower.contains("walk") or lower.contains("run") or lower.contains("take"):
			animation.loop_mode = Animation.LOOP_LINEAR
		else:
			animation.loop_mode = Animation.LOOP_NONE

func _play_animation(anim_name: String):
	if not _animation_player:
		return
	var animation_name = _pick_animation(anim_name)
	if animation_name.is_empty() or animation_name == _current_animation:
		return
	_animation_player.play(animation_name, 0.18)
	_current_animation = animation_name

func _pick_animation(anim_name: String) -> String:
	if _animation_player.has_animation(anim_name):
		return anim_name
	var desired = anim_name.to_lower()
	var animation_list = _animation_player.get_animation_list()
	for candidate in animation_list:
		var lower = candidate.to_lower()
		if lower == desired or lower.ends_with("/" + desired) or lower.contains(desired):
			return candidate
	if desired == "attack":
		for candidate in animation_list:
			var lower = candidate.to_lower()
			if lower.contains("attack") or lower.contains("hit") or lower.contains("punch"):
				return candidate
	if desired == "run":
		for candidate in animation_list:
			var lower = candidate.to_lower()
			if lower.contains("run") or lower.contains("walk") or lower.contains("take"):
				return candidate
	if desired == "walk":
		for candidate in animation_list:
			var lower = candidate.to_lower()
			if lower.contains("walk") or lower.contains("run") or lower.contains("take"):
				return candidate
	for candidate in animation_list:
		var lower = candidate.to_lower()
		if lower.contains("take") or lower.contains("action"):
			return candidate
	if not animation_list.is_empty():
		return animation_list[0]
	return ""

func _build_monster_audio():
	_monster_audio_player = AudioStreamPlayer3D.new()
	_monster_audio_player.name = "ProceduralMonsterVoice"
	_monster_audio_player.unit_size = 4.0
	_monster_audio_player.max_distance = 30.0
	_monster_audio_player.volume_db = -19.0
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = MONSTER_SOUND_SAMPLE_RATE
	stream.buffer_length = 0.35
	_monster_audio_player.stream = stream
	add_child(_monster_audio_player)
	_monster_audio_player.play()
	_monster_audio_playback = _monster_audio_player.get_stream_playback() as AudioStreamGeneratorPlayback

func _update_monster_audio():
	if not _monster_audio_playback:
		return
	var frames = _monster_audio_playback.get_frames_available()
	for i in range(frames):
		_monster_audio_playback.push_frame(_next_monster_audio_frame())

func _next_monster_audio_frame() -> Vector2:
	var intensity = 0.0
	if visible:
		intensity = 0.82 if state == State.CHASE else 0.34
	if _player and visible:
		var distance_pressure = clamp(1.0 - global_position.distance_to(_player.global_position) / 26.0, 0.0, 1.0)
		intensity = max(intensity, distance_pressure)

	_monster_audio_phase += TAU * lerp(34.0, 58.0, intensity) * voice_pitch / float(MONSTER_SOUND_SAMPLE_RATE)
	if _monster_audio_phase > TAU:
		_monster_audio_phase -= TAU
	_monster_audio_pulse += 1.0 / float(MONSTER_SOUND_SAMPLE_RATE)

	var throat = sin(_monster_audio_phase) * 0.16
	var rasp = (randf() * 2.0 - 1.0) * 0.055
	var pulse = sin(_monster_audio_pulse * TAU * lerp(1.6, 4.5, intensity)) * 0.08
	var sample = (throat + rasp + pulse) * intensity
	return Vector2(sample, sample)

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
