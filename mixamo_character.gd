extends Node3D

const ANIMATION_SOURCES = {
	"Idle": "res://assets/mixamo/standing_idle.fbx",
	"Walk": "res://assets/mixamo/walking.fbx",
	"Run": "res://assets/mixamo/fast_run.fbx",
	"Jump": "res://assets/mixamo/jump.fbx",
	"Slide": "res://assets/mixamo/running_slide.fbx",
	"SneakWalk": "res://assets/mixamo/sneak_walk.fbx",
}

const LOOPING_ANIMATION_NAMES = ["Idle", "Walk", "Run", "SneakWalk"]
const JUMP_HOLD_TIME = 0.32
const SLIDE_HOLD_TIME = 0.72
const LAND_HOLD_TIME = 0.24

const SOCKET_BONES = {
	"RightHandSocket": ["mixamorig:RightHand", "RightHand", "mixamorig_RightHand"],
	"LeftHandSocket": ["mixamorig:LeftHand", "LeftHand", "mixamorig_LeftHand"],
	"HeadSocket": ["mixamorig:Head", "Head", "mixamorig_Head"],
}

var animation_player: AnimationPlayer
var animation_tree: AnimationTree
var state_playback: AnimationNodeStateMachinePlayback
var skeleton: Skeleton3D
var current_state = ""
var first_person_mode = true
var imported_animations = {}
var state_animations = {}
var state_lock_timer = 0.0
var was_on_ground = true
var base_model_position = Vector3.ZERO
var has_base_model_position = false
@export var start_as_shadow_only = true
@export var normalize_model_height = true
@export var target_model_height = 1.68
@export var foot_offset_from_origin = -0.95
@export var crouch_visual_lift = 0.58
@export var slide_visual_lift = 0.72

@onready var model_root: Node3D = $Model

func _ready():
	skeleton = _find_skeleton(model_root)
	animation_player = _find_animation_player(model_root)
	_setup_sockets()
	_setup_animation_tree()
	if normalize_model_height:
		call_deferred("_normalize_model_size")
	set_first_person_mode(start_as_shadow_only)

func _process(delta: float):
	state_lock_timer = max(state_lock_timer - delta, 0.0)
	_update_visual_lift(delta)

func update_locomotion(is_running: bool, is_crouching: bool, is_sliding: bool, is_moving: bool, is_on_ground: bool, y_velocity: float):
	if state_lock_timer > 0.0 and current_state in ["Jump", "Land", "Slide"]:
		was_on_ground = is_on_ground
		return

	if is_sliding:
		_travel_with_lock("Slide", SLIDE_HOLD_TIME)
	elif not is_on_ground:
		if was_on_ground and y_velocity > 0.0:
			_travel_with_lock("Jump", JUMP_HOLD_TIME)
		elif current_state != "Jump":
			_travel("Jump")
	elif is_crouching and not is_moving:
		_freeze_sneak_pose()
	elif is_crouching and is_moving:
		_travel("SneakWalk")
	elif is_running and is_moving:
		_travel("Run")
	elif is_moving:
		_travel("Walk")
	else:
		_travel("Idle")

	was_on_ground = is_on_ground

func trigger_land(fall_speed: float):
	if fall_speed < 3.0:
		return
	_travel_with_lock("Land", LAND_HOLD_TIME)

func set_first_person_mode(enabled: bool):
	first_person_mode = enabled
	_set_shadow_mode(model_root, enabled)

