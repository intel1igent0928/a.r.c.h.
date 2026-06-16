extends CanvasLayer

signal pack_selected(pack_name: String)
signal host_requested()
signal join_requested(ip: String)
signal disconnect_requested()
signal save_requested()
signal export_scene_requested()
signal load_requested()
signal clear_requested()
signal test_mode_toggled(enabled: bool)
signal capture_requested()

var _pack_selector: OptionButton
var _status_label: Label
var _help_label: Label
var _net_status_label: Label
var _mode_status_label: Label
var _ip_input: LineEdit
var _test_toggle: CheckBox


func _ready() -> void:
	_build_ui()


func setup_pack_names(pack_names: Array) -> void:
	if _pack_selector == null:
		_build_ui()

	_pack_selector.clear()
	for pack_name in pack_names:
		_pack_selector.add_item(str(pack_name))


func set_selected_pack(pack_name: String) -> void:
	if _pack_selector == null:
		return

	for index in range(_pack_selector.item_count):
		if _pack_selector.get_item_text(index) == pack_name:
			_pack_selector.select(index)
			return


func update_status(pack_name: String, model_name: String, grid_size: float, rotation_degrees: float, object_scale: float, height_offset: float) -> void:
	if _status_label == null:
		return

	_status_label.text = "Pack: %s\nModel: %s\nGrid: %.1f\nRotation: %.0f\nScale: %.2f\nHeight: %.2f" % [
		pack_name,
		model_name,
		grid_size,
		rotation_degrees,
		object_scale,
		height_offset
	]


func update_net_status(status_text: String) -> void:
	if _net_status_label != null:
		_net_status_label.text = status_text


func update_input_status(captured: bool, test_mode: bool) -> void:
	if _mode_status_label == null:
		return

	var cursor_text := "Camera locked" if captured else "Cursor free"
	var mode_text := "Test view" if test_mode else "Build view"
	_mode_status_label.text = "%s | %s" % [cursor_text, mode_text]


func set_test_mode(enabled: bool) -> void:
	if _test_toggle != null:
		_test_toggle.button_pressed = enabled
	update_input_status(Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED, enabled)


func _build_ui() -> void:
	if _pack_selector != null:
		return

	var root := VBoxContainer.new()
	root.name = "BuilderUI"
	root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root.position = Vector2(16, 16)
	root.custom_minimum_size = Vector2(430, 0)
	add_child(root)

	var panel := PanelContainer.new()
	root.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	content.add_child(title_row)

	var title := Label.new()
	title.text = "A.R.C.H. Maze Builder"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	var capture_btn := Button.new()
	capture_btn.text = "Capture"
	capture_btn.tooltip_text = "Lock mouse and fly/build in the 3D view."
	capture_btn.pressed.connect(func(): capture_requested.emit())
	title_row.add_child(capture_btn)

	var pack_row := HBoxContainer.new()
	pack_row.add_theme_constant_override("separation", 8)
	content.add_child(pack_row)

	var pack_label := Label.new()
	pack_label.text = "Pack"
	pack_label.custom_minimum_size = Vector2(58, 0)
	pack_row.add_child(pack_label)

	_pack_selector = OptionButton.new()
	_pack_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pack_selector.item_selected.connect(_on_pack_item_selected)
	pack_row.add_child(_pack_selector)

	_mode_status_label = Label.new()
	_mode_status_label.text = "Cursor free | Build view"
	_mode_status_label.add_theme_color_override("font_color", Color(0.72, 0.86, 1.0, 1.0))
	content.add_child(_mode_status_label)

	var net_panel := VBoxContainer.new()
	net_panel.add_theme_constant_override("separation", 6)
	content.add_child(net_panel)

	var net_row_1 := HBoxContainer.new()
	net_row_1.add_theme_constant_override("separation", 6)
	net_panel.add_child(net_row_1)

	var host_btn := Button.new()
	host_btn.text = "Host"
	host_btn.tooltip_text = "Start a session. Your friend joins your IP on port 7432."
	host_btn.pressed.connect(func(): host_requested.emit())
	net_row_1.add_child(host_btn)

	var disconnect_btn := Button.new()
	disconnect_btn.text = "Disconnect"
	disconnect_btn.pressed.connect(func(): disconnect_requested.emit())
	net_row_1.add_child(disconnect_btn)

	_net_status_label = Label.new()
	_net_status_label.text = "Offline"
	_net_status_label.modulate = Color(0.62, 0.62, 0.62)
	_net_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_net_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	net_row_1.add_child(_net_status_label)

	var net_row_2 := HBoxContainer.new()
	net_row_2.add_theme_constant_override("separation", 6)
	net_panel.add_child(net_row_2)

	_ip_input = LineEdit.new()
	_ip_input.placeholder_text = "Friend host IP"
	_ip_input.text = "127.0.0.1"
	_ip_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	net_row_2.add_child(_ip_input)

	var join_btn := Button.new()
	join_btn.text = "Join"
	join_btn.pressed.connect(func(): join_requested.emit(_ip_input.text.strip_edges()))
	net_row_2.add_child(join_btn)

	var file_row := HBoxContainer.new()
	file_row.add_theme_constant_override("separation", 6)
	content.add_child(file_row)

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.tooltip_text = "Editable save to res://saved_mazes/manual_maze.json"
	save_btn.pressed.connect(func(): save_requested.emit())
	file_row.add_child(save_btn)

	var export_btn := Button.new()
	export_btn.text = "Export Scene"
	export_btn.tooltip_text = "Create res://saved_mazes/manual_maze_built.tscn for use in Godot."
	export_btn.pressed.connect(func(): export_scene_requested.emit())
	file_row.add_child(export_btn)

	var load_btn := Button.new()
	load_btn.text = "Load"
	load_btn.pressed.connect(func(): load_requested.emit())
	file_row.add_child(load_btn)

	var clear_btn := Button.new()
	clear_btn.text = "Clear"
	clear_btn.pressed.connect(func(): clear_requested.emit())
	file_row.add_child(clear_btn)

	_test_toggle = CheckBox.new()
	_test_toggle.text = "Test view"
	_test_toggle.tooltip_text = "Run around the map with collision. Right click still deletes blocks."
	_test_toggle.toggled.connect(func(enabled: bool): test_mode_toggled.emit(enabled))
	file_row.add_child(_test_toggle)

	_status_label = Label.new()
	_status_label.text = "Pack:\nModel:\nGrid:\nRotation:\nScale:\nHeight:"
	content.add_child(_status_label)

	_help_label = Label.new()
	_help_label.text = "Click world or Capture = lock mouse | Esc = cursor\nBuild: WASD fly | LMB place | RMB delete | surface snap works\nTest view: WASD run | Shift sprint | Space jump | RMB delete\nHold X/Z height | Hold -/= fine scale | Shift = faster\nQ/E or 1-6 model | R rotate | [ ] grid | Home reset\nF5 save JSON | F6 export scene | F9 load | Delete clear"
	_help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_help_label)


func _on_pack_item_selected(index: int) -> void:
	pack_selected.emit(_pack_selector.get_item_text(index))
