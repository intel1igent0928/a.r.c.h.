extends CharacterBody3D

const LERP_SPEED := 12.0
const TARGET_HEIGHT := 1.75
const CHARACTER_MODELS := [
	"res://assets/Charakters/lowpoly_anime_character_cyberstyle.glb",
	"res://assets/Charakters/luoli_run.glb"
]

@export var player_label := "Friend"
@export var owner_peer_id: int = 1
@export var model_index: int = 0

@onready var name_label_3d: Label3D = $NameLabel3D
@onready var fallback_mesh: MeshInstance3D = $BodyMesh

var _model_root: Node3D
var _target_position := Vector3.ZERO
var _target_yaw := 0.0


func _ready() -> void:
	_target_position = global_position
	_target_yaw = rotation.y
	_setup_label()
	_setup_fallback_material()
	_load_character_model(model_index)


func _physics_process(delta: float) -> void:
	global_position = global_position.lerp(_target_position, min(delta * LERP_SPEED, 1.0))
	rotation.y = lerp_angle(rotation.y, _target_yaw, min(delta * LERP_SPEED, 1.0))


func set_target(pos: Vector3, yaw: float) -> void:
	_target_position = pos
	_target_yaw = yaw


func set_model_index(index: int) -> void:
	model_index = posmod(index, CHARACTER_MODELS.size())
	if is_inside_tree():
		_load_character_model(model_index)


func set_local_hidden(hidden: bool) -> void:
	visible = not hidden
	set_physics_process(not hidden)


func _setup_label() -> void:
	if name_label_3d == null:
		return

	name_label_3d.text = player_label
	name_label_3d.font_size = 48
	name_label_3d.modulate = Color(0.95, 0.84, 0.42, 1.0)
	name_label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label_3d.position = Vector3(0.0, 2.15, 0.0)


func _setup_fallback_material() -> void:
	if fallback_mesh == null:
		return

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.55, 0.88, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.05, 0.12, 0.30)
	fallback_mesh.material_override = mat


func _load_character_model(index: int) -> void:
	if _model_root != null and is_instance_valid(_model_root):
		_model_root.queue_free()
		_model_root = null

	if CHARACTER_MODELS.is_empty():
		_set_fallback_visible(true)
		return

	var path: String = CHARACTER_MODELS[posmod(index, CHARACTER_MODELS.size())]
	var scene: PackedScene = load(path)
	if scene == null:
		push_warning("RemotePlayer could not load character: %s" % path)
		_set_fallback_visible(true)
		return

	var model := scene.instantiate() as Node3D
	if model == null:
		_set_fallback_visible(true)
		return

	_model_root = Node3D.new()
	_model_root.name = "CharacterModel"
	add_child(_model_root)
	_model_root.add_child(model)
	_normalize_model(model)
	_set_fallback_visible(false)


func _normalize_model(model: Node3D) -> void:
	model.position = Vector3.ZERO
	model.rotation = Vector3.ZERO
	model.scale = Vector3.ONE

	var bounds := _calculate_aabb(_model_root)
	if bounds.size.length() < 0.001:
		return

	var scale_factor: float = TARGET_HEIGHT / max(bounds.size.y, 0.001)
	model.scale = Vector3.ONE * scale_factor

	bounds = _calculate_aabb(_model_root)
	var bottom_center := Vector3(
		bounds.position.x + bounds.size.x * 0.5,
		bounds.position.y,
		bounds.position.z + bounds.size.z * 0.5
	)
	model.position -= bottom_center


func _set_fallback_visible(enabled: bool) -> void:
	if fallback_mesh != null:
		fallback_mesh.visible = enabled


func _calculate_aabb(root: Node3D) -> AABB:
	var bounds := AABB()
	var has_bounds := false
	var stack: Array = [[root, Transform3D.IDENTITY]]

	while not stack.is_empty():
		var item: Array = stack.pop_back()
		var node: Node = item[0]
		var transform: Transform3D = item[1]

		if node is MeshInstance3D:
			for corner in _get_aabb_corners(node.get_aabb()):
				var point: Vector3 = transform * corner
				if not has_bounds:
					bounds = AABB(point, Vector3.ZERO)
					has_bounds = true
				else:
					bounds = bounds.expand(point)

		for child in node.get_children():
			if child is Node3D:
				stack.append([child, transform * child.transform])

	return bounds


func _get_aabb_corners(aabb: AABB) -> Array:
	var p := aabb.position
	var s := aabb.size
	return [
		p,
		p + Vector3(s.x, 0.0, 0.0),
		p + Vector3(0.0, s.y, 0.0),
		p + Vector3(0.0, 0.0, s.z),
		p + Vector3(s.x, s.y, 0.0),
		p + Vector3(s.x, 0.0, s.z),
		p + Vector3(0.0, s.y, s.z),
		p + s
	]