func _setup_animation_tree():
	if not animation_player:
		push_warning("MixamoCharacter: no AnimationPlayer found in imported character.")
		return

	_copy_animation_sources()

	animation_tree = AnimationTree.new()
	animation_tree.name = "AnimationTree"
	add_child(animation_tree)
	animation_tree.anim_player = animation_tree.get_path_to(animation_player)

	var state_machine = AnimationNodeStateMachine.new()
	animation_tree.tree_root = state_machine

	var idle_animation = _animation_for("Idle", ["Idle", "Standing Idle", "standing_idle", "mixamo.com", "Take 001"])
	var walk_animation = _animation_for("Walk", ["Walking", "walking"])
	var run_animation = _animation_for("Run", ["Fast Run", "fast_run"])
	var jump_animation = _animation_for("Jump", ["Jump", "jump"])
	var slide_animation = _animation_for("Slide", ["Running Slide", "running_slide"])
	var sneak_walk_animation = _animation_for("SneakWalk", ["Sneak Walk", "sneak_walk"])

	_set_animation_loop(idle_animation, true)
	_set_animation_loop(walk_animation, true)
	_set_animation_loop(run_animation, true)
	_set_animation_loop(slide_animation, false)
	_set_animation_loop(sneak_walk_animation, true)
	_set_animation_loop(jump_animation, false)

	state_animations = {
		"Idle": idle_animation,
		"Walk": walk_animation,
		"Run": run_animation,
		"Jump": jump_animation,
		"Fall": idle_animation,
		"Land": idle_animation,
		"Slide": slide_animation,
		"SneakWalk": sneak_walk_animation,
	}

	_add_state(state_machine, "Idle", idle_animation)
	_add_state(state_machine, "Walk", walk_animation)
	_add_state(state_machine, "Run", run_animation)
	_add_state(state_machine, "Jump", jump_animation)
	_add_state(state_machine, "Fall", idle_animation)
	_add_state(state_machine, "Land", idle_animation)
	_add_state(state_machine, "Slide", slide_animation)
	_add_state(state_machine, "SneakWalk", sneak_walk_animation)

	for from_state in ["Idle", "Walk", "Run", "Jump", "Fall", "Land", "Slide", "SneakWalk"]:
		for to_state in ["Idle", "Walk", "Run", "Jump", "Fall", "Land", "Slide", "SneakWalk"]:
			if from_state != to_state:
				state_machine.add_transition(from_state, to_state, AnimationNodeStateMachineTransition.new())

	animation_tree.active = true
	state_playback = animation_tree.get("parameters/playback")
	_travel("Idle")

func _add_state(state_machine: AnimationNodeStateMachine, state_name: String, animation_name: String):
	var node = AnimationNodeAnimation.new()
	node.animation = animation_name
	state_machine.add_node(state_name, node)

func _copy_animation_sources():
	for anim_name in ANIMATION_SOURCES.keys():
		var scene = load(ANIMATION_SOURCES[anim_name]) as PackedScene
		if not scene:
			push_warning("MixamoCharacter: could not load %s" % ANIMATION_SOURCES[anim_name])
			continue

		var instance = scene.instantiate()
		var source_player = _find_animation_player(instance)
		if source_player:
			_copy_first_animation(source_player, anim_name)
		instance.queue_free()

func _copy_first_animation(source_player: AnimationPlayer, target_name: String):
	var source_names = source_player.get_animation_list()
	if source_names.is_empty():
		push_warning("MixamoCharacter: %s has no animations." % target_name)
		return

	var source_animation = source_player.get_animation(source_names[0])
	if not source_animation:
		return

	var target_animation = source_animation.duplicate(true)
	target_animation.loop_mode = Animation.LOOP_LINEAR if target_name in LOOPING_ANIMATION_NAMES else Animation.LOOP_NONE
	_make_in_place(target_animation, target_name in ["Jump", "Slide", "SneakWalk"])

	var library = AnimationLibrary.new()
	library.add_animation(target_name, target_animation)
	var library_name = target_name.to_lower()
	if animation_player.has_animation_library(library_name):
		animation_player.remove_animation_library(library_name)
	animation_player.add_animation_library(library_name, library)
	imported_animations[target_name] = "%s/%s" % [library_name, target_name]

func _animation_for(imported_name: String, fallback_candidates: Array) -> String:
	if imported_animations.has(imported_name):
		return imported_animations[imported_name]
	return _pick_animation(fallback_candidates)

func _make_in_place(animation: Animation, lock_vertical_motion: bool):
	for track_index in range(animation.get_track_count()):
		if animation.track_get_type(track_index) != Animation.TYPE_POSITION_3D:
			continue

		var track_path = str(animation.track_get_path(track_index)).to_lower()
		if not _is_root_motion_track(track_path):
			continue

		var key_count = animation.track_get_key_count(track_index)
		if key_count == 0:
			continue

		var base_position = animation.track_get_key_value(track_index, 0)
		for key_index in range(key_count):
			var value = animation.track_get_key_value(track_index, key_index)
			if value is Vector3:
				value.x = base_position.x
				value.z = base_position.z
				if lock_vertical_motion:
					value.y = base_position.y
				animation.track_set_key_value(track_index, key_index, value)

func _is_root_motion_track(track_path: String) -> bool:
	return track_path.contains("hips") or track_path.contains("root") or track_path.contains("mixamorig")

func _set_animation_loop(animation_name: String, enabled: bool):
	if animation_name.is_empty() or not animation_player.has_animation(animation_name):
		return

	var animation = animation_player.get_animation(animation_name)
	if animation:
		animation.loop_mode = Animation.LOOP_LINEAR if enabled else Animation.LOOP_NONE

