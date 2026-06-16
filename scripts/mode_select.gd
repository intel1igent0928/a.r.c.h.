extends Control

## ModeSelect — главный экран выбора режима.
## Показывается при запуске игры. Позволяет выбрать:
##   • Classic Builder — старый режим с готовыми 3D-моделями
##   • Voxel Builder   — новый режим, строительство блоками в пиксельном стиле

const CLASSIC_SCENE := "res://scenes/maze_manual_builder.tscn"
const VOXEL_SCENE   := "res://scenes/voxel_builder.tscn"

var _title_anim_time := 0.0

@onready var _btn_classic : Button = $CenterContainer/VBox/Modes/BtnClassic
@onready var _btn_voxel   : Button = $CenterContainer/VBox/Modes/BtnVoxel
@onready var _btn_quit    : Button = $CenterContainer/VBox/BtnQuit
@onready var _title_label : Label  = $CenterContainer/VBox/Title
@onready var _sub_label   : Label  = $CenterContainer/VBox/SubTitle


func _ready() -> void:
	_apply_style()

	_btn_classic.pressed.connect(_on_classic_pressed)
	_btn_voxel.pressed.connect(_on_voxel_pressed)
	_btn_quit.pressed.connect(_on_quit_pressed)

	# Плавное появление
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.65).set_ease(Tween.EASE_OUT)

	# Анимация подзаголовка
	if is_instance_valid(_sub_label):
		_sub_label.modulate.a = 0.0
		var tw2 := create_tween()
		tw2.tween_interval(0.4)
		tw2.tween_property(_sub_label, "modulate:a", 1.0, 0.5)


func _process(delta: float) -> void:
	_title_anim_time += delta
	if is_instance_valid(_title_label):
		var flicker := 0.92 + sin(_title_anim_time * 3.1) * 0.08
		_title_label.modulate = Color(flicker, flicker * 0.88, 0.5, 1.0)


func _on_classic_pressed() -> void:
	_load_scene(CLASSIC_SCENE)


func _on_voxel_pressed() -> void:
	_load_scene(VOXEL_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _load_scene(path: String) -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.35).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): get_tree().change_scene_to_file(path))


# ─── Стили ────────────────────────────────────────────────────────────────────

func _apply_style() -> void:
	var col_bg      := Color(0.06, 0.04, 0.03)
	var col_border  := Color(0.45, 0.28, 0.10)
	var col_text    := Color(0.95, 0.88, 0.65)
	var col_btn_n   := Color(0.14, 0.09, 0.05, 0.95)
	var col_btn_h   := Color(0.24, 0.16, 0.07, 1.0)
	var col_btn_p   := Color(0.34, 0.22, 0.08, 1.0)
	var col_gold    := Color(1.0,  0.78, 0.28, 1.0)
	var col_quit_bg := Color(0.28, 0.10, 0.06, 0.88)

	var bg := find_child("BgColor", true, false) as ColorRect
	if bg:
		bg.color = col_bg

	_style_big_button(_btn_classic, col_btn_n, col_btn_h, col_btn_p, col_border, col_text)
	_style_big_button(_btn_voxel,   col_btn_n, col_btn_h, col_btn_p, col_gold,   col_text)
	_style_small_button(_btn_quit, col_quit_bg, col_text)

	if is_instance_valid(_title_label):
		_title_label.add_theme_font_size_override("font_size", 56)
		_title_label.add_theme_color_override("font_color", col_gold)
		_title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
		_title_label.add_theme_constant_override("shadow_offset_x", 3)
		_title_label.add_theme_constant_override("shadow_offset_y", 3)

	if is_instance_valid(_sub_label):
		_sub_label.add_theme_font_size_override("font_size", 18)
		_sub_label.add_theme_color_override("font_color", Color(0.70, 0.62, 0.45))

	var hint := find_child("HintLabel", true, false) as Label
	if hint:
		hint.add_theme_font_size_override("font_size", 14)
		hint.add_theme_color_override("font_color", Color(0.50, 0.42, 0.28))

	var sep := find_child("TitleUnderline", true, false) as HSeparator
	if sep:
		var sep_style := StyleBoxFlat.new()
		sep_style.bg_color = col_border
		sep.add_theme_stylebox_override("separator", sep_style)


func _style_big_button(
		btn: Button,
		col_n: Color, col_h: Color, col_p: Color,
		col_border: Color, col_text: Color
	) -> void:
	if not is_instance_valid(btn):
		return
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", col_text)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.7))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 0.8))
	for state in ["normal", "hover", "pressed", "focus"]:
		var s := StyleBoxFlat.new()
		s.corner_radius_top_left = 8
		s.corner_radius_top_right = 8
		s.corner_radius_bottom_right = 8
		s.corner_radius_bottom_left = 8
		s.border_width_left = 2
		s.border_width_top = 2
		s.border_width_right = 2
		s.border_width_bottom = 2
		s.content_margin_left   = 18.0
		s.content_margin_right  = 18.0
		s.content_margin_top    = 12.0
		s.content_margin_bottom = 12.0
		match state:
			"normal":
				s.bg_color     = col_n
				s.border_color = col_border
			"hover":
				s.bg_color     = col_h
				s.border_color = col_border.lightened(0.3)
				s.border_width_left = 3
				s.border_width_top = 3
				s.border_width_right = 3
				s.border_width_bottom = 3
			"pressed":
				s.bg_color     = col_p
				s.border_color = Color(1.0, 0.85, 0.3, 1.0)
				s.border_width_left = 3
				s.border_width_top = 3
				s.border_width_right = 3
				s.border_width_bottom = 3
			"focus":
				s.bg_color     = col_n
				s.border_color = col_border.lightened(0.2)
		btn.add_theme_stylebox_override(state, s)


func _style_small_button(btn: Button, col_bg: Color, _col_text: Color) -> void:
	if not is_instance_valid(btn):
		return
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color(0.75, 0.45, 0.35))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.65, 0.5))
	for state in ["normal", "hover", "pressed"]:
		var s := StyleBoxFlat.new()
		s.corner_radius_top_left = 6
		s.corner_radius_top_right = 6
		s.corner_radius_bottom_right = 6
		s.corner_radius_bottom_left = 6
		s.border_width_left = 1
		s.border_width_top = 1
		s.border_width_right = 1
		s.border_width_bottom = 1
		s.content_margin_left   = 16.0
		s.content_margin_right  = 16.0
		s.content_margin_top    = 8.0
		s.content_margin_bottom = 8.0
		match state:
			"normal":
				s.bg_color     = col_bg
				s.border_color = Color(0.45, 0.20, 0.12)
			"hover":
				s.bg_color     = col_bg.lightened(0.1)
				s.border_color = Color(0.7, 0.35, 0.22)
			"pressed":
				s.bg_color     = col_bg.darkened(0.1)
				s.border_color = Color(1.0, 0.5, 0.3)
		btn.add_theme_stylebox_override(state, s)
