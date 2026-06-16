## VoxelBuilder — Minecraft-стиль блочный редактор коридоров.
## Строит подземелья из блоков с pixel-art текстурами.
##
## Управление:
##   ЛКМ          — поставить блок
##   ПКМ          — удалить блок
##   Q / E        — предыдущий / следующий тип блока (или колесо мыши)
##   1–8          — выбрать блок напрямую
##   R            — повернуть (90°)
##   Shift+R      — повернуть назад
##   X            — слой выше
##   Z            — слой ниже
##   Home         — сбросить слой
##   F5           — сохранить
##   F9           — загрузить
##   F6           — экспортировать в .tscn
##   Tab          — отпустить / захватить мышь
##   Esc          — вернуться в меню
extends Node3D

const SAVE_PATH   := "res://saved_mazes/voxel_map.json"
const EXPORT_PATH := "res://saved_mazes/voxel_map_built.tscn"
const MENU_SCENE  := "res://scenes/mode_select.tscn"

## Размер одной клетки в метрах (должен совпадать с GridMap.cell_size в .tscn)
const CELL_SIZE  := 2.0

## Дальность строительства (в метрах)
const BUILD_RANGE := 40.0

## Предпросмотр
const PREVIEW_COLOR    := Color(0.3, 0.85, 1.0, 0.45)
const PREVIEW_EMISSION := Color(0.2, 0.6, 1.0)

@onready var _grid_map     : GridMap          = $GridMap
@onready var _deco_grid    : GridMap          = $DecoGrid
@onready var _camera_ctrl  : CharacterBody3D  = $BuilderCamera
@onready var _camera       : Camera3D         = $BuilderCamera/Camera3D
@onready var _ui           : CanvasLayer       = $VoxelUI
@onready var _preview_root : Node3D           = $PreviewRoot
@onready var _grid_vis     : MeshInstance3D   = $GridVisual

var _current_block   := 0
var _rotation_steps  := 0   # 0–3
var _layer           := 0   # вертикальный слой в клетках GridMap
var _preview_mesh    : MeshInstance3D
var _mesh_library    : MeshLibrary
var _last_captured   := false

# ─── Инициализация ────────────────────────────────────────────────────────────

func _ready() -> void:
	_mesh_library = VoxelMeshLib.build()
	if _mesh_library == null:
		push_error("VoxelBuilder: MeshLibrary build failed!")
		return
	_grid_map.mesh_library = _mesh_library
	_deco_grid.mesh_library = _mesh_library

	# Рисуем сетку
	_build_grid_visual()

	call_deferred("_deferred_init")


func _deferred_init() -> void:
	_build_preview_mesh()
	_load_map()
	if _ui.has_method("connect_signals"):
		_ui.connect_signals(self)
	_update_ui()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_last_captured = true


# ─── Основной цикл ────────────────────────────────────────────────────────────

func _physics_process(_delta: float) -> void:
	var cap := Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if cap != _last_captured:
		_last_captured = cap
	if cap:
		_update_preview()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					_place_block()
					get_viewport().set_input_as_handled()
					return
				MOUSE_BUTTON_RIGHT:
					_remove_block()
					get_viewport().set_input_as_handled()
					return
				MOUSE_BUTTON_WHEEL_UP:
					_select_block(_current_block - 1)
					get_viewport().set_input_as_handled()
					return
				MOUSE_BUTTON_WHEEL_DOWN:
					_select_block(_current_block + 1)
					get_viewport().set_input_as_handled()
					return

	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	match event.keycode:
		KEY_Q:  _select_block(_current_block - 1)
		KEY_E:  _select_block(_current_block + 1)
		KEY_1:  _select_block(0)
		KEY_2:  _select_block(1)
		KEY_3:  _select_block(2)
		KEY_4:  _select_block(3)
		KEY_5:  _select_block(4)
		KEY_6:  _select_block(5)
		KEY_7:  _select_block(6)
		KEY_8:  _select_block(7)
		KEY_R:
			if event.shift_pressed:
				_rotation_steps = posmod(_rotation_steps - 1, 4)
			else:
				_rotation_steps = posmod(_rotation_steps + 1, 4)
			_update_ui()
		KEY_X:
			_layer += 1
			_build_grid_visual()
			_update_ui()
		KEY_Z:
			_layer -= 1
			_build_grid_visual()
			_update_ui()
		KEY_HOME:
			_layer = 0
			_build_grid_visual()
			_update_ui()
		KEY_F5:  _save_map()
		KEY_F9:  _load_map(); _update_ui()
		KEY_F6:  _export_scene()
		KEY_ESCAPE:  _go_to_menu()
		KEY_TAB:
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# ─── Блоки ────────────────────────────────────────────────────────────────────