func _pick_animation(candidates: Array) -> String:
	var names = animation_player.get_animation_list()
	for candidate in candidates:
		for anim_name in names:
			if anim_name.to_lower().contains(str(candidate).to_lower()):
				return anim_name

	if names.is_empty():
		return ""
	return names[0]

func _travel(state_name: String):
	_resume_animation_tree()
	if current_state == state_name:
		return

	current_state = state_name
	state_lock_timer = 0.0
	if state_playback:
		state_playback.travel(state_name)

func _travel_with_lock(state_name: String, lock_time: float):
	_resume_animation_tree()
	if current_state == state_name:
		state_lock_timer = max(state_lock_timer, lock_time)
		return

	current_state = state_name
	state_lock_timer = lock_time
	if state_playback:
		state_playback.travel(state_name)

func _freeze_sneak_pose():
	if current_state == "CrouchPose":
		return
	if not animation_player or not state_animations.has("SneakWalk"):
		return

	if animation_tree:
		animation_tree.active = false

	animation_player.play(state_animations["SneakWalk"])
	animation_player.seek(0.0, true)
	animation_player.pause()
	current_state = "CrouchPose"
	state_lock_timer = 0.0

func _resume_animation_tree():
	if animation_player:
		animation_player.stop(false)
	if animation_tree and not animation_tree.active:
		animation_tree.active = true

func _setup_sockets():
	if not skeleton:
		_add_marker_sockets()
		return

	for socket_name in SOCKET_BONES.keys():
		var bone_index = _find_first_bone(SOCKET_BONES[socket_name])
		if bone_index == -1:
			continue

		var attachment = BoneAttachment3D.new()
		attachment.name = socket_name
		attachment.bone_idx = bone_index
		skeleton.add_child(attachment)

func _add_marker_sockets():
	for socket_name in SOCKET_BONES.keys():
		var marker = Marker3D.new()
		marker.name = socket_name
		add_child(marker)

func _find_first_bone(names: Array) -> int:
	for index in range(skeleton.get_bone_count()):
		var bone_name = skeleton.get_bone_name(index)
		for wanted in names:
			if bone_name == wanted:
				return index
	return -1

func _set_shadow_mode(node: Node, shadows_only: bool):
	if node is GeometryInstance3D:
		node.visible = true
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY if shadows_only else GeometryInstance3D.SHADOW_CASTING_SETTING_ON

	for child in node.get_children():
		_set_shadow_mode(child, shadows_only)

func _normalize_model_size():
	var bounds = _get_visual_bounds(model_root)
	if not bounds.has("valid"):
		return

	var height = bounds["max"].y - bounds["min"].y
	if height <= 0.001:
		return

	var scale_factor = target_model_height / height
	model_root.scale *= scale_factor
	await get_tree().process_frame

	bounds = _get_visual_bounds(model_root)
	if not bounds.has("valid"):
		return

	var target_foot_y = global_position.y + foot_offset_from_origin
	var foot_offset = bounds["min"].y - target_foot_y
	model_root.global_position.y -= foot_offset
	base_model_position = model_root.position
	has_base_model_position = true

func _update_visual_lift(delta: float):
	if not has_base_model_position:
		base_model_position = model_root.position
		has_base_model_position = true

	var target_position = base_model_position
	if current_state in ["CrouchPose", "SneakWalk"]:
		target_position.y += crouch_visual_lift
	elif current_state == "Slide":
		target_position.y += slide_visual_lift

	model_root.position = model_root.position.lerp(target_position, delta * 18.0)

func _get_visual_bounds(node: Node) -> Dictionary:
	var has_bounds = false
	var min_point = Vector3(1.0e20, 1.0e20, 1.0e20)
	var max_point = Vector3(-1.0e20, -1.0e20, -1.0e20)
	var stack: Array[Node] = [node]

	while not stack.is_empty():
		var current = stack.pop_back()
		if current is VisualInstance3D:
			var aabb = current.get_aabb()
			for x in [aabb.position.x, aabb.position.x + aabb.size.x]:
				for y in [aabb.position.y, aabb.position.y + aabb.size.y]:
					for z in [aabb.position.z, aabb.position.z + aabb.size.z]:
						var point = current.global_transform * Vector3(x, y, z)
						min_point = min_point.min(point)
						max_point = max_point.max(point)
						has_bounds = true

		for child in current.get_children():
			stack.append(child)

	if not has_bounds:
		return {}

	return {
		"valid": true,
		"min": min_point,
		"max": max_point,
	}

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D

	for child in node.get_children():
		var found = _find_skeleton(child)
		if found:
			return found
	return null

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer

	for child in node.get_children():
		var found = _find_animation_player(child)
		if found:
			return found
	return null
