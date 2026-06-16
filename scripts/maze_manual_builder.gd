extends Node3D

const SAVE_PATH := "res://saved_mazes/manual_maze.json"
const EXPORT_SCENE_PATH := "res://saved_mazes/manual_maze_built.tscn"
const SCALE_PREFS_PATH := "res://saved_mazes/builder_model_scales.json"
const BUILDER_GROUP := "builder_placed"
const GRID_SIZES := [0.5, 1.0, 2.0, 4.0]
const HEIGHT_STEP_PER_SECOND := 2.5
const SCALE_STEP_PER_SECOND := 0.35
const SCALE_FAST_MULTIPLIER := 4.0

const ASSET_PACKS := {
	"Dungeon": [
		{"name": "walls", "path": "res://assets/Dungeon/walls.glb", "scale": 3.6},
		{"name": "corners", "path": "res://assets/Dungeon/corners.glb", "scale": 3.6},
		{"name": "floor", "path": "res://assets/Dungeon/floor.glb", "scale": 0.04},
		{"name": "door", "path": "res://assets/Dungeon/door.glb", "scale": 0.32},
		{"name": "arch", "path": "res://assets/Dungeon/arch.glb", "scale": 0.3},
		{"name": "column", "path": "res://assets/Dungeon/column.glb", "scale": 0.35}
	],
	"Cave": [
		{"name": "cave_wall", "path": "res://assets/Cave/cave_wall.glb", "scale": 0.004},
		{"name": "cave_floor", "path": "res://assets/Cave/cave_floor.glb", "scale": 0.08},
		{"name": "cave_corridor", "path": "res://assets/Cave/cave_corridor.glb", "scale": 0.24},
		{"name": "rock_wall", "path": "res://assets/Cave/rock_wall.glb", "scale": 0.18},
		{"name": "rock_arch", "path": "res://assets/Cave/rock_arch.glb", "scale": 0.26},
		{"name": "rock_cluster", "path": "res://assets/Cave/rock_cluster.glb", "scale": 0.32}
	],
	"Kenney Modlar": [
		{"name": "corridor", "path": "res://assets/Kenney Modlar/Models/GLB format/corridor.glb", "scale": 1.0},
		{"name": "corridor_corner", "path": "res://assets/Kenney Modlar/Models/GLB format/corridor-corner.glb", "scale": 1.0},
		{"name": "corridor_end", "path": "res://assets/Kenney Modlar/Models/GLB format/corridor-end.glb", "scale": 1.0},
		{"name": "corridor_intersection", "path": "res://assets/Kenney Modlar/Models/GLB format/corridor-intersection.glb", "scale": 1.0},
		{"name": "corridor_junction", "path": "res://assets/Kenney Modlar/Models/GLB format/corridor-junction.glb", "scale": 1.0},
		{"name": "corridor_transition", "path": "res://assets/Kenney Modlar/Models/GLB format/corridor-transition.glb", "scale": 1.0},
		{"name": "corridor_wide", "path": "res://assets/Kenney Modlar/Models/GLB format/corridor-wide.glb", "scale": 1.0},
		{"name": "corridor_wide_corner", "path": "res://assets/Kenney Modlar/Models/GLB format/corridor-wide-corner.glb", "scale": 1.0},
		{"name": "corridor_wide_end", "path": "res://assets/Kenney Modlar/Models/GLB format/corridor-wide-end.glb", "scale": 1.0},
		{"name": "corridor_wide_intersection", "path": "res://assets/Kenney Modlar/Models/GLB format/corridor-wide-intersection.glb", "scale": 1.0},
		{"name": "corridor_wide_junction", "path": "res://assets/Kenney Modlar/Models/GLB format/corridor-wide-junction.glb", "scale": 1.0},
		{"name": "gate", "path": "res://assets/Kenney Modlar/Models/GLB format/gate.glb", "scale": 1.0},
		{"name": "gate_door", "path": "res://assets/Kenney Modlar/Models/GLB format/gate-door.glb", "scale": 1.0},
		{"name": "gate_door_window", "path": "res://assets/Kenney Modlar/Models/GLB format/gate-door-window.glb", "scale": 1.0},
		{"name": "gate_metal_bars", "path": "res://assets/Kenney Modlar/Models/GLB format/gate-metal-bars.glb", "scale": 1.0},
		{"name": "room_corner", "path": "res://assets/Kenney Modlar/Models/GLB format/room-corner.glb", "scale": 1.0},
		{"name": "room_large", "path": "res://assets/Kenney Modlar/Models/GLB format/room-large.glb", "scale": 1.0},
		{"name": "room_large_variation", "path": "res://assets/Kenney Modlar/Models/GLB format/room-large-variation.glb", "scale": 1.0},
		{"name": "room_small", "path": "res://assets/Kenney Modlar/Models/GLB format/room-small.glb", "scale": 1.0},
		{"name": "room_small_variation", "path": "res://assets/Kenney Modlar/Models/GLB format/room-small-variation.glb", "scale": 1.0},
		{"name": "room_wide", "path": "res://assets/Kenney Modlar/Models/GLB format/room-wide.glb", "scale": 1.0},
		{"name": "room_wide_variation", "path": "res://assets/Kenney Modlar/Models/GLB format/room-wide-variation.glb", "scale": 1.0},
		{"name": "stairs", "path": "res://assets/Kenney Modlar/Models/GLB format/stairs.glb", "scale": 1.0},
		{"name": "stairs_wide", "path": "res://assets/Kenney Modlar/Models/GLB format/stairs-wide.glb", "scale": 1.0},
		{"name": "template_floor", "path": "res://assets/Kenney Modlar/Models/GLB format/template-floor.glb", "scale": 1.0},
		{"name": "template_floor_big", "path": "res://assets/Kenney Modlar/Models/GLB format/template-floor-big.glb", "scale": 1.0},
		{"name": "template_wall", "path": "res://assets/Kenney Modlar/Models/GLB format/template-wall.glb", "scale": 1.0},
		{"name": "template_wall_corner", "path": "res://assets/Kenney Modlar/Models/GLB format/template-wall-corner.glb", "scale": 1.0},
		{"name": "template_wall_half", "path": "res://assets/Kenney Modlar/Models/GLB format/template-wall-half.glb", "scale": 1.0},
		{"name": "template_wall_stairs", "path": "res://assets/Kenney Modlar/Models/GLB format/template-wall-stairs.glb", "scale": 1.0},
		{"name": "template_wall_top", "path": "res://assets/Kenney Modlar/Models/GLB format/template-wall-top.glb", "scale": 1.0}
	],
	"Dungeon corridor pack": [
		{"name": "corridor_x2", "path": "res://assets/Uploaded Dungeon Packs/dungeon_corridor_pack_w_assets_and_modules.glb", "node_path": "Sketchfab_model/DungedonAssets_fbx/RootNode/Corridor X2", "scale": 0.65},
		{"name": "corridor_x4", "path": "res://assets/Uploaded Dungeon Packs/dungeon_corridor_pack_w_assets_and_modules.glb", "node_path": "Sketchfab_model/DungedonAssets_fbx/RootNode/Corridor X4", "scale": 0.65},
		{"name": "cross_corridor", "path": "res://assets/Uploaded Dungeon Packs/dungeon_corridor_pack_w_assets_and_modules.glb", "node_path": "Sketchfab_model/DungedonAssets_fbx/RootNode/CrossCorridor", "scale": 0.65},
		{"name": "t_corridor", "path": "res://assets/Uploaded Dungeon Packs/dungeon_corridor_pack_w_assets_and_modules.glb", "node_path": "Sketchfab_model/DungedonAssets_fbx/RootNode/TCorridor", "scale": 0.65},
		{"name": "corner_corridor", "path": "res://assets/Uploaded Dungeon Packs/dungeon_corridor_pack_w_assets_and_modules.glb", "node_path": "Sketchfab_model/DungedonAssets_fbx/RootNode/CornerCorridor", "scale": 0.65},
		{"name": "statue", "path": "res://assets/Uploaded Dungeon Packs/dungeon_corridor_pack_w_assets_and_modules.glb", "node_path": "Sketchfab_model/DungedonAssets_fbx/RootNode/Ind_Asset_Statue", "scale": 0.65},
		{"name": "pillar", "path": "res://assets/Uploaded Dungeon Packs/dungeon_corridor_pack_w_assets_and_modules.glb", "node_path": "Sketchfab_model/DungedonAssets_fbx/RootNode/Ind_Asset_Pillar", "scale": 0.65},
		{"name": "wall", "path": "res://assets/Uploaded Dungeon Packs/dungeon_corridor_pack_w_assets_and_modules.glb", "node_path": "Sketchfab_model/DungedonAssets_fbx/RootNode/Ind_Asset_Wall", "scale": 0.65},
		{"name": "square_wall", "path": "res://assets/Uploaded Dungeon Packs/dungeon_corridor_pack_w_assets_and_modules.glb", "node_path": "Sketchfab_model/DungedonAssets_fbx/RootNode/Ind_Asset_SquareWall", "scale": 0.65},
		{"name": "floor", "path": "res://assets/Uploaded Dungeon Packs/dungeon_corridor_pack_w_assets_and_modules.glb", "node_path": "Sketchfab_model/DungedonAssets_fbx/RootNode/Ind_Asset_Floor", "scale": 0.65},
		{"name": "rugs", "path": "res://assets/Uploaded Dungeon Packs/dungeon_corridor_pack_w_assets_and_modules.glb", "node_path": "Sketchfab_model/DungedonAssets_fbx/RootNode/Ind_Asset_Rugs", "scale": 0.65}
	],
	"Free modular dungeon": [
		{"name": "tile", "path": "res://assets/Uploaded Dungeon Packs/free_modular_low_poly_dungeon_pack.glb", "node_path": "Sketchfab_model/low poly dungeon assets_fbx/RootNode/tile", "scale": 1.15},
		{"name": "tile_001", "path": "res://assets/Uploaded Dungeon Packs/free_modular_low_poly_dungeon_pack.glb", "node_path": "Sketchfab_model/low poly dungeon assets_fbx/RootNode/tile_001", "scale": 1.15},
		{"name": "tile_002", "path": "res://assets/Uploaded Dungeon Packs/free_modular_low_poly_dungeon_pack.glb", "node_path": "Sketchfab_model/low poly dungeon assets_fbx/RootNode/tile_002", "scale": 1.15},
		{"name": "floor", "path": "res://assets/Uploaded Dungeon Packs/free_modular_low_poly_dungeon_pack.glb", "node_path": "Sketchfab_model/low poly dungeon assets_fbx/RootNode/floor", "scale": 1.15},
		{"name": "floor_001", "path": "res://assets/Uploaded Dungeon Packs/free_modular_low_poly_dungeon_pack.glb", "node_path": "Sketchfab_model/low poly dungeon assets_fbx/RootNode/floor_001", "scale": 1.15},
		{"name": "floor_002", "path": "res://assets/Uploaded Dungeon Packs/free_modular_low_poly_dungeon_pack.glb", "node_path": "Sketchfab_model/low poly dungeon assets_fbx/RootNode/floor_002", "scale": 1.15},
		{"name": "railing", "path": "res://assets/Uploaded Dungeon Packs/free_modular_low_poly_dungeon_pack.glb", "node_path": "Sketchfab_model/low poly dungeon assets_fbx/RootNode/railing", "scale": 1.15},
		{"name": "damaged_railing_left", "path": "res://assets/Uploaded Dungeon Packs/free_modular_low_poly_dungeon_pack.glb", "node_path": "Sketchfab_model/low poly dungeon assets_fbx/RootNode/damaged railing left", "scale": 1.15},
		{"name": "damaged_railing_right", "path": "res://assets/Uploaded Dungeon Packs/free_modular_low_poly_dungeon_pack.glb", "node_path": "Sketchfab_model/low poly dungeon assets_fbx/RootNode/damaged railing right", "scale": 1.15},
		{"name": "stairs", "path": "res://assets/Uploaded Dungeon Packs/free_modular_low_poly_dungeon_pack.glb", "node_path": "Sketchfab_model/low poly dungeon assets_fbx/RootNode/stairs", "scale": 1.15},
		{"name": "spikes_floor", "path": "res://assets/Uploaded Dungeon Packs/free_modular_low_poly_dungeon_pack.glb", "node_path": "Sketchfab_model/low poly dungeon assets_fbx/RootNode/spikes floor", "scale": 1.15},
		{"name": "debris", "path": "res://assets/Uploaded Dungeon Packs/free_modular_low_poly_dungeon_pack.glb", "node_path": "Sketchfab_model/low poly dungeon assets_fbx/RootNode/debris", "scale": 1.15},
		{"name": "key", "path": "res://assets/Uploaded Dungeon Packs/free_modular_low_poly_dungeon_pack.glb", "node_path": "Sketchfab_model/low poly dungeon assets_fbx/RootNode/Key_001", "scale": 1.15},
		{"name": "coin", "path": "res://assets/Uploaded Dungeon Packs/free_modular_low_poly_dungeon_pack.glb", "node_path": "Sketchfab_model/low poly dungeon assets_fbx/RootNode/Coin_001", "scale": 1.15},
		{"name": "pillar", "path": "res://assets/Uploaded Dungeon Packs/free_modular_low_poly_dungeon_pack.glb", "node_path": "Sketchfab_model/low poly dungeon assets_fbx/RootNode/pillar", "scale": 1.15},
		{"name": "door", "path": "res://assets/Uploaded Dungeon Packs/free_modular_low_poly_dungeon_pack.glb", "node_path": "Sketchfab_model/low poly dungeon assets_fbx/RootNode/door_013", "scale": 1.15},
		{"name": "door_arc", "path": "res://assets/Uploaded Dungeon Packs/free_modular_low_poly_dungeon_pack.glb", "node_path": "Sketchfab_model/low poly dungeon assets_fbx/RootNode/door arc", "scale": 1.15},
		{"name": "brick_wall", "path": "res://assets/Uploaded Dungeon Packs/free_modular_low_poly_dungeon_pack.glb", "node_path": "Sketchfab_model/low poly dungeon assets_fbx/RootNode/brick wall", "scale": 1.15},
		{"name": "smooth_wall", "path": "res://assets/Uploaded Dungeon Packs/free_modular_low_poly_dungeon_pack.glb", "node_path": "Sketchfab_model/low poly dungeon assets_fbx/RootNode/smooth wall", "scale": 1.15},
		{"name": "torch", "path": "res://assets/Uploaded Dungeon Packs/free_modular_low_poly_dungeon_pack.glb", "node_path": "Sketchfab_model/low poly dungeon assets_fbx/RootNode/torch", "scale": 1.15},
		{"name": "wooden_box", "path": "res://assets/Uploaded Dungeon Packs/free_modular_low_poly_dungeon_pack.glb", "node_path": "Sketchfab_model/low poly dungeon assets_fbx/RootNode/wooden box", "scale": 1.15},
		{"name": "barrel", "path": "res://assets/Uploaded Dungeon Packs/free_modular_low_poly_dungeon_pack.glb", "node_path": "Sketchfab_model/low poly dungeon assets_fbx/RootNode/barrel", "scale": 1.15},
		{"name": "chest_bottom", "path": "res://assets/Uploaded Dungeon Packs/free_modular_low_poly_dungeon_pack.glb", "node_path": "Sketchfab_model/low poly dungeon assets_fbx/RootNode/chest bottom", "scale": 1.15},
		{"name": "chest_top", "path": "res://assets/Uploaded Dungeon Packs/free_modular_low_poly_dungeon_pack.glb", "node_path": "Sketchfab_model/low poly dungeon assets_fbx/RootNode/chest top", "scale": 1.15}
	],
	"Sand biome dungeon": [
		{"name": "floor_1", "path": "res://assets/Uploaded Dungeon Packs/low_poly_modular_dungeon_sand_biome.glb", "node_path": "Sketchfab_model/ModularDungeonSandBiome-Assets_fbx/RootNode/Floor1", "scale": 1.25},
		{"name": "floor_2", "path": "res://assets/Uploaded Dungeon Packs/low_poly_modular_dungeon_sand_biome.glb", "node_path": "Sketchfab_model/ModularDungeonSandBiome-Assets_fbx/RootNode/Floor2", "scale": 1.25},
		{"name": "floor_3", "path": "res://assets/Uploaded Dungeon Packs/low_poly_modular_dungeon_sand_biome.glb", "node_path": "Sketchfab_model/ModularDungeonSandBiome-Assets_fbx/RootNode/Floor3", "scale": 1.25},
		{"name": "floor_4", "path": "res://assets/Uploaded Dungeon Packs/low_poly_modular_dungeon_sand_biome.glb", "node_path": "Sketchfab_model/ModularDungeonSandBiome-Assets_fbx/RootNode/Floor4", "scale": 1.25},
		{"name": "wall", "path": "res://assets/Uploaded Dungeon Packs/low_poly_modular_dungeon_sand_biome.glb", "node_path": "Sketchfab_model/ModularDungeonSandBiome-Assets_fbx/RootNode/WallwithoutPillar", "scale": 1.25},
		{"name": "pillar_wall_1", "path": "res://assets/Uploaded Dungeon Packs/low_poly_modular_dungeon_sand_biome.glb", "node_path": "Sketchfab_model/ModularDungeonSandBiome-Assets_fbx/RootNode/Pillar1Wall1", "scale": 1.25},
		{"name": "pillar_wall_2", "path": "res://assets/Uploaded Dungeon Packs/low_poly_modular_dungeon_sand_biome.glb", "node_path": "Sketchfab_model/ModularDungeonSandBiome-Assets_fbx/RootNode/Pillar2Wall1", "scale": 1.25},
		{"name": "pillar_wall_3", "path": "res://assets/Uploaded Dungeon Packs/low_poly_modular_dungeon_sand_biome.glb", "node_path": "Sketchfab_model/ModularDungeonSandBiome-Assets_fbx/RootNode/Pillar3Wall1", "scale": 1.25},
		{"name": "door_1", "path": "res://assets/Uploaded Dungeon Packs/low_poly_modular_dungeon_sand_biome.glb", "node_path": "Sketchfab_model/ModularDungeonSandBiome-Assets_fbx/RootNode/Pillar1Door", "scale": 1.25},
		{"name": "door_no_pillar", "path": "res://assets/Uploaded Dungeon Packs/low_poly_modular_dungeon_sand_biome.glb", "node_path": "Sketchfab_model/ModularDungeonSandBiome-Assets_fbx/RootNode/Door1WithoutPillar", "scale": 1.25},
		{"name": "cell_bars", "path": "res://assets/Uploaded Dungeon Packs/low_poly_modular_dungeon_sand_biome.glb", "node_path": "Sketchfab_model/ModularDungeonSandBiome-Assets_fbx/RootNode/CellBars", "scale": 1.25},
		{"name": "full_cell_bars", "path": "res://assets/Uploaded Dungeon Packs/low_poly_modular_dungeon_sand_biome.glb", "node_path": "Sketchfab_model/ModularDungeonSandBiome-Assets_fbx/RootNode/FullCellBars", "scale": 1.25},
		{"name": "pillar_1", "path": "res://assets/Uploaded Dungeon Packs/low_poly_modular_dungeon_sand_biome.glb", "node_path": "Sketchfab_model/ModularDungeonSandBiome-Assets_fbx/RootNode/Pillar1", "scale": 1.25},
		{"name": "pillar_2", "path": "res://assets/Uploaded Dungeon Packs/low_poly_modular_dungeon_sand_biome.glb", "node_path": "Sketchfab_model/ModularDungeonSandBiome-Assets_fbx/RootNode/Pillar2", "scale": 1.25},
		{"name": "pillar_3", "path": "res://assets/Uploaded Dungeon Packs/low_poly_modular_dungeon_sand_biome.glb", "node_path": "Sketchfab_model/ModularDungeonSandBiome-Assets_fbx/RootNode/Pillar3", "scale": 1.25},
		{"name": "barrel", "path": "res://assets/Uploaded Dungeon Packs/low_poly_modular_dungeon_sand_biome.glb", "node_path": "Sketchfab_model/ModularDungeonSandBiome-Assets_fbx/RootNode/Barrel", "scale": 1.25},
		{"name": "crate", "path": "res://assets/Uploaded Dungeon Packs/low_poly_modular_dungeon_sand_biome.glb", "node_path": "Sketchfab_model/ModularDungeonSandBiome-Assets_fbx/RootNode/Crate", "scale": 1.25},
		{"name": "brazier", "path": "res://assets/Uploaded Dungeon Packs/low_poly_modular_dungeon_sand_biome.glb", "node_path": "Sketchfab_model/ModularDungeonSandBiome-Assets_fbx/RootNode/Brazier", "scale": 1.25},
		{"name": "sarcophagus", "path": "res://assets/Uploaded Dungeon Packs/low_poly_modular_dungeon_sand_biome.glb", "node_path": "Sketchfab_model/ModularDungeonSandBiome-Assets_fbx/RootNode/Sarcophagus", "scale": 1.25},
		{"name": "torch", "path": "res://assets/Uploaded Dungeon Packs/low_poly_modular_dungeon_sand_biome.glb", "node_path": "Sketchfab_model/ModularDungeonSandBiome-Assets_fbx/RootNode/Torch", "scale": 1.25},
		{"name": "rock_brick_a", "path": "res://assets/Uploaded Dungeon Packs/low_poly_modular_dungeon_sand_biome.glb", "node_path": "Sketchfab_model/ModularDungeonSandBiome-Assets_fbx/RootNode/BrickA", "scale": 1.25},
		{"name": "rock_brick_b", "path": "res://assets/Uploaded Dungeon Packs/low_poly_modular_dungeon_sand_biome.glb", "node_path": "Sketchfab_model/ModularDungeonSandBiome-Assets_fbx/RootNode/BrickB", "scale": 1.25},
		{"name": "rock_brick_c", "path": "res://assets/Uploaded Dungeon Packs/low_poly_modular_dungeon_sand_biome.glb", "node_path": "Sketchfab_model/ModularDungeonSandBiome-Assets_fbx/RootNode/BrickC", "scale": 1.25}
	]
}

