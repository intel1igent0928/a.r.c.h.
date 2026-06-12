extends Node3D

const SAVE_PATH := "res://saved_mazes/manual_maze.json"
const SCALE_PREFS_PATH := "res://saved_mazes/builder_model_scales.json"
const BUILDER_GROUP := "builder_placed"
const GRID_SIZES := [0.5, 1.0, 2.0, 4.0]

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

@onready var _camera: Camera3D = $BuilderCamera
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


func _ready() -> void:
	_browser.setup_pack_names(ASSET_PACKS.keys())
	_browser.pack_selected.connect(_on_pack_selected)
	_browser.set_selected_pack(_current_pack)
	_load_model_scale_preferences()
	_build_grid_visual()
	_rebuild_preview()
	_update_ui()


func _physics_process(_delta: float) -> void:
	_update_preview_position()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event.button_index == MOUSE_BUTTON_LEFT:
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
			_set_current_model_scale(max(0.01, _get_current_model_scale() - 0.1))
			_apply_preview_transform()
			_update_ui()
		KEY_EQUAL:
			_set_current_model_scale(_get_current_model_scale() + 0.1)
			_apply_preview_transform()
			_update_ui()
		KEY_BACKSPACE:
			_set_current_model_scale(_get_current_asset_default_scale())
			_apply_preview_transform()
			_update_ui()
		KEY_X:
			_height_offset += 0.25
			_update_preview_position()
			_update_ui()
		KEY_Z:
			_height_offset -= 0.25
			_update_preview_position()
			_update_ui()
		KEY_HOME:
			_height_offset = 0.0
			_update_preview_position()
			_update_ui()
		KEY_DELETE:
			_clear_placed_objects()
		KEY_F5:
			_save_maze()
		KEY_F9:
			_load_maze()


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


func _rebuild_preview() -> void:
	if _preview != null:
		_preview.queue_free()
		_preview = null

	var asset := _get_current_asset()
	_preview = _instantiate_asset(asset)
	if _preview == null:
		return

	_preview.name = "GhostPreview"
	_preview_root.add_child(_preview)
	_make_preview_ghost(_preview)
	_apply_preview_transform()


func _update_preview_position() -> void:
	var viewport_center := get_viewport().get_visible_rect().size * 0.5
	var ray_origin := _camera.project_ray_origin(viewport_center)
	var ray_direction := _camera.project_ray_normal(viewport_center)
	var hit := ray_origin + ray_direction * 80.0

	if absf(ray_direction.y) > 0.0001:
		var t := -ray_origin.y / ray_direction.y
		if t > 0.0:
			hit = ray_origin + ray_direction * t

	var grid_size := _get_grid_size()
	_preview_position = Vector3(
		_snap_to_grid(hit.x, grid_size),
		_height_offset,
		_snap_to_grid(hit.z, grid_size)
	)
	_apply_preview_transform()


func _apply_preview_transform() -> void:
	if _preview == null:
		return

	_preview.global_position = _preview_position
	_preview.rotation = Vector3(0.0, _get_rotation_y(), 0.0)
	_preview.scale = Vector3.ONE * _get_current_model_scale()


func _place_current_model() -> void:
	var asset := _get_current_asset()
	_spawn_placed_object(
		_current_pack,
		asset["name"],
		_preview_position,
		_get_rotation_y(),
		_get_current_model_scale()
	)


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
			node.queue_free()
			return
		node = node.get_parent()


func _clear_placed_objects() -> void:
	for child in _placed_root.get_children():
		child.queue_free()


func _save_maze() -> void:
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


func _load_maze() -> void:
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

	_clear_placed_objects()
	for entry in parsed:
		if typeof(entry) != TYPE_DICTIONARY:
			continue

		var pack_name := str(entry.get("pack", ""))
		var model_name := str(entry.get("model", ""))
		var position := _array_to_vector3(entry.get("position", [0.0, 0.0, 0.0]))
		var rotation := _array_to_vector3(entry.get("rotation", [0.0, 0.0, 0.0]))
		var object_scale := float(entry.get("scale", 1.0))
		_spawn_placed_object(pack_name, model_name, position, rotation.y, object_scale)


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


func _set_current_model_scale(value: float) -> void:
	_model_scales[_get_current_asset_key()] = max(0.01, value)
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
	return duplicate as Node3D


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