func _select_block(index: int) -> void:
	_current_block = posmod(index, VoxelMeshLib.BLOCK_NAMES.size())
	_build_preview_mesh()
	_update_ui()


func _is_decor(id: int) -> bool:
	return id in [6, 7, 8, 9] # Torch, Lever, Carpet, Vault Ceiling

func _place_block() -> void:
	var info := _get_target_info(true)
	var cell : Vector3i = info.cell
	if not _is_valid_cell(cell):
		return
		
	var orient := _orient_from_steps(_rotation_steps)
	
	if _is_decor(_current_block):
		# Автоповорот для настенных предметов (Torch, Lever) по нормали стены
		if _current_block in [6, 7]:
			orient = _orient_from_normal(info.normal)
		_deco_grid.set_cell_item(cell, _current_block, orient)
	else:
		_grid_map.set_cell_item(cell, _current_block, orient)
	_update_ui()


func _remove_block() -> void:
	# Сначала проверяем ячейку снаружи (где висит декор - ковёр, факел)
	var info_outer := _get_target_info(true)
	var cell_outer : Vector3i = info_outer.cell
	if _is_valid_cell(cell_outer) and _deco_grid.get_cell_item(cell_outer) != GridMap.INVALID_CELL_ITEM:
		_deco_grid.set_cell_item(cell_outer, GridMap.INVALID_CELL_ITEM)
		_update_ui()
		return
		
	# Если декора нет, удаляем основной блок (ячейка внутри)
	var info_inner := _get_target_info(false)
	var cell_inner : Vector3i = info_inner.cell
	if not _is_valid_cell(cell_inner):
		return
		
	if _grid_map.get_cell_item(cell_inner) != GridMap.INVALID_CELL_ITEM:
		_grid_map.set_cell_item(cell_inner, GridMap.INVALID_CELL_ITEM)
	_update_ui()


func _is_valid_cell(cell: Vector3i) -> bool:
	return cell != Vector3i(-9999, -9999, -9999)


## Возвращает инфу о клетке и нормали
func _get_target_info(place: bool) -> Dictionary:
	var invalid := {"cell": Vector3i(-9999, -9999, -9999), "normal": Vector3.UP}
	if not is_instance_valid(_camera):
		return invalid
	var space := get_world_3d().direct_space_state
	if space == null:
		return invalid

	var center   := get_viewport().get_visible_rect().size * 0.5
	var ray_from := _camera.project_ray_origin(center)
	var ray_dir  := _camera.project_ray_normal(center)
	var ray_to   := ray_from + ray_dir * BUILD_RANGE

	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	query.collide_with_bodies = true
	query.exclude = [_camera_ctrl.get_rid()]
	var hit := space.intersect_ray(query)

	if hit.is_empty():
		if place:
			return {"cell": _cell_on_layer_plane(ray_from, ray_dir), "normal": Vector3.UP}
		return invalid

	var hit_pos : Vector3 = hit["position"]
	var normal  : Vector3 = hit["normal"]

	if place:
		# Если ставим декорацию, мы хотим поставить её в ту же клетку, на которую смотрим, если это ковёр на полу.
		# Для факела на стене мы тоже хотим поставить его в ту же клетку, где находится пол, но прижать к стене.
		# Чтобы сохранить логику Майнкрафта (ставим в соседнюю пустую), оставляем смещение наружу.
		var offset := normal * (CELL_SIZE * 0.6)
		# Но если ставим ковёр (11), лучше ставить его в соседнюю ВЕРХНЮЮ ячейку
		return {"cell": _world_to_cell(hit_pos + offset), "normal": normal}
	else:
		return {"cell": _world_to_cell(hit_pos - normal * (CELL_SIZE * 0.1)), "normal": normal}


## Конвертирует мировую позицию → клетку GridMap
func _world_to_cell(world_pos: Vector3) -> Vector3i:
	return _grid_map.local_to_map(_grid_map.to_local(world_pos))