@onready var _camera_controller: Node3D = $BuilderCamera
@onready var _camera: Camera3D = $BuilderCamera/Camera3D
@onready var _placed_root: Node3D = $PlacedObjects
@onready var _preview_root: Node3D = $PreviewRoot
@onready var _browser: CanvasLayer = $AssetPackBrowser
@onready var _grid_visual: MeshInstance3D = $GridVisual

var _current_pack := "Dungeon"
var _current_model_index := 0
var _grid_index := 2
var _rotation_steps := 0
var _model_scales := {}
var _height_offset := 0.0
var _preview: Node3D
var _preview_position := Vector3.ZERO
var _preview_bottom_offset := 0.0

# ── Multiplayer ───────────────────────────
const REMOTE_PLAYER_SCENE = preload("res://remote_player.tscn")
var _remote_players := {} # peer_id -> RemotePlayer
var _is_online := false
var _local_avatar_index := 0
var _net_update_timer := 0.0
var _test_mode := false
var _last_mouse_captured := false
var _remote_root: Node3D
var _last_scale_pref_save_time := 0.0

func _ready() -> void:
	_browser.setup_pack_names(ASSET_PACKS.keys())
	_browser.pack_selected.connect(_on_pack_selected)
	_browser.host_requested.connect(_on_host_requested)
	_browser.join_requested.connect(_on_join_requested)
	_browser.disconnect_requested.connect(_on_disconnect_requested)
	_browser.save_requested.connect(_save_maze)
	_browser.export_scene_requested.connect(_export_built_scene)
	_browser.load_requested.connect(func(): _load_maze(true))
	_browser.clear_requested.connect(func(): _clear_placed_objects(true))
	_browser.test_mode_toggled.connect(_set_test_mode)
	_browser.capture_requested.connect(_capture_builder_mouse)
	_browser.set_selected_pack(_current_pack)
	_load_model_scale_preferences()
	_build_grid_visual()
	_rebuild_preview()
	_update_ui()

	# Load existing map (continue tomorrow feature)
	_load_maze()

	# Set unified spawn point for the camera
	if is_instance_valid(_camera_controller):
		_camera_controller.global_position = Vector3(0, 10, 0)

	_remote_root = Node3D.new()
	_remote_root.name = "RemotePlayers"
	add_child(_remote_root)
	randomize()
	_local_avatar_index = randi() % 2
	_last_mouse_captured = Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	_browser.update_input_status(_last_mouse_captured, _test_mode)

	NetworkManager.player_connected.connect(_on_net_player_connected)
	NetworkManager.player_disconnected.connect(_on_net_player_disconnected)
	NetworkManager.connection_failed.connect(_on_net_connection_failed)
	NetworkManager.server_disconnected.connect(_on_net_server_disconnected)
	NetworkManager.server_created.connect(_on_net_connected_to_server)
	multiplayer.connected_to_server.connect(_on_net_connected_to_server)

func _physics_process(delta: float) -> void:
	_update_continuous_adjustments(delta)
	_update_preview_position()

	var captured := Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if captured != _last_mouse_captured:
		_last_mouse_captured = captured
		_browser.update_input_status(captured, _test_mode)

	if _is_online:
		_net_update_timer -= delta
		if _net_update_timer <= 0.0:
			_net_update_timer = 0.05
			_rpc_update_remote_player.rpc(
				multiplayer.get_unique_id(),
				_get_builder_player_position(),
				_get_builder_player_yaw(),
				_local_avatar_index
			)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event.button_index == MOUSE_BUTTON_LEFT and not _test_mode:
			_place_current_model()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_delete_looked_at_object()
			get_viewport().set_input_as_handled()
		return

	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	match event.keycode:
		KEY_Q:
			_select_model(_current_model_index - 1)
		KEY_E:
			_select_model(_current_model_index + 1)
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6:
			_select_model(event.keycode - KEY_1)
		KEY_BRACKETLEFT:
			_set_grid_index(_grid_index - 1)
		KEY_BRACKETRIGHT:
			_set_grid_index(_grid_index + 1)
		KEY_R:
			if event.shift_pressed:
				_rotation_steps -= 1
			else:
				_rotation_steps += 1
			_rotation_steps = posmod(_rotation_steps, 4)
			_apply_preview_transform()
			_update_ui()
		KEY_MINUS:
			_set_current_model_scale(max(0.001, _get_current_model_scale() - _get_scale_key_step(event.shift_pressed)))
			_apply_preview_transform()
			_update_ui()
		KEY_EQUAL:
			_set_current_model_scale(_get_current_model_scale() + _get_scale_key_step(event.shift_pressed))
			_apply_preview_transform()
			_update_ui()
		KEY_BACKSPACE:
			_set_current_model_scale(_get_current_asset_default_scale())
			_apply_preview_transform()
			_update_ui()
		KEY_X:
			_height_offset += 0.05
			_update_preview_position()
			_update_ui()
		KEY_Z:
			_height_offset -= 0.05
			_update_preview_position()
			_update_ui()
		KEY_HOME:
			_height_offset = 0.0
			_update_preview_position()
			_update_ui()
		KEY_DELETE:
			_clear_placed_objects(true)
		KEY_F5:
			_save_maze()
		KEY_F6:
			_export_built_scene()
		KEY_F9:
			_load_maze(true)


