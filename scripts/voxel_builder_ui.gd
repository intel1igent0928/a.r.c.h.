## VoxelBuilderUI — интерфейс Voxel Builder.
## Боковая панель с выбором блоков, статус-бар, подсказки.
extends CanvasLayer

signal block_selected(id: int)
signal save_pressed()
signal load_pressed()
signal export_pressed()
signal clear_pressed()
signal menu_pressed()

# Ссылка на основной билдер
var _builder : Node

# UI элементы
@onready var _block_palette  : HBoxContainer  = %BlockPalette
@onready var _status_bar     : Label          = %StatusBar
@onready var _block_name_lbl : Label          = %BlockName
@onready var _coord_lbl      : Label          = %CoordLabel
@onready var _hint_panel     : PanelContainer = %HintPanel
@onready var _toast_label    : Label          = %ToastLabel

var _toast_timer    := 0.0
var _palette_btns   : Array[Button] = []


func _ready() -> void:
	_build_palette()
	_setup_toolbar()

	# Скрываем тост изначально
	if is_instance_valid(_toast_label):
		_toast_label.modulate.a = 0.0


func _process(delta: float) -> void:
	# Тост-уведомление затухает
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if is_instance_valid(_toast_label):
			_toast_label.modulate.a = clamp(_toast_timer / 0.5, 0.0, 1.0)


## Подключаем сигналы к билдеру
func connect_signals(builder: Node) -> void:
	_builder = builder
	block_selected.connect(builder.select_block_by_id)
	save_pressed.connect(builder.request_save)
	load_pressed.connect(builder.request_load)
	export_pressed.connect(builder.request_export)
	clear_pressed.connect(builder.request_clear)
	menu_pressed.connect(builder.request_menu)


## Обновляет статус-бар
func update_status(
		block_id: int,
		block_name: String,
		block_icon: String,
		rotation_deg: int,
		layer: int,
		cell_count: int
	) -> void:
	if is_instance_valid(_block_name_lbl):
		_block_name_lbl.text = "%s %s" % [block_icon, block_name]

	if is_instance_valid(_status_bar):
		_status_bar.text = "Layer: %+d  |  Rot: %d°  |  Blocks: %d" % [layer, rotation_deg, cell_count]

	# Подсвечиваем активную кнопку в палитре
	for i in _palette_btns.size():
		_palette_btns[i].button_pressed = (i == block_id)


## Показывает тост-уведомление
func show_status(msg: String) -> void:
	if not is_instance_valid(_toast_label):
		return
	_toast_label.text = msg
	_toast_label.modulate.a = 1.0
	_toast_timer = 2.0


# ─── Построение UI ────────────────────────────────────────────────────────────

func _build_palette() -> void:
	if not is_instance_valid(_block_palette):
		return

	# Очищаем
	for child in _block_palette.get_children():
		child.queue_free()
	_palette_btns.clear()

	for i in VoxelMeshLib.BLOCK_NAMES.size():
		var btn := Button.new()
		btn.text         = "%s\n%s" % [VoxelMeshLib.BLOCK_ICONS[i], VoxelMeshLib.BLOCK_NAMES[i].replace(" ", "\n")]
		btn.custom_minimum_size = Vector2(72, 72)
		btn.toggle_mode  = true
		btn.button_group = ButtonGroup.new() if i == 0 else _palette_btns[0].button_group

		# Стиль
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color   = Color(0.12, 0.10, 0.08, 0.88)
		normal_style.border_width_left = 2
		normal_style.border_width_top = 2
		normal_style.border_width_right = 2
		normal_style.border_width_bottom = 2
		normal_style.border_color     = Color(0.35, 0.25, 0.15, 1.0)
		normal_style.corner_radius_top_left = 4
		normal_style.corner_radius_top_right = 4
		normal_style.corner_radius_bottom_right = 4
		normal_style.corner_radius_bottom_left = 4
		btn.add_theme_stylebox_override("normal", normal_style)

		var pressed_style := normal_style.duplicate() as StyleBoxFlat
		pressed_style.bg_color     = Color(0.28, 0.18, 0.08, 0.95)
		pressed_style.border_color = Color(1.0, 0.72, 0.2, 1.0)
		pressed_style.border_width_left = 3
		pressed_style.border_width_top = 3
		pressed_style.border_width_right = 3
		pressed_style.border_width_bottom = 3
		btn.add_theme_stylebox_override("pressed", pressed_style)

		var hover_style := normal_style.duplicate() as StyleBoxFlat
		hover_style.bg_color = Color(0.18, 0.14, 0.10, 0.92)
		hover_style.border_color = Color(0.65, 0.50, 0.25, 1.0)
		btn.add_theme_stylebox_override("hover", hover_style)

		btn.add_theme_color_override("font_color", Color(0.92, 0.85, 0.65))
		btn.add_theme_font_size_override("font_size", 10)

		var idx := i
		btn.pressed.connect(func(): block_selected.emit(idx))

		_block_palette.add_child(btn)
		_palette_btns.append(btn)

	if _palette_btns.size() > 0:
		_palette_btns[0].button_pressed = true


func _setup_toolbar() -> void:
	# Кнопки тулбара ищем по именам
	var btn_save   := _find_button("BtnSave")
	var btn_load   := _find_button("BtnLoad")
	var btn_export := _find_button("BtnExport")
	var btn_clear  := _find_button("BtnClear")
	var btn_menu   := _find_button("BtnMenu")

	if btn_save:   btn_save.pressed.connect(func():   save_pressed.emit())
	if btn_load:   btn_load.pressed.connect(func():   load_pressed.emit())
	if btn_export: btn_export.pressed.connect(func(): export_pressed.emit())
	if btn_clear:  btn_clear.pressed.connect(func():  clear_pressed.emit())
	if btn_menu:   btn_menu.pressed.connect(func():   menu_pressed.emit())


func _find_button(btn_name: String) -> Button:
	return find_child(btn_name, true, false) as Button
