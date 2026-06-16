## remote_player.gd
## Visual representation of the other player in 3D.
## Uses MultiplayerSynchronizer to receive position/rotation from the owner peer.
extends CharacterBody3D

const LERP_SPEED := 14.0

## Display name shown above the capsule.
@export var player_label := "Игрок 2"
## Which peer owns this puppet (set by the spawner / game_manager).
@export var owner_peer_id: int = 1

@onready var name_label_3d: Label3D = $NameLabel3D
@onready var body_mesh: MeshInstance3D = $BodyMesh
@onready var sync: MultiplayerSynchronizer = $MultiplayerSynchronizer

# Received transform targets (written by the synchronizer)
var _target_position := Vector3.ZERO
var _target_yaw      := 0.0

func _ready() -> void:
	# Only the authority peer drives this node; everyone else gets puppet updates.
	set_multiplayer_authority(owner_peer_id)

	# Configure replication in code so we don't need a binary .tres
	var rep_config = SceneReplicationConfig.new()
	rep_config.add_property(NodePath(".:_target_position"))
	rep_config.add_property(NodePath(".:_target_yaw"))
	sync.replication_config = rep_config

	if name_label_3d:
		name_label_3d.text = player_label
		name_label_3d.font_size = 48
		name_label_3d.modulate = Color(0.9, 0.82, 0.48, 1.0)
		name_label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		name_label_3d.position = Vector3(0.0, 1.2, 0.0)

	if body_mesh:
		# Simple capsule visual
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.25, 0.55, 0.88, 1.0)
		mat.emission_enabled = true
		mat.emission = Color(0.05, 0.12, 0.30)
		body_mesh.material_override = mat

	if is_multiplayer_authority():
		# Hide visual representation for the local player (they see their own FPS arms/camera)
		if body_mesh:
			body_mesh.visible = false
		if name_label_3d:
			name_label_3d.visible = false

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		# --- Authority: send our real transform to others ---
		_target_position = global_position
		_target_yaw      = rotation.y
	else:
		# --- Puppet: smoothly interpolate to received values ---
		global_position = global_position.lerp(_target_position, delta * LERP_SPEED)
		rotation.y      = lerp_angle(rotation.y, _target_yaw, delta * LERP_SPEED)

## Called by GameManager to update authority-side data each frame.
## The MultiplayerSynchronizer then replicates _target_position / _target_yaw.
func update_from_local_player(pos: Vector3, yaw: float) -> void:
	_target_position = pos
	_target_yaw      = yaw