func _on_pack_selected(pack_name: String) -> void:
	if not ASSET_PACKS.has(pack_name):
		return

	_current_pack = pack_name
	_current_model_index = 0
	_rotation_steps = 0
	_rebuild_preview()
	_update_ui()


func _select_model(index: int) -> void:
	var pack: Array = ASSET_PACKS[_current_pack]
	if pack.is_empty():
		return

	_current_model_index = posmod(index, pack.size())
	_rotation_steps = 0
	_rebuild_preview()
	_update_ui()


func _set_grid_index(index: int) -> void:
	_grid_index = clamp(index, 0, GRID_SIZES.size() - 1)
	_update_preview_position()
	_update_ui()


func _update_continuous_adjustments(delta: float) -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return
	if _test_mode:
		return

	var changed_height := false
	if Input.is_key_pressed(KEY_X):
		_height_offset += HEIGHT_STEP_PER_SECOND * delta
		changed_height = true
	if Input.is_key_pressed(KEY_Z):
		_height_offset -= HEIGHT_STEP_PER_SECOND * delta
		changed_height = true

	var scale_delta := 0.0
	var scale_speed := SCALE_STEP_PER_SECOND
	if Input.is_key_pressed(KEY_SHIFT):
		scale_speed *= SCALE_FAST_MULTIPLIER
	if Input.is_key_pressed(KEY_EQUAL):
		scale_delta += scale_speed * delta
	if Input.is_key_pressed(KEY_MINUS):
		scale_delta -= scale_speed * delta

	if absf(scale_delta) > 0.0001:
		_set_current_model_scale(max(0.001, _get_current_model_scale() + scale_delta), false)
		_apply_preview_transform()
		_update_ui()
		_save_model_scale_preferences_deferred()

	if changed_height:
		_update_preview_position()
		_update_ui()


func _rebuild_preview() -> void:
	if _preview != null:
		_preview.queue_free()
		_preview = null
	_preview_bottom_offset = 0.0

	var asset := _get_current_asset()
	_preview = _instantiate_asset(asset)
	if _preview == null:
		return

	_preview.name = "GhostPreview"
	_preview_root.add_child(_preview)
	_make_preview_ghost(_preview)
	var bounds := _calculate_local_aabb(_preview)
	if bounds.size.length() >= 0.01:
		_preview_bottom_offset = bounds.position.y
	_preview.visible = not _test_mode
	_apply_preview_transform()


func _update_preview_position() -> void:
	var viewport_center := get_viewport().get_visible_rect().size * 0.5
	var ray_origin := _camera.project_ray_origin(viewport_center)
	var ray_direction := _camera.project_ray_normal(viewport_center)
	var hit := ray_origin + ray_direction * 80.0

	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * 500.0)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	if _preview != null:
		query.exclude = _collect_collision_rids(_preview)

	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		hit = result["position"]

	if absf(ray_direction.y) > 0.0001:
		var t := -ray_origin.y / ray_direction.y
		if result.is_empty() and t > 0.0:
			hit = ray_origin + ray_direction * t

	var grid_size := _get_grid_size()
	_preview_position = Vector3(
		_snap_to_grid(hit.x, grid_size),
		hit.y + _height_offset - _preview_bottom_offset * _get_current_model_scale(),
		_snap_to_grid(hit.z, grid_size)
	)
	_apply_preview_transform()


func _collect_collision_rids(root: Node) -> Array[RID]:
	var result: Array[RID] = []
	if root is CollisionObject3D:
		result.append(root.get_rid())
	for child in root.get_children():
		result.append_array(_collect_collision_rids(child))
	return result


func _apply_preview_transform() -> void:
	if _preview == null:
		return

	_preview.global_position = _preview_position
	_preview.rotation = Vector3(0.0, _get_rotation_y(), 0.0)
	_preview.scale = Vector3.ONE * _get_current_model_scale()


func _place_current_model() -> void:
	var asset = _get_current_asset()
	var pack_name: String = _current_pack
	var model_name: String = asset["name"]
	var pos: Vector3 = _preview_position
	var rot_y: float = _get_rotation_y()
	var scl: float = _get_current_model_scale()
	var unique_name := "Obj_%d_%d" % [Time.get_ticks_usec(), randi() % 1000]

	# Spawn locally
	var wrapper = _spawn_placed_object(pack_name, model_name, pos, rot_y, scl)
	if wrapper:
		wrapper.name = unique_name

	# Tell others
	if _is_online:
		_rpc_spawn_object.rpc(unique_name, pack_name, model_name, pos, rot_y, scl)

@rpc("any_peer", "reliable", "call_remote")
func _rpc_spawn_object(object_name: String, pack_name: String, model_name: String, pos: Vector3, rot_y: float, scl: float) -> void:
	var wrapper = _spawn_placed_object(pack_name, model_name, pos, rot_y, scl)
	if wrapper:
		wrapper.name = object_name


