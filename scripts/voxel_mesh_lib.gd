extends Node
class_name VoxelMeshLib

# Идентификаторы блоков
const ID_BRICK_WALL   := 0
const ID_STONE_FLOOR  := 1
const ID_WOOD_CEILING := 2
const ID_PILLAR       := 3
const ID_ARCH_DOOR    := 4
const ID_CRATE        := 5
const ID_TORCH        := 6
const ID_LEVER        := 7
const ID_CARPET       := 8
const ID_VAULT_CEILING:= 9

# Имена блоков для UI
const BLOCK_NAMES := [
	"Brick Wall",
	"Stone Floor",
	"Wood Ceiling",
	"Wood Pillar",
	"Arch Door",
	"Wooden Crate",
	"Wall Torch",
	"Wall Lever",
	"Red Carpet",
	"Vault Ceiling",
]

# Иконки (эмодзи для UI кнопок)
const BLOCK_ICONS := [
	"🧱",  # Brick Wall
	"🪨",  # Stone Floor
	"🪵",  # Wood Ceiling
	"🏛️", # Pillar
	"🚪",  # Arch Door
	"📦",  # Wooden Crate
	"🔥",  # Wall Torch
	"🕹️",  # Wall Lever
	"🟥",  # Red Carpet
	"🕍",  # Vault Ceiling
]

## Генерирует и возвращает MeshLibrary со всеми блоками
static func build() -> MeshLibrary:
	var lib := MeshLibrary.new()

	# 1. Грузим внешние текстуры (или создаём заглушки-картинки, если их нет)
	var tex_brick  := _get_texture("brick.png", Color(0.3, 0.25, 0.25))
	var tex_floor  := _get_texture("floor.png", Color(0.3, 0.3, 0.3))
	var tex_ceil   := _get_texture("ceiling.png", Color(0.2, 0.15, 0.1))
	var tex_pillar := _get_texture("pillar.png", Color(0.25, 0.15, 0.05))
	var tex_door   := _get_texture("door.png", Color(0.4, 0.25, 0.15))
	var tex_crate  := _get_texture("crate.png", Color(0.5, 0.3, 0.2))
	var tex_torch  := _get_texture("torch.png", Color(0.9, 0.5, 0.1))
	var tex_lever  := _get_texture("lever.png", Color(0.5, 0.5, 0.5))
	var tex_carpet := _get_texture("carpet.png", Color(0.8, 0.2, 0.2))

	# 2. Создаём материалы
	var mat_brick  := _make_material(tex_brick)
	var mat_floor  := _make_material(tex_floor)
	var mat_ceil   := _make_material(tex_ceil)
	var mat_pillar := _make_material(tex_pillar)
	var mat_door   := _make_material(tex_door)
	var mat_crate  := _make_material(tex_crate)
	var mat_carpet := _make_material(tex_carpet)
	
	var mat_torch  := _make_material(tex_torch)
	mat_torch.emission_enabled = true
	mat_torch.emission_texture = tex_torch
	mat_torch.emission = Color(1.0, 0.8, 0.4)
	mat_torch.emission_energy_multiplier = 1.5
	
	var mat_lever  := _make_material(tex_lever)
	mat_lever.emission_enabled = true
	mat_lever.emission_texture = tex_lever
	mat_lever.emission = Color(1.0, 0.2, 0.2)
	mat_lever.emission_energy_multiplier = 2.0

	# 3. Размеры мешей
	var S   := Vector3(2.0, 2.0, 2.0)   # полный блок 2x2x2
	var SL  := Vector3(2.0, 0.4, 2.0)   # тонкая плита (пол/потолок)
	var SP  := Vector3(0.6, 2.0, 0.6)   # Квадратный столб (Pillar)
	var SD  := Vector3(2.0, 2.0, 0.4)   # Дверь/Арка (тонкая стена)
	var ST  := Vector3(0.4, 0.8, 0.2)   # Настенная панель (Torch / Lever)
	var SC  := Vector3(1.8, 0.1, 1.8)   # Ковёр

	# Основная архитектура
	_add_box_item(lib, ID_BRICK_WALL, "Brick Wall", mat_brick, S, _make_box_shape(S))
	_add_box_item(lib, ID_PILLAR,     "Wood Pillar", mat_pillar, SP, _make_box_shape(SP))
	_add_box_item(lib, ID_CRATE,      "Wooden Crate", mat_crate, S, _make_box_shape(S))
	
	# Архитектура со смещением (чтобы прилегать к краям клетки!)
	# Пол опущен на дно клетки (-0.8)
	_add_box_item_offset(lib, ID_STONE_FLOOR, "Stone Floor", mat_floor, SL, Vector3(0, -0.8, 0))
	# Потолок поднят к верху клетки (+0.8)
	_add_box_item_offset(lib, ID_WOOD_CEILING, "Wood Ceiling", mat_ceil, SL, Vector3(0, 0.8, 0))
	# Дверь прижата к одной из сторон клетки (Z=-0.8), так её можно крутить "R" и прилеплять к стенам!
	_add_box_item_offset(lib, ID_ARCH_DOOR, "Arch Door", mat_door, SD, Vector3(0, 0, -0.8))
	
	# Декорации со смещением
	_add_box_item_offset(lib, ID_TORCH,         "Wall Torch",    mat_torch,  ST, Vector3(0, 0, -0.9))
	_add_box_item_offset(lib, ID_LEVER,         "Wall Lever",    mat_lever,  ST, Vector3(0, 0, -0.9))
	_add_box_item_offset(lib, ID_CARPET,        "Red Carpet",    mat_carpet, SC, Vector3(0, -0.95, 0))
	_add_box_item_offset(lib, ID_VAULT_CEILING, "Vault Ceiling", mat_ceil, Vector3(2.0, 0.4, 2.0), Vector3(0, 0.8, 0))

	return lib


