extends Node3D

@export_file("*.glb", "*.gltf", "*.tscn") var model_path := ""
@export var target_height := 1.0
@export var yaw_degrees := 0.0
@export var pitch_degrees := 0.0
@export var roll_degrees := 0.0
@export var ground_y_offset := 0.0
@export var cast_shadows := true

var _model: Node3D

func _ready():
	_load_model()

func _load_model():
	if model_path.is_empty():
		return

	var scene = load(model_path) as PackedScene
	if not scene:
		push_warning("Could not load prop model: %s" % model_path)
		return

	_model = scene.instantiate() as Node3D
	if not _model:
		push_warning("Prop model is not a Node3D: %s" % model_path)
		return

	_model.name = "ImportedPropModel"
	_model.rotation_degrees = Vector3(pitch_degrees, yaw_degrees, roll_degrees)
	add_child(_model)
	_normalize_model(_model)
	_prepare_visuals(_model)

func _normalize_model(model: Node3D):
	var bounds = _get_visual_bounds(model)
	if bounds.size.y <= 0.01:
		return

	var scale_factor = target_height / bounds.size.y
	model.scale *= scale_factor

	bounds = _get_visual_bounds(model)
	model.global_position.y += (global_position.y + ground_y_offset) - bounds.position.y

func _prepare_visuals(node: Node):
	if node is GeometryInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_prepare_visuals(child)

func _get_visual_bounds(root: Node3D) -> AABB:
	var has_bounds = false
	var combined := AABB()
	for mesh in _collect_meshes(root):
		var transformed = _transform_aabb(mesh.global_transform, mesh.get_aabb())
		if has_bounds:
			combined = combined.merge(transformed)
		else:
			combined = transformed
			has_bounds = true
	return combined

func _collect_meshes(root: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	if root is MeshInstance3D:
		meshes.append(root)
	for child in root.get_children():
		meshes.append_array(_collect_meshes(child))
	return meshes

func _transform_aabb(transform: Transform3D, box: AABB) -> AABB:
	var min_v = Vector3(INF, INF, INF)
	var max_v = Vector3(-INF, -INF, -INF)
	for x in [box.position.x, box.position.x + box.size.x]:
		for y in [box.position.y, box.position.y + box.size.y]:
			for z in [box.position.z, box.position.z + box.size.z]:
				var point = transform * Vector3(x, y, z)
				min_v = min_v.min(point)
				max_v = max_v.max(point)
	return AABB(min_v, max_v - min_v)