func _spawn_placed_object(pack_name: String, model_name: String, position: Vector3, rotation_y: float, object_scale: float) -> Node3D:
	var asset := _find_asset(pack_name, model_name)
	if asset.is_empty():
		return null

	var model := _instantiate_asset(asset)
	if model == null:
		return null

	var wrapper := Node3D.new()
	wrapper.name = "Placed_%s_%s" % [pack_name, model_name]
	wrapper.add_to_group(BUILDER_GROUP)
	wrapper.set_meta("pack", pack_name)
	wrapper.set_meta("model", model_name)
	wrapper.set_meta("asset_path", asset["path"])
	wrapper.position = position
	wrapper.rotation = Vector3(0.0, rotation_y, 0.0)
	wrapper.scale = Vector3.ONE * object_scale

	model.name = "Model"
	wrapper.add_child(model)
	_placed_root.add_child(wrapper)

	if not _has_collision(wrapper):
		_add_box_collision(wrapper)

	return wrapper


func _delete_looked_at_object() -> void:
	var viewport_center := get_viewport().get_visible_rect().size * 0.5
	var ray_origin := _camera.project_ray_origin(viewport_center)
	var ray_end := ray_origin + _camera.project_ray_normal(viewport_center) * 500.0

	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return

	var node: Node = result["collider"]
	while node != null:
		if node.is_in_group(BUILDER_GROUP):
			# Remove locally
			var node_name = node.name
			node.queue_free()
			# Tell others
			if _is_online:
				_rpc_delete_object.rpc(node_name)
			return
		node = node.get_parent()

@rpc("any_peer", "reliable", "call_remote")
func _rpc_delete_object(node_name: String) -> void:
	var node = _placed_root.get_node_or_null(NodePath(node_name))
	if node and node.is_in_group(BUILDER_GROUP):
		node.queue_free()


func _clear_placed_objects(sync_network := false) -> void:
	if sync_network and _is_online and not multiplayer.is_server():
		push_warning("Only the host can clear the shared maze.")
		_browser.update_net_status("Only host can clear")
		return

	for child in _placed_root.get_children():
		child.queue_free()

	if sync_network and _is_online and multiplayer.is_server():
		_rpc_clear_all_objects.rpc()


@rpc("authority", "reliable", "call_remote")
func _rpc_clear_all_objects() -> void:
	_clear_placed_objects(false)


func _save_maze() -> void:
	if _is_online and not multiplayer.is_server():
		push_warning("Only the host can save the maze.")
		_browser.update_net_status("Only host can save")
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://saved_mazes"))

	var data := []
	for child in _placed_root.get_children():
		if not child.is_in_group(BUILDER_GROUP):
			continue

		data.append({
			"pack": child.get_meta("pack"),
			"model": child.get_meta("model"),
			"position": _vector3_to_array(child.position),
			"rotation": _vector3_to_array(child.rotation),
			"scale": child.scale.x
		})

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save maze to %s" % SAVE_PATH)
		return

	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	_browser.update_net_status("Saved JSON")


func _export_built_scene() -> void:
	if _is_online and not multiplayer.is_server():
		push_warning("Only the host can export the shared maze.")
		_browser.update_net_status("Only host can export")
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://saved_mazes"))

	var export_root := Node3D.new()
	export_root.name = "ManualMazeBuilt"
	for child in _placed_root.get_children():
		if not child.is_in_group(BUILDER_GROUP):
			continue
		var copy := child.duplicate()
		copy.name = child.name
		export_root.add_child(copy)
		copy.owner = export_root
		_set_scene_owner_recursive(copy, export_root)

	var packed := PackedScene.new()
	var pack_error := packed.pack(export_root)
	if pack_error != OK:
		export_root.free()
		push_warning("Could not pack built maze scene: %s" % error_string(pack_error))
		_browser.update_net_status("Export failed")
		return

	var save_error := ResourceSaver.save(packed, EXPORT_SCENE_PATH)
	export_root.free()
	if save_error != OK:
		push_warning("Could not export built maze scene: %s" % error_string(save_error))
		_browser.update_net_status("Export failed")
		return

	_browser.update_net_status("Exported scene")


func _set_scene_owner_recursive(node: Node, scene_owner: Node) -> void:
	for child in node.get_children():
		child.owner = scene_owner
		_set_scene_owner_recursive(child, scene_owner)


func _load_maze(sync_network := false) -> void:
	if sync_network and _is_online and not multiplayer.is_server():
		push_warning("Only the host can load the shared maze.")
		_browser.update_net_status("Only host can load")
		return

	if not FileAccess.file_exists(SAVE_PATH):
		push_warning("No saved maze found at %s" % SAVE_PATH)
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return

	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_ARRAY:
		push_warning("Saved maze JSON is not an array.")
		return

	_clear_placed_objects(false)
	for entry in parsed:
		if typeof(entry) != TYPE_DICTIONARY:
			continue

		var pack_name := str(entry.get("pack", ""))
		var model_name := str(entry.get("model", ""))
		var position := _array_to_vector3(entry.get("position", [0.0, 0.0, 0.0]))
		var rotation := _array_to_vector3(entry.get("rotation", [0.0, 0.0, 0.0]))
		var object_scale := float(entry.get("scale", 1.0))
		_spawn_placed_object(pack_name, model_name, position, rotation.y, object_scale)

	if sync_network and _is_online and multiplayer.is_server():
		_broadcast_full_state()


func _get_current_asset() -> Dictionary:
	return ASSET_PACKS[_current_pack][_current_model_index]


func _get_current_asset_key() -> String:
	var asset := _get_current_asset()
	return "%s/%s" % [_current_pack, asset["name"]]


func _get_current_asset_default_scale() -> float:
	return float(_get_current_asset().get("scale", 1.0))


func _get_current_model_scale() -> float:
	var key := _get_current_asset_key()
	if _model_scales.has(key):
		return float(_model_scales[key])

	var default_scale := _get_current_asset_default_scale()
	_model_scales[key] = default_scale
	return default_scale


func _set_current_model_scale(value: float, save_now := true) -> void:
	_model_scales[_get_current_asset_key()] = max(0.001, value)
	if save_now:
		_save_model_scale_preferences()


func _get_scale_key_step(fast := false) -> float:
	return 0.05 if fast else 0.01


func _save_model_scale_preferences_deferred() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_scale_pref_save_time < 0.25:
		return
	_last_scale_pref_save_time = now
	_save_model_scale_preferences()


func _load_model_scale_preferences() -> void:
	if not FileAccess.file_exists(SCALE_PREFS_PATH):
		return

	var file := FileAccess.open(SCALE_PREFS_PATH, FileAccess.READ)
	if file == null:
		return

	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	_model_scales.clear()
	for key in parsed.keys():
		_model_scales[str(key)] = max(0.01, float(parsed[key]))


