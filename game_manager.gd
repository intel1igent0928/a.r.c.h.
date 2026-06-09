extends Node

const START_TITLE = "A.R.C.H."
const START_TEXT = "Find the gate key, read the notes, and leave the maze before the thing learns your route."

var key_found := false
var exit_open := false
var notes_found := 0
var relic_found := false
var game_started := false
var game_over := false
var threat := 0.0

var _canvas: CanvasLayer
var _root_ui: Control
var _menu_panel: Panel
var _pause_panel: Panel
var _end_panel: Panel
var _settings_panel: Panel
var _objective_label: Label
var _note_label: Label
var _fear_overlay: ColorRect
var _monster: Node
var _player: Node

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_input()
	_canvas = get_tree().root.find_child("CanvasLayer", true, false) as CanvasLayer
	_player = get_tree().root.find_child("Player", true, false)
	_monster = get_tree().root.find_child("Monster", true, false)
	_build_ui()
	call_deferred("_show_start")

func _process(delta: float):
	threat = max(threat - delta * 0.02, 0.0)
	if _fear_overlay:
		var target_alpha = clamp(threat * 0.22, 0.0, 0.46)
		_fear_overlay.color.a = lerp(_fear_overlay.color.a, target_alpha, delta * 3.0)
	_sync_mouse_mode()

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		if not game_started or game_over:
			return
		_toggle_pause()

func start_game():
	game_started = true
	game_over = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_set_ui_interactive(false)
	_menu_panel.visible = false
	_pause_panel.visible = false
	_end_panel.visible = false
	_settings_panel.visible = false
	_update_objective()
	if _monster and _monster.has_method("set_active"):
		_monster.set_active(true)

func register_pickup(item_name: String, points: int, dangerous: bool, description: String):
	var lower = item_name.to_lower()
	if lower.contains("key"):
		key_found = true
		_show_note("The gate key feels warm. Something knows you took it.")
	elif lower.contains("note"):
		notes_found += 1
		_show_note(description if not description.is_empty() else "A note points toward the old inner halls.")
	elif lower.contains("relic"):
		relic_found = true
		threat += 1.2
		_show_note("The relic hums like it is laughing.")
	elif lower.contains("battery"):
		_show_note("Battery secured. Keep the light alive.")

	if dangerous:
		threat += 0.85
		if _monster and _monster.has_method("alert_to_player"):
			_monster.alert_to_player()

	_update_objective()

func register_flashlight():
	_show_note("Flashlight online. Shadows are less honest now.")
	_update_objective()

func try_exit() -> bool:
	if key_found:
		win_game()
		return true

	_show_note("The gate is locked. Find the key inside the maze.")
	threat += 0.35
	return false

func win_game():
	if game_over:
		return
	game_over = true
	exit_open = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_set_ui_interactive(true)
	_show_end("YOU ESCAPED", "You found the key and left the maze with %d note(s). The morning looks fake, but it is yours." % notes_found)

func kill_player(reason := "The monster caught you."):
	if game_over:
		return
	game_over = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_set_ui_interactive(true)
	_show_end("YOU DIED", reason)

func scare_pulse(amount := 0.6):
	threat += amount

func _show_start():
	game_started = false
	game_over = false
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_set_ui_interactive(true)
	_menu_panel.visible = true
	_pause_panel.visible = false
	_end_panel.visible = false
	_settings_panel.visible = false

func _toggle_pause():
	var paused = not get_tree().paused
	get_tree().paused = paused
	_pause_panel.visible = paused
	if not paused:
		_settings_panel.visible = false
	_set_ui_interactive(paused)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED)

func _update_objective():
	if not _objective_label:
		return
	var key_text = "key: found" if key_found else "key: missing"
	var exit_text = "exit: ready" if key_found else "exit: locked"
	_objective_label.text = "%s | notes: %d | %s" % [key_text, notes_found, exit_text]

func _show_note(text: String):
	if not _note_label:
		return
	_note_label.text = text
	_note_label.modulate.a = 1.0
	var tween = _note_label.create_tween()
	tween.tween_interval(4.0)
	tween.tween_property(_note_label, "modulate:a", 0.0, 1.2)

func _show_end(title: String, body: String):
	_end_panel.visible = true
	var title_label = _end_panel.get_node("VBox/Title") as Label
	var body_label = _end_panel.get_node("VBox/Body") as Label
	title_label.text = title
	body_label.text = body

