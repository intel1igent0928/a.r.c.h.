## PixelTextureGen — генерирует текстуры в стиле старых Dungeon Crawlers
## (Толстые чёрные контуры, крупные кирпичи, квадратные деревянные балки)
class_name PixelTextureGen
extends RefCounted

const TEX_SIZE := 32
const C_OUTLINE := Color(0.04, 0.03, 0.03, 1.0) # Жирный комиксный контур

# ─── Публичный API ────────────────────────────────────────────────────────────

## Кирпичная стена (крупные мрачные блоки)
static func make_brick_wall() -> ImageTexture:
	var img := Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGBA8)
	var c_brick := Color(0.35, 0.28, 0.22)
	var c_brick_d := Color(0.25, 0.20, 0.15)
	_fill(img, c_brick)
	_add_noise(img, 0.15, c_brick_d, c_brick)
	
	# 4 ряда кирпичей с толстыми швами
	for row in range(4):
		var y_start := row * 8
		_hline_thick(img, y_start, 2, C_OUTLINE)
		var offset := 0 if row % 2 == 0 else 16
		for x in [offset, offset + 16]:
			_vline_thick(img, x % TEX_SIZE, y_start, y_start + 8, 2, C_OUTLINE)
			
	return ImageTexture.create_from_image(img)

## Каменный пол (крупные плиты)
static func make_stone_floor() -> ImageTexture:
	var img := Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGBA8)
	var c_stone := Color(0.28, 0.28, 0.28)
	var c_stone_d := Color(0.20, 0.20, 0.20)
	_fill(img, c_stone)
	_add_noise(img, 0.1, c_stone_d, c_stone)
	
	# Сетка неровных плит
	for y in [0, 10, 21]: _hline_thick(img, y, 2, C_OUTLINE)
	for x in [0, 10, 21]: _vline_thick(img, x, 0, 32, 2, C_OUTLINE)
	
	return ImageTexture.create_from_image(img)

## Деревянная балка (квадратная, с волокнами)
static func make_wood_pillar() -> ImageTexture:
	var img := Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGBA8)
	var c_wood := Color(0.35, 0.20, 0.10)
	var c_wood_d := Color(0.20, 0.10, 0.05)
	_fill(img, c_wood)
	
	for i in range(15):
		var rx := randi() % TEX_SIZE
		_vline(img, rx, c_wood_d)
	
	# Жирные края балки
	_vline_thick(img, 0, 0, 32, 2, C_OUTLINE)
	_vline_thick(img, 30, 0, 32, 2, C_OUTLINE)
	
	return ImageTexture.create_from_image(img)

## Арочная деревянная дверь
static func make_arch_door() -> ImageTexture:
	var img := Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGBA8)
	_fill(img, C_OUTLINE) # Фон (рамка)
	
	var c_wood := Color(0.40, 0.25, 0.15)
	var c_iron := Color(0.45, 0.45, 0.45)
	
	# Рисуем саму арку
	for y in range(32):
		for x in range(32):
			var dx := absi(x - 16)
			var dy := 16 - y if y < 16 else 0
			if sqrt(float(dx * dx + dy * dy)) < 13.0:
				img.set_pixel(x, y, c_wood)
	
	# Доски
	_vline(img, 10, C_OUTLINE)
	_vline(img, 16, C_OUTLINE)
	_vline(img, 22, C_OUTLINE)
	
	# Железные полосы
	_hline_thick(img, 18, 2, c_iron)
	_hline_thick(img, 26, 2, c_iron)
	
	# Замочная скважина
	img.set_pixel(16, 22, C_OUTLINE)
	img.set_pixel(16, 23, C_OUTLINE)
	
	return ImageTexture.create_from_image(img)