## Ставит на горизонтальную плоскость активного слоя
func _cell_on_layer_plane(ray_from: Vector3, ray_dir: Vector3) -> Vector3i:
	# Центр слоя _layer в мировых координатах
	# GridMap смещён на Y=1, cell(Y) центр = GridMap.Y + layer * CELL_SIZE
	var layer_center_y := _grid_map.global_position.y + float(_layer) * CELL_SIZE
	if abs(ray_dir.y) < 0.001:
		return Vector3i(-9999, -9999, -9999)
	var t := (layer_center_y - ray_from.y) / ray_dir.y
	if t < 0.0 or t > BUILD_RANGE:
		return Vector3i(-9999, -9999, -9999)
	var hit_pt := ray_from + ray_dir * t
	return _world_to_cell(hit_pt)


## GridMap ориентация из шагов поворота
func _orient_from_steps(steps: int) -> int:
	const ORIENTS := [0, 16, 10, 22]
	return ORIENTS[posmod(steps, 4)]

## Автоориентация факела (и других wall-items) по нормали стены
func _orient_from_normal(normal: Vector3) -> int:
	if abs(normal.x) > abs(normal.z):
		if normal.x > 0: return 22 # Смотрит на X+
		else: return 16            # Смотрит на X-
	else:
		if normal.z > 0: return 0  # Смотрит на Z+
		else: return 10            # Смотрит на Z-


# ─── Предпросмотр ─────────────────────────────────────────────────────────────

func _build_preview_mesh() -> void:
	if is_instance_valid(_preview_mesh):
		_preview_mesh.queue_free()
	if _mesh_library == null:
		return

	var src := _mesh_library.get_item_mesh(_current_block)
	if src == null:
		return

	_preview_mesh = MeshInstance3D.new()
	_preview_mesh.mesh = src

	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = PREVIEW_COLOR
	mat.emission_enabled = true
	mat.emission = PREVIEW_EMISSION
	mat.emission_energy_multiplier = 0.5
	mat.no_depth_test = false
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_preview_mesh.material_override = mat
	_preview_root.add_child(_preview_mesh)


func _update_preview() -> void:
	if not is_instance_valid(_preview_mesh):
		return

	var info := _get_target_info(true)
	var cell : Vector3i = info.cell
	if not _is_valid_cell(cell):
		_preview_mesh.visible = false
		return

	_preview_mesh.visible = true
	var local_pos := _grid_map.map_to_local(cell)
	_preview_mesh.global_position = _grid_map.to_global(local_pos)
	
	if _current_block in [6, 7]: # Torch, Lever auto-rotate
		var orient := _orient_from_normal(info.normal)
		# Convert GridMap orientation to degrees (roughly)
		if orient == 22: _preview_mesh.rotation_degrees = Vector3(0, -90, 0)
		elif orient == 16: _preview_mesh.rotation_degrees = Vector3(0, 90, 0)
		elif orient == 0: _preview_mesh.rotation_degrees = Vector3(0, 0, 0)
		else: _preview_mesh.rotation_degrees = Vector3(0, 180, 0)
	else:
		_preview_mesh.rotation_degrees = Vector3(0.0, _rotation_steps * 90.0, 0.0)
		
	_preview_mesh.scale = Vector3.ONE


# ─── Сетка ────────────────────────────────────────────────────────────────────

## Строит/обновляет визуальную сетку для текущего слоя
func _build_grid_visual() -> void:
	if not is_instance_valid(_grid_vis):
		return

	var grid_size  := 30          # клеток в каждую сторону
	var half       := grid_size * CELL_SIZE
	var y_pos      := float(_layer) * CELL_SIZE  # нижняя грань текущего слоя

	var arr_mesh := ArrayMesh.new()
	var verts    : PackedVector3Array
	var colors   : PackedColorArray

	var line_col   := Color(0.4, 0.8, 1.0, 0.55)   # голубые линии сетки
	var accent_col := Color(0.8, 0.5, 1.0, 0.8)     # центральные линии
	var origin_col := Color(1.0, 0.8, 0.2, 1.0)     # ось-ориентир

	for i in range(-grid_size, grid_size + 1):
		var world_x := float(i) * CELL_SIZE
		var world_z := float(i) * CELL_SIZE

		# Выбираем цвет: центр ярче
		var col_x := accent_col if i == 0 else line_col
		var col_z := accent_col if i == 0 else line_col

		# Линия вдоль Z
		verts.append(Vector3(world_x, y_pos, -half))
		verts.append(Vector3(world_x, y_pos,  half))
		colors.append(col_x)
		colors.append(col_x)

		# Линия вдоль X
		verts.append(Vector3(-half, y_pos, world_z))
		verts.append(Vector3( half, y_pos, world_z))
		colors.append(col_z)
		colors.append(col_z)

	# Ось-стрелка (направление "вперёд" — Z-)
	verts.append(Vector3(0, y_pos, 0))
	verts.append(Vector3(0, y_pos, -CELL_SIZE * 3.0))
	colors.append(origin_col)
	colors.append(origin_col)

	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_COLOR]  = colors
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arr)

	# Материал для линий
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = false
	arr_mesh.surface_set_material(0, mat)

	_grid_vis.mesh = arr_mesh

	# Надпись текущего слоя в UI
	if _ui.has_method("update_status"):
		pass  # обновится через _update_ui()


# ─── Сохранение / Загрузка ────────────────────────────────────────────────────

func _save_map() -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("res://saved_mazes")
	)
	var data := {"grid": [], "deco": []}
	for cell in _grid_map.get_used_cells():
		data.grid.append({
			"x": cell.x, "y": cell.y, "z": cell.z,
			"item":   _grid_map.get_cell_item(cell),
			"orient": _grid_map.get_cell_item_orientation(cell)
		})
	for cell in _deco_grid.get_used_cells():
		data.deco.append({
			"x": cell.x, "y": cell.y, "z": cell.z,
			"item":   _deco_grid.get_cell_item(cell),
			"orient": _deco_grid.get_cell_item_orientation(cell)
		})
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()
	if _ui.has_method("show_status"):
		_ui.show_status("💾 Saved!")


func _load_map() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	
	_grid_map.clear()
	_deco_grid.clear()
	
	if typeof(parsed) == TYPE_ARRAY:
		# Старый формат (только GridMap)
		for entry in parsed:
			if typeof(entry) != TYPE_DICTIONARY: continue
			var cell := Vector3i(int(entry.get("x", 0)), int(entry.get("y", 0)), int(entry.get("z", 0)))
			_grid_map.set_cell_item(cell, int(entry.get("item", 0)), int(entry.get("orient", 0)))
	elif typeof(parsed) == TYPE_DICTIONARY:
		# Новый формат
		for entry in parsed.get("grid", []):
			var cell := Vector3i(int(entry.get("x", 0)), int(entry.get("y", 0)), int(entry.get("z", 0)))
			_grid_map.set_cell_item(cell, int(entry.get("item", 0)), int(entry.get("orient", 0)))
		for entry in parsed.get("deco", []):
			var cell := Vector3i(int(entry.get("x", 0)), int(entry.get("y", 0)), int(entry.get("z", 0)))
			_deco_grid.set_cell_item(cell, int(entry.get("item", 0)), int(entry.get("orient", 0)))
			
	if _ui.has_method("show_status"):
		_ui.show_status("📂 Loaded!")


func _export_scene() -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("res://saved_mazes")
	)
	var root := Node3D.new()
	root.name = "VoxelMapBuilt"
	var g := _grid_map.duplicate() as GridMap
	g.name = "GridMap"
	root.add_child(g)
	g.owner = root
	var packed := PackedScene.new()
	if packed.pack(root) == OK:
		ResourceSaver.save(packed, EXPORT_PATH)
		if _ui.has_method("show_status"):
			_ui.show_status("📦 Exported!")
	root.free()


func _go_to_menu() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file(MENU_SCENE)


# ─── UI ───────────────────────────────────────────────────────────────────────

func _update_ui() -> void:
	if not is_instance_valid(_ui):
		return
	if _ui.has_method("update_status"):
		_ui.update_status(
			_current_block,
			VoxelMeshLib.BLOCK_NAMES[_current_block],
			VoxelMeshLib.BLOCK_ICONS[_current_block],
			_rotation_steps * 90,
			_layer,
			_grid_map.get_used_cells().size()
		)


# ─── Публичный API для UI ─────────────────────────────────────────────────────

func select_block_by_id(id: int) -> void: _select_block(id)
func request_save()   -> void: _save_map()
func request_load()   -> void: _load_map(); _update_ui()
func request_export() -> void: _export_scene()
func request_menu()   -> void: _go_to_menu()
func request_clear()  -> void:
	_grid_map.clear()
	_update_ui()
	if _ui.has_method("show_status"):
		_ui.show_status("🗑️ Cleared")