func _build_ui():
	if not _canvas:
		return

	_root_ui = Control.new()
	_root_ui.name = "GameUI"
	_root_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	_root_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(_root_ui)

	_fear_overlay = ColorRect.new()
	_fear_overlay.name = "FearOverlay"
	_fear_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fear_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fear_overlay.color = Color(0.42, 0.02, 0.04, 0.0)
	_root_ui.add_child(_fear_overlay)

	_objective_label = Label.new()
	_objective_label.name = "ObjectiveLabel"
	_objective_label.offset_left = 24.0
	_objective_label.offset_top = 122.0
	_objective_label.offset_right = 620.0
	_objective_label.offset_bottom = 152.0
	_objective_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objective_label.add_theme_color_override("font_color", Color(0.86, 0.92, 0.82, 0.94))
	_root_ui.add_child(_objective_label)

	_note_label = Label.new()
	_note_label.name = "NoteLabel"
	_note_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_note_label.offset_left = -330.0
	_note_label.offset_top = 90.0
	_note_label.offset_right = 330.0
	_note_label.offset_bottom = 160.0
	_note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_note_label.modulate.a = 0.0
	_note_label.add_theme_font_size_override("font_size", 18)
	_note_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.62, 1.0))
	_root_ui.add_child(_note_label)

	_menu_panel = _make_panel("StartMenu", "VBox")
	_add_title(_menu_panel, START_TITLE)
	_add_body(_menu_panel, START_TEXT)
	_add_button(_menu_panel, "Start", start_game)
	_add_button(_menu_panel, "Settings", _show_settings)
	_add_button(_menu_panel, "Quit", _quit_game)

	_pause_panel = _make_panel("PauseMenu", "VBox")
	_add_title(_pause_panel, "PAUSED")
	_add_button(_pause_panel, "Resume", _toggle_pause)
	_add_button(_pause_panel, "Settings", _show_settings)
	_add_button(_pause_panel, "Main Menu", _show_start)
	_pause_panel.visible = false

	_end_panel = _make_panel("EndScreen", "VBox")
	_add_title(_end_panel, "END")
	_add_body(_end_panel, "")
	_add_button(_end_panel, "Main Menu", _show_start)
	_end_panel.visible = false

	_settings_panel = _make_panel("Settings", "VBox")
	_add_title(_settings_panel, "SETTINGS")
	_add_body(_settings_panel, "V toggles camera, F toggles flashlight, Esc pauses.")
	_add_slider(_settings_panel, "Volume", 0.0, 1.0, 0.72, _set_volume)
	_add_slider(_settings_panel, "Mouse", 0.0008, 0.006, 0.0024, _set_mouse_sensitivity)
	_add_button(_settings_panel, "Back", _hide_settings)
	_settings_panel.visible = false

	_update_objective()

func _make_panel(node_name: String, box_name: String) -> Panel:
	var panel = Panel.new()
	panel.name = node_name
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -260.0
	panel.offset_top = -170.0
	panel.offset_right = 260.0
	panel.offset_bottom = 170.0
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.03, 0.028, 0.91)
	style.border_color = Color(0.72, 0.62, 0.42, 0.62)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)
	_root_ui.add_child(panel)

	var box = VBoxContainer.new()
	box.name = box_name
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 28.0
	box.offset_top = 28.0
	box.offset_right = -28.0
	box.offset_bottom = -28.0
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	return panel

func _add_title(panel: Panel, text: String):
	var label = Label.new()
	label.name = "Title"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.48, 1.0))
	panel.get_child(0).add_child(label)

func _add_body(panel: Panel, text: String):
	var label = Label.new()
	label.name = "Body"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.78, 0.84, 0.76, 1.0))
	panel.get_child(0).add_child(label)

func _add_button(panel: Panel, text: String, callback: Callable):
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 42.0)
	button.pressed.connect(callback)
	panel.get_child(0).add_child(button)

func _add_slider(panel: Panel, label_text: String, min_value: float, max_value: float, value: float, callback: Callable):
	var label = Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", Color(0.86, 0.90, 0.78, 1.0))
	panel.get_child(0).add_child(label)
	var slider = HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = 0.01 if max_value > 0.1 else 0.0001
	slider.value = value
	slider.value_changed.connect(callback)
	panel.get_child(0).add_child(slider)

func _set_volume(value: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(max(value, 0.001)))

func _set_mouse_sensitivity(value: float):
	if _player:
		_player.set("mouse_sensitivity", value)

func _show_settings():
	_settings_panel.visible = true
	_set_ui_interactive(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _hide_settings():
	_settings_panel.visible = false
	_sync_mouse_mode()

func _quit_game():
	get_tree().quit()

func _ensure_input():
	if not InputMap.has_action("ui_cancel"):
		InputMap.add_action("ui_cancel")
	if InputMap.action_get_events("ui_cancel").is_empty():
		var event = InputEventKey.new()
		event.physical_keycode = KEY_ESCAPE
		event.keycode = KEY_ESCAPE
		InputMap.action_add_event("ui_cancel", event)

func is_playing() -> bool:
	return game_started and not game_over and not get_tree().paused and not _settings_panel.visible

func _sync_mouse_mode():
	if not game_started or game_over or get_tree().paused or _settings_panel.visible:
		_set_ui_interactive(true)
		if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		_set_ui_interactive(false)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _set_ui_interactive(interactive: bool):
	if _root_ui:
		_root_ui.mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	for panel in [_menu_panel, _pause_panel, _end_panel, _settings_panel]:
		if panel:
			panel.mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