# ─── Вспомогательные функции ──────────────────────────────────────────────────

static func _get_texture(filename: String, fallback_color: Color) -> Texture2D:
	var path := "res://assets/textures/" + filename
	if FileAccess.file_exists(path):
		return load(path) as Texture2D
	
	# Генерируем заглушку-картинку
	DirAccess.make_dir_recursive_absolute("res://assets/textures")
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	
	# Рисуем шумный паттерн для заглушки
	for y in 128:
		for x in 128:
			var c = fallback_color
			if randf() > 0.5: c = c.darkened(0.1)
			img.set_pixel(x, y, c)
			
	# Рамка для наглядности (чтобы было видно края блока)
	for i in 128:
		img.set_pixel(i, 0, Color.BLACK)
		img.set_pixel(i, 127, Color.BLACK)
		img.set_pixel(0, i, Color.BLACK)
		img.set_pixel(127, i, Color.BLACK)
			
	img.save_png("res://assets/textures/" + filename)
	return ImageTexture.create_from_image(img)

static func _make_material(tex: Texture2D) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.roughness = 1.0
	mat.metallic = 0.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	return mat

static func _add_box_item_offset(
		lib: MeshLibrary, id: int, item_name: String, mat: Material, size: Vector3, offset: Vector3
	) -> void:
	lib.create_item(id)
	lib.set_item_name(id, item_name)

	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.surface_set_material(0, mat)
	
	var arr_mesh := ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh.get_mesh_arrays())
	
	var arrays = arr_mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in range(verts.size()):
		verts[i] += offset
	arrays[Mesh.ARRAY_VERTEX] = verts
	
	var final_mesh := ArrayMesh.new()
	final_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	final_mesh.surface_set_material(0, mat)

	lib.set_item_mesh(id, final_mesh)
	
	var shape := _make_box_shape(size)
	var trans := Transform3D(Basis(), offset)
	lib.set_item_shapes(id, [shape, trans])

static func _add_box_item(
		lib: MeshLibrary,
		id: int,
		item_name: String,
		mat: Material,
		size: Vector3,
		shape: Shape3D
	) -> void:
	lib.create_item(id)
	lib.set_item_name(id, item_name)

	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.surface_set_material(0, mat)
	lib.set_item_mesh(id, mesh)

	var trans := Transform3D.IDENTITY
	lib.set_item_shapes(id, [shape, trans])

static func _make_box_shape(size: Vector3) -> BoxShape3D:
	var shape := BoxShape3D.new()
	shape.size = size
	return shape