func _save_model_scale_preferences() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://saved_mazes"))

	var file := FileAccess.open(SCALE_PREFS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save builder scale preferences to %s" % SCALE_PREFS_PATH)
		return

	file.store_string(JSON.stringify(_model_scales, "\t"))
	file.close()


func _instantiate_asset(asset: Dictionary) -> Node3D:
	var scene: PackedScene = load(asset["path"])
	if scene == null:
		push_warning("Could not load builder asset: %s" % asset["path"])
		return null

	var root := scene.instantiate()
	if not asset.has("node_path"):
		return root as Node3D

	var target := root.get_node_or_null(NodePath(asset["node_path"]))
	if target == null:
		push_warning("Missing node_path '%s' in %s" % [asset["node_path"], asset["path"]])
		root.free()
		return null

	var duplicate := target.duplicate()
	root.free()
	if not (duplicate is Node3D):
		duplicate.free()
		return null

	return _normalize_extracted_asset(duplicate)


func _normalize_extracted_asset(asset_root: Node3D) -> Node3D:
	var wrapper := Node3D.new()
	wrapper.name = "ExtractedAsset"

	asset_root.transform.origin = Vector3.ZERO
	wrapper.add_child(asset_root)

	var bounds := _calculate_local_aabb(wrapper)
	if bounds.size.length() >= 0.01:
		var center_xz := Vector3(
			bounds.position.x + bounds.size.x * 0.5,
			bounds.position.y,
			bounds.position.z + bounds.size.z * 0.5
		)
		asset_root.position -= center_xz

	return wrapper


func _find_asset(pack_name: String, model_name: String) -> Dictionary:
	if not ASSET_PACKS.has(pack_name):
		return {}

	for asset in ASSET_PACKS[pack_name]:
		if asset["name"] == model_name:
			return asset

	return {}


func _get_grid_size() -> float:
	return GRID_SIZES[_grid_index]


func _get_rotation_y() -> float:
	return float(_rotation_steps) * PI * 0.5


func _snap_to_grid(value: float, grid_size: float) -> float:
	return round(value / grid_size) * grid_size


func _make_preview_ghost(node: Node) -> void:
	if node is MeshInstance3D:
		var material := StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(0.25, 0.8, 1.0, 0.38)
		material.emission_enabled = true
		material.emission = Color(0.18, 0.55, 0.9, 1.0)
		material.emission_energy_multiplier = 0.25
		node.material_override = material

	if node is CollisionObject3D:
		node.collision_layer = 0
		node.collision_mask = 0

	for child in node.get_children():
		_make_preview_ghost(child)


func _has_collision(node: Node) -> bool:
	if node is CollisionObject3D:
		return true

	for child in node.get_children():
		if _has_collision(child):
			return true

	return false


func _add_box_collision(wrapper: Node3D) -> void:
	var aabb := _calculate_local_aabb(wrapper)
	if aabb.size.length() < 0.01:
		aabb = AABB(Vector3(-0.5, 0.0, -0.5), Vector3.ONE)

	var body := StaticBody3D.new()
	body.name = "GeneratedBoxCollision"

	var collision_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = aabb.size
	collision_shape.shape = box
	collision_shape.position = aabb.position + aabb.size * 0.5

	body.add_child(collision_shape)
	wrapper.add_child(body)


func _calculate_local_aabb(root: Node3D) -> AABB:
	var bounds := AABB()
	var has_bounds := false

	for child in root.get_children():
		var result := _collect_mesh_bounds(child, child.transform, has_bounds, bounds)
		has_bounds = result["has_bounds"]
		bounds = result["bounds"]

	return bounds


func _collect_mesh_bounds(node: Node, transform: Transform3D, has_bounds: bool, bounds: AABB) -> Dictionary:
	if node is MeshInstance3D:
		var mesh_aabb: AABB = node.get_aabb()
		for corner in _get_aabb_corners(mesh_aabb):
			var point: Vector3 = transform * corner
			if not has_bounds:
				bounds = AABB(point, Vector3.ZERO)
				has_bounds = true
			else:
				bounds = bounds.expand(point)

	for child in node.get_children():
		if child is Node3D:
			var result := _collect_mesh_bounds(child, transform * child.transform, has_bounds, bounds)
			has_bounds = result["has_bounds"]
			bounds = result["bounds"]

	return {
		"has_bounds": has_bounds,
		"bounds": bounds
	}


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


func _vector3_to_array(value: Vector3) -> Array:
	return [value.x, value.y, value.z]


func _array_to_vector3(value) -> Vector3:
	if typeof(value) != TYPE_ARRAY or value.size() < 3:
		return Vector3.ZERO

	return Vector3(float(value[0]), float(value[1]), float(value[2]))


func _get_builder_player_position() -> Vector3:
	if is_instance_valid(_camera_controller):
		return _camera_controller.global_position
	return _camera.global_position


func _get_builder_player_yaw() -> float:
	if is_instance_valid(_camera_controller):
		return _camera_controller.rotation.y
	return _camera.rotation.y


func _update_ui() -> void:
	var asset := _get_current_asset()
	_browser.update_status(
		_current_pack,
		asset["name"],
		_get_grid_size(),
		rad_to_deg(_get_rotation_y()),
		_get_current_model_scale(),
		_height_offset
	)


func _build_grid_visual() -> void:
	var mesh := ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.35, 0.45, 0.48, 0.55)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	var extent := 1200
	for index in range(-extent, extent + 1):
		var alpha_axis := index == 0
		var y := 0.015
		if alpha_axis:
			mesh.surface_set_color(Color(0.7, 0.9, 1.0, 0.9))
		else:
			mesh.surface_set_color(Color(0.35, 0.45, 0.48, 0.28))
		mesh.surface_add_vertex(Vector3(index, y, -extent))
		mesh.surface_add_vertex(Vector3(index, y, extent))
		mesh.surface_add_vertex(Vector3(-extent, y, index))
		mesh.surface_add_vertex(Vector3(extent, y, index))
	mesh.surface_end()

	_grid_visual.mesh = mesh

# ── Multiplayer API ──────────────────────────────────────────────────────────

func _on_host_requested() -> void:
	if _is_online:
		return

	var err := NetworkManager.create_server()
	if err == OK:
		_browser.update_net_status("Hosting on port %d" % NetworkManager.DEFAULT_PORT)
	else:
		_browser.update_net_status("Host failed: %s" % error_string(err))

func _on_join_requested(ip: String) -> void:
	if _is_online:
		return

	if ip.is_empty():
		ip = "127.0.0.1"
	var err := NetworkManager.join_server(ip)
	if err == OK:
		_browser.update_net_status("Connecting to %s..." % ip)
	else:
		_browser.update_net_status("Join failed: %s" % error_string(err))


func _on_disconnect_requested() -> void:
	NetworkManager.disconnect_network()
	_on_net_server_disconnected()


func _capture_builder_mouse() -> void:
	if _camera_controller.has_method("capture_mouse"):
		_camera_controller.capture_mouse()
	_browser.update_input_status(true, _test_mode)


func _set_test_mode(enabled: bool) -> void:
	_test_mode = enabled
	if _camera_controller.has_method("set_test_mode"):
		_camera_controller.set_test_mode(enabled)
	if _preview != null:
		_preview.visible = not _test_mode
	_browser.update_input_status(Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED, _test_mode)

func _old_on_net_player_connected(peer_id: int) -> void:
	if _remote_players.has(peer_id): return
	var rp: CharacterBody3D = REMOTE_PLAYER_SCENE.instantiate()
	rp.name = "RemotePlayer_%d" % peer_id
	rp.set("owner_peer_id", peer_id)
	rp.set("player_label", "Игрок (id %d)" % peer_id)
	rp.global_position = _camera.global_position + Vector3(0, 5, 0) # Spawn slightly above
	get_tree().root.add_child(rp)
	_remote_players[peer_id] = rp

	# If I am host and someone joins, I should send them my entire map state!
	if multiplayer.is_server():
		_send_full_state_to_peer(peer_id)

func _old_on_net_connected_to_server() -> void:
	_is_online = true
	var my_id := multiplayer.get_unique_id()
	_on_net_player_connected(my_id)
	for peer_id in multiplayer.get_peers():
		_on_net_player_connected(peer_id)
	_browser.update_net_status("Connected")

func _old_on_net_player_disconnected(peer_id: int) -> void:
	if _remote_players.has(peer_id):
		var rp = _remote_players[peer_id]
		if is_instance_valid(rp):
			rp.queue_free()
		_remote_players.erase(peer_id)

func _old_on_net_server_disconnected() -> void:
	_is_online = false
	_browser.update_net_status("Offline")
	for pid in _remote_players.keys():
		var rp = _remote_players[pid]
		if is_instance_valid(rp):
			rp.queue_free()
	_remote_players.clear()

func _old_send_full_state_to_peer(peer_id: int) -> void:
	for child in _placed_root.get_children():
		if not child.is_in_group(BUILDER_GROUP): continue
		var pack_name = child.get_meta("pack")
		var model_name = child.get_meta("model")
		var pos = child.position
		var rot_y = child.rotation.y
		var scl = child.scale.x
		# Re-use the sync object name so it matches exactly
		_rpc_sync_existing_object.rpc_id(peer_id, child.name, pack_name, model_name, pos, rot_y, scl)

@rpc("authority", "reliable", "call_remote")
func _old_rpc_sync_existing_object(object_name: String, pack_name: String, model_name: String, pos: Vector3, rot_y: float, scl: float) -> void:
	var wrapper = _spawn_placed_object(pack_name, model_name, pos, rot_y, scl)
	if wrapper:
		wrapper.name = object_name


func _on_net_player_connected(peer_id: int) -> void:
	if _remote_players.has(peer_id):
		return
	_spawn_remote_player(peer_id, peer_id % 2)

	if multiplayer.is_server():
		_send_full_state_to_peer(peer_id)


func _spawn_remote_player(peer_id: int, avatar_index: int) -> Node3D:
	if _remote_players.has(peer_id):
		var existing = _remote_players[peer_id]
		if is_instance_valid(existing) and existing.has_method("set_model_index"):
			existing.set_model_index(avatar_index)
		return existing

	var rp: Node3D = REMOTE_PLAYER_SCENE.instantiate()
	rp.name = "RemotePlayer_%d" % peer_id
	rp.set("owner_peer_id", peer_id)
	rp.set("player_label", "Friend %d" % peer_id)
	rp.set("model_index", avatar_index)
	rp.global_position = _get_builder_player_position()
	if _remote_root == null:
		_remote_root = Node3D.new()
		_remote_root.name = "RemotePlayers"
		add_child(_remote_root)
	_remote_root.add_child(rp)
	_remote_players[peer_id] = rp

	if peer_id == multiplayer.get_unique_id() and rp.has_method("set_local_hidden"):
		rp.set_local_hidden(true)

	return rp


func _on_net_connected_to_server() -> void:
	_is_online = true
	var my_id := multiplayer.get_unique_id()
	_spawn_remote_player(my_id, _local_avatar_index)
	for peer_id in multiplayer.get_peers():
		_on_net_player_connected(peer_id)
	_browser.update_net_status("Connected")


func _on_net_player_disconnected(peer_id: int) -> void:
	if _remote_players.has(peer_id):
		var rp = _remote_players[peer_id]
		if is_instance_valid(rp):
			rp.queue_free()
		_remote_players.erase(peer_id)


func _on_net_server_disconnected() -> void:
	_is_online = false
	_browser.update_net_status("Offline")
	for pid in _remote_players.keys():
		var rp = _remote_players[pid]
		if is_instance_valid(rp):
			rp.queue_free()
	_remote_players.clear()


func _on_net_connection_failed() -> void:
	_is_online = false
	_browser.update_net_status("Connection failed")


func _send_full_state_to_peer(peer_id: int) -> void:
	for child in _placed_root.get_children():
		if not child.is_in_group(BUILDER_GROUP):
			continue
		var pack_name = child.get_meta("pack")
		var model_name = child.get_meta("model")
		var pos = child.position
		var rot_y = child.rotation.y
		var scl = child.scale.x
		_rpc_sync_existing_object.rpc_id(peer_id, child.name, pack_name, model_name, pos, rot_y, scl)


func _broadcast_full_state() -> void:
	_rpc_clear_all_objects.rpc()
	for peer_id in multiplayer.get_peers():
		_send_full_state_to_peer(peer_id)


@rpc("authority", "reliable", "call_remote")
func _rpc_sync_existing_object(object_name: String, pack_name: String, model_name: String, pos: Vector3, rot_y: float, scl: float) -> void:
	var wrapper = _spawn_placed_object(pack_name, model_name, pos, rot_y, scl)
	if wrapper:
		wrapper.name = object_name


@rpc("any_peer", "unreliable", "call_remote")
func _rpc_update_remote_player(peer_id: int, pos: Vector3, yaw: float, avatar_index: int) -> void:
	var rp := _spawn_remote_player(peer_id, avatar_index)
	if rp != null and rp.has_method("set_target"):
		rp.set_target(pos, yaw)