## Настенный рычаг
static func make_lever() -> ImageTexture:
	var img := Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGBA8)
	_fill(img, Color.TRANSPARENT)
	
	var c_iron := Color(0.55, 0.55, 0.55)
	var c_rust := Color(0.60, 0.30, 0.20)
	var c_stick := Color(0.30, 0.15, 0.10)
	
	# Металлическая пластина
	for y in range(6, 26):
		for x in range(10, 22):
			img.set_pixel(x, y, c_iron)
			if randf() > 0.7: img.set_pixel(x, y, c_rust)
			
	# Контур пластины
	for x in range(10, 22):
		img.set_pixel(x, 6, C_OUTLINE)
		img.set_pixel(x, 25, C_OUTLINE)
	for y in range(6, 26):
		img.set_pixel(10, y, C_OUTLINE)
		img.set_pixel(21, y, C_OUTLINE)
		
	# Центральная щель
	_vline_thick(img, 15, 10, 22, 2, C_OUTLINE)
	
	# Красная лампочка (индикатор)
	img.set_pixel(15, 8, Color.RED)
	img.set_pixel(16, 8, Color.RED)
	
	# Палка рычага (наклонена)
	for i in range(8):
		img.set_pixel(15 + i, 16 - i, c_stick)
		img.set_pixel(16 + i, 16 - i, c_stick)
		
	return ImageTexture.create_from_image(img)

## Настенный факел
static func make_torch() -> ImageTexture:
	var img := Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGBA8)
	_fill(img, Color.TRANSPARENT)
	
	var c_stick := Color(0.40, 0.25, 0.15)
	var c_iron := Color(0.40, 0.40, 0.40)
	
	# Палка
	for y in range(16, 26):
		img.set_pixel(15, y, c_stick)
		img.set_pixel(16, y, c_stick)
		
	# Крепление
	_hline_thick(img, 22, 2, c_iron)
	img.set_pixel(14, 22, C_OUTLINE)
	img.set_pixel(17, 22, C_OUTLINE)
	
	# Пламя
	var c_core := Color(1.0, 0.9, 0.4)
	var c_edge := Color(1.0, 0.4, 0.0)
	for y in range(6, 16):
		for x in range(10, 22):
			var dist := absi(x - 15) + absi(y - 14)
			if dist < 6 + randi() % 2:
				img.set_pixel(x, y, c_core if randf() > 0.4 else c_edge)
				
	return ImageTexture.create_from_image(img)

## Деревянный ящик
static func make_wooden_crate() -> ImageTexture:
	var img := Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGBA8)
	var c_wood := Color(0.45, 0.30, 0.15)
	var c_wood_d := Color(0.25, 0.15, 0.05)
	_fill(img, c_wood)
	
	# Рамка
	_hline_thick(img, 0, 3, c_wood_d)
	_hline_thick(img, 29, 3, c_wood_d)
	_vline_thick(img, 0, 0, 32, 3, c_wood_d)
	_vline_thick(img, 29, 0, 32, 3, c_wood_d)
	
	# Контуры
	_hline_thick(img, 0, 1, C_OUTLINE)
	_hline_thick(img, 31, 1, C_OUTLINE)
	_vline_thick(img, 0, 0, 32, 1, C_OUTLINE)
	_vline_thick(img, 31, 0, 32, 1, C_OUTLINE)
	
	# Красная лента (как на скрине)
	var c_ribbon := Color(0.8, 0.1, 0.1)
	_vline_thick(img, 14, 0, 32, 4, c_ribbon)
	_hline_thick(img, 14, 4, c_ribbon)
	
	return ImageTexture.create_from_image(img)

# ─── Утилиты ──────────────────────────────────────────────────────────────────

static func _fill(img: Image, color: Color) -> void:
	img.fill(color)

static func _add_noise(img: Image, amount: float, c1: Color, c2: Color) -> void:
	for y in img.get_height():
		for x in img.get_width():
			if randf() < amount:
				img.set_pixel(x, y, c1 if randf() > 0.5 else c2)

static func _hline_thick(img: Image, y: int, thickness: int, color: Color) -> void:
	for i in range(thickness):
		if y + i < img.get_height():
			for x in img.get_width():
				img.set_pixel(x, y + i, color)

static func _vline_thick(img: Image, x: int, y1: int, y2: int, thickness: int, color: Color) -> void:
	for i in range(thickness):
		if x + i < img.get_width():
			for y in range(y1, y2):
				if y < img.get_height():
					img.set_pixel(x + i, y, color)

static func _vline(img: Image, x: int, color: Color) -> void:
	for y in img.get_height():
		img.set_pixel(x, y, color)

# ─── Создание материала ───────────────────────────────────────────────────────

static func make_block_material(tex: Texture2D) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.roughness = 1.0
	mat.metallic = 0.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat
