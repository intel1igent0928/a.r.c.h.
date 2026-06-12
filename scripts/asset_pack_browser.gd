extends CanvasLayer

signal pack_selected(pack_name: String)

var _pack_selector: OptionButton
var _status_label: Label
var _help_label: Label


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


func _build_ui() -> void:
	if _pack_selector != null:
		return

	var root := VBoxContainer.new()
	root.name = "BuilderUI"
	root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root.position = Vector2(16, 16)
	root.custom_minimum_size = Vector2(360, 0)
	add_child(root)

	var panel := PanelContainer.new()
	root.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var title := Label.new()
	title.text = "Manual Maze Builder"
	content.add_child(title)

	var pack_row := HBoxContainer.new()
	content.add_child(pack_row)

	var pack_label := Label.new()
	pack_label.text = "Pack"
	pack_label.custom_minimum_size = Vector2(58, 0)
	pack_row.add_child(pack_label)

	_pack_selector = OptionButton.new()
	_pack_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pack_selector.item_selected.connect(_on_pack_item_selected)
	pack_row.add_child(_pack_selector)

	_status_label = Label.new()
	_status_label.text = "Pack:\nModel:\nGrid:\nRotation:\nScale:"
	content.add_child(_status_label)

	_help_label = Label.new()
	_help_label.text = "WASD fly | Space up | Ctrl down | Shift fast | Esc mouse\nLMB place | RMB delete\nQ/E model | 1-6 quick model | R rotate\n[ ] grid | - = scale | Backspace reset scale\nX/Z height | Home reset height\nF5 save | F9 load | Delete clear"
	content.add_child(_help_label)


func _on_pack_item_selected(index: int) -> void:
	pack_selected.emit(_pack_selector.get_item_text(index))
