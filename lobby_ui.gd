## lobby_ui.gd
## Co-op lobby: host/join panel + live 2-D grid editor that both players can edit
## together before the maze is built.  Attach to a Node child of the CanvasLayer.
extends Node

signal start_requested(rows: Array)   # emitted on host when Play is pressed
signal back_requested()               # emitted when user goes back to main menu

# ── tunables ─────────────────────────────────────────────────────────────────
const DEFAULT_COLS    := 15   # maze grid columns (odd numbers look best)
const DEFAULT_ROWS    := 13   # maze grid rows
const CELL_PX         := 28   # pixels per cell in the 2D editor
const WALL_COLOR      := Color(0.18, 0.17, 0.15, 1.0)
const PATH_COLOR      := Color(0.55, 0.52, 0.44, 1.0)
const START_COLOR     := Color(0.22, 0.78, 0.38, 1.0)
const EXIT_COLOR      := Color(0.82, 0.25, 0.22, 1.0)
const HOVER_COLOR     := Color(1.0, 0.85, 0.35, 0.55)
const GRID_BG         := Color(0.07, 0.07, 0.06, 0.96)
const PANEL_BG        := Color(0.025, 0.03, 0.028, 0.93)
const BORDER_COLOR    := Color(0.72, 0.62, 0.42, 0.62)

# ── runtime state ─────────────────────────────────────────────────────────────
var _canvas: CanvasLayer
var _root: Control
var _panel: Panel             # outer panel (host/join choice)
var _lobby_panel: Panel       # inner panel (grid editor + status)
var _grid_draw: Control       # custom-draw grid
var _status_label: Label
var _play_btn: Button
var _ip_field: LineEdit

var _grid_rows: Array[String] = []   # the shared maze map (strings of '#','.',…)
var _hover_cell := Vector2i(-1, -1)
var _is_paint_wall := true            # true = painting walls, false = erasing

func setup(canvas: CanvasLayer) -> void:
	_canvas = canvas
	_build_panels()
	_init_grid()

# ── Public API ────────────────────────────────────────────────────────────────

func show_lobby() -> void:
	_panel.visible      = true
	_lobby_panel.visible = false
	_root.visible       = true

func hide_lobby() -> void:
	_root.visible = false

## Returns current grid rows (for passing into MazeBuilder).
func get_grid() -> Array[String]:
	return _grid_rows

## Called when the NetworkManager says the grid snapshot arrived (client side).
func apply_snapshot(rows: Array) -> void:
	_grid_rows.clear()
	for r in rows:
		_grid_rows.append(str(r))
	_grid_draw.queue_redraw()

# ── Grid helpers ──────────────────────────────────────────────────────────────

func _init_grid() -> void:
	_grid_rows.clear()
	var cols := DEFAULT_COLS
	var rows := DEFAULT_ROWS
	for y in range(rows):
		var row := ""
		for x in range(cols):
			if x == 0 or y == 0 or x == cols - 1 or y == rows - 1:
				row += "#"          # outer border
			elif x == 1 and y == 1:
				row += "S"          # start
			elif x == cols - 2 and y == rows - 2:
				row += "E"          # exit
			else:
				row += "."          # open path by default
		_grid_rows.append(row)

func _get_cell(x: int, y: int) -> String:
	if y < 0 or y >= _grid_rows.size():
		return "#"
	if x < 0 or x >= _grid_rows[y].length():
		return "#"
	return _grid_rows[y][x]

func _set_cell(x: int, y: int, ch: String) -> void:
	if y < 0 or y >= _grid_rows.size():
		return
	if x < 0 or x >= _grid_rows[y].length():
		return
	# Protect start / exit markers
	var cur := _grid_rows[y][x]
	if cur == "S" or cur == "E":
		return
	var row := _grid_rows[y]
	_grid_rows[y] = row.left(x) + ch + row.substr(x + 1)

func _pixel_to_cell(px: Vector2) -> Vector2i:
	if _grid_rows.is_empty():
		return Vector2i(-1, -1)
	var cols := _grid_rows[0].length()
	var rows := _grid_rows.size()
	var grid_w := cols * CELL_PX
	var grid_h := rows * CELL_PX
	var offset_x := (_grid_draw.size.x - grid_w) * 0.5
	var offset_y := (_grid_draw.size.y - grid_h) * 0.5
	var cx := int((px.x - offset_x) / CELL_PX)
	var cy := int((px.y - offset_y) / CELL_PX)
	if cx < 0 or cy < 0 or cx >= cols or cy >= rows:
		return Vector2i(-1, -1)
	return Vector2i(cx, cy)

# ── UI building ───────────────────────────────────────────────────────────────

func _build_panels() -> void:
	_root = Control.new()
	_root.name = "LobbyRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_root.visible = false
	_canvas.add_child(_root)

	# ── dim overlay ──────────────────────────────────────────────────────────
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	# ── host/join panel ──────────────────────────────────────────────────────
	_panel = _make_styled_panel("LobbyConnPanel")
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left   = -240.0
	_panel.offset_top    = -180.0
	_panel.offset_right  =  240.0
	_panel.offset_bottom =  180.0
	_root.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 28; vbox.offset_top = 24; vbox.offset_right = -28; vbox.offset_bottom = -24
	vbox.add_theme_constant_override("separation", 14)
	_panel.add_child(vbox)

	_add_styled_label(vbox, "МУЛЬТИПЛЕЕР", 30, Color(0.95, 0.82, 0.48, 1.0))
	_add_styled_label(vbox, "Выберите роль:", 15, Color(0.78, 0.84, 0.76, 0.9))

	var host_btn := _make_button("🏠  Создать игру (Host)")
	host_btn.pressed.connect(_on_host_pressed)
	vbox.add_child(host_btn)

	_add_styled_label(vbox, "─── или подключиться ───", 13, Color(0.55, 0.55, 0.50, 0.7))

	var ip_row := HBoxContainer.new()
	ip_row.add_theme_constant_override("separation", 8)
	vbox.add_child(ip_row)

	_ip_field = LineEdit.new()
	_ip_field.placeholder_text = "IP адрес (напр. 192.168.1.5)"
	_ip_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ip_field.custom_minimum_size.y = 38
	_ip_field.add_theme_color_override("font_color", Color(0.9, 0.9, 0.85, 1.0))
	ip_row.add_child(_ip_field)

	var join_btn := _make_button("🔗 Войти")
	join_btn.custom_minimum_size = Vector2(90, 38)
	join_btn.pressed.connect(_on_join_pressed)
	ip_row.add_child(join_btn)

	var solo_btn := _make_button("👤  Одиночная игра")
	solo_btn.pressed.connect(_on_solo_pressed)
	vbox.add_child(solo_btn)

	var back_btn := _make_button("← Назад")
	back_btn.pressed.connect(_on_back_pressed)
	vbox.add_child(back_btn)

	# ── grid editor panel ────────────────────────────────────────────────────
	_lobby_panel = _make_styled_panel("LobbyEditorPanel")
	_lobby_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lobby_panel.offset_left = 40; _lobby_panel.offset_top = 30
	_lobby_panel.offset_right = -40; _lobby_panel.offset_bottom = -30
	_lobby_panel.visible = false
	_root.add_child(_lobby_panel)

	var editor_vbox := VBoxContainer.new()
	editor_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	editor_vbox.offset_left = 20; editor_vbox.offset_top = 16
	editor_vbox.offset_right = -20; editor_vbox.offset_bottom = -16
	editor_vbox.add_theme_constant_override("separation", 10)
	_lobby_panel.add_child(editor_vbox)

	_add_styled_label(editor_vbox, "РЕДАКТОР ЛАБИРИНТА", 22, Color(0.95, 0.82, 0.48, 1.0))

	_status_label = Label.new()
	_status_label.text = "Ожидание…"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6, 1.0))
	editor_vbox.add_child(_status_label)

	var hint := Label.new()
	hint.text = "ЛКМ = поставить стену  |  ПКМ = убрать стену  |  S = старт  |  E = выход"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.65, 0.65, 0.60, 0.85))
	editor_vbox.add_child(hint)

	# Grid draw container
	_grid_draw = Control.new()
	_grid_draw.name = "GridDraw"
	_grid_draw.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_grid_draw.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid_draw.draw.connect(_on_grid_draw)
	_grid_draw.gui_input.connect(_on_grid_input)
	_grid_draw.mouse_entered.connect(func(): _grid_draw.mouse_filter = Control.MOUSE_FILTER_STOP)
	editor_vbox.add_child(_grid_draw)

	var bottom_row := HBoxContainer.new()
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_row.add_theme_constant_override("separation", 16)
	editor_vbox.add_child(bottom_row)

	var reset_btn := _make_button("🔄 Сбросить")
	reset_btn.custom_minimum_size = Vector2(130, 40)
	reset_btn.pressed.connect(_on_reset_grid)
	bottom_row.add_child(reset_btn)

	_play_btn = _make_button("▶  Играть!")
	_play_btn.custom_minimum_size = Vector2(130, 40)
	_play_btn.disabled = true
	_play_btn.pressed.connect(_on_play_pressed)
	bottom_row.add_child(_play_btn)

	var leave_btn := _make_button("✕ Выйти")
	leave_btn.custom_minimum_size = Vector2(100, 40)
	leave_btn.pressed.connect(_on_leave_lobby)
	bottom_row.add_child(leave_btn)

# ── Draw ──────────────────────────────────────────────────────────────────────

func _on_grid_draw() -> void:
	if _grid_rows.is_empty():
		return
	var cols := _grid_rows[0].length()
	var rows := _grid_rows.size()
	var grid_w := cols * CELL_PX
	var grid_h := rows * CELL_PX
	var ox := int((_grid_draw.size.x - grid_w) * 0.5)
	var oy := int((_grid_draw.size.y - grid_h) * 0.5)

	# Background
	_grid_draw.draw_rect(Rect2(ox - 2, oy - 2, grid_w + 4, grid_h + 4), BORDER_COLOR)
	_grid_draw.draw_rect(Rect2(ox, oy, grid_w, grid_h), GRID_BG)

	for y in range(rows):
		for x in range(cols):
			var ch := _get_cell(x, y)
			var color: Color
			match ch:
				"#": color = WALL_COLOR
				"S": color = START_COLOR
				"E": color = EXIT_COLOR
				_:   color = PATH_COLOR

			var rect := Rect2(ox + x * CELL_PX + 1, oy + y * CELL_PX + 1, CELL_PX - 2, CELL_PX - 2)
			_grid_draw.draw_rect(rect, color)

			# Cell label for S/E
			if ch == "S" or ch == "E":
				_grid_draw.draw_string(
					ThemeDB.fallback_font,
					Vector2(ox + x * CELL_PX + 6, oy + y * CELL_PX + CELL_PX - 7),
					ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.9)
				)

	# Hover highlight
	if _hover_cell != Vector2i(-1, -1):
		var hx := _hover_cell.x; var hy := _hover_cell.y
		var hover_rect := Rect2(ox + hx * CELL_PX, oy + hy * CELL_PX, CELL_PX, CELL_PX)
		_grid_draw.draw_rect(hover_rect, HOVER_COLOR)

# ── Input ────────────────────────────────────────────────────────────────────

func _on_grid_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var cell := _pixel_to_cell(event.position)
		if cell != _hover_cell:
			_hover_cell = cell
			_grid_draw.queue_redraw()
	
	if event is InputEventMouseButton and event.pressed:
		var cell := _pixel_to_cell(event.position)
		if cell == Vector2i(-1, -1):
			return
		var ch := "#" if event.button_index == MOUSE_BUTTON_LEFT else "."
		_apply_cell_change(cell.x, cell.y, ch)

func _apply_cell_change(x: int, y: int, ch: String) -> void:
	_set_cell(x, y, ch)
	_grid_draw.queue_redraw()
	# Sync to peers
	if NetworkManager.is_online:
		_rpc_set_cell.rpc(x, y, ch)

# ── RPC ──────────────────────────────────────────────────────────────────────

@rpc("any_peer", "reliable")
func _rpc_set_cell(x: int, y: int, ch: String) -> void:
	_set_cell(x, y, ch)
	_grid_draw.queue_redraw()

@rpc("authority", "reliable")
func _rpc_receive_snapshot(rows: Array) -> void:
	apply_snapshot(rows)
	_grid_draw.queue_redraw()

func _send_snapshot_to(peer_id: int) -> void:
	var plain_rows: Array = []
	for r in _grid_rows:
		plain_rows.append(r)
	_rpc_receive_snapshot.rpc_id(peer_id, plain_rows)

# ── Button handlers ───────────────────────────────────────────────────────────

func _on_host_pressed() -> void:
	var err := NetworkManager.create_server()
	if err != OK:
		_show_error("Не удалось создать сервер (порт %d занят?)" % NetworkManager.DEFAULT_PORT)
		return
	_panel.visible = false
	_lobby_panel.visible = true
	_status_label.text = "Ожидание второго игрока…  Порт: %d" % NetworkManager.DEFAULT_PORT
	_play_btn.disabled = false   # host can start solo too
	NetworkManager.player_connected.connect(_on_remote_player_connected)
	NetworkManager.player_disconnected.connect(_on_remote_player_disconnected)

func _on_join_pressed() -> void:
	var ip := _ip_field.text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"
	var err := NetworkManager.join_server(ip)
	if err != OK:
		_show_error("Не удалось подключиться к %s" % ip)
		return
	_panel.visible = false
	_lobby_panel.visible = true
	_status_label.text = "Подключение к %s…" % ip
	_play_btn.disabled = true   # client cannot start the game
	NetworkManager.player_connected.connect(_on_remote_player_connected)
	NetworkManager.player_disconnected.connect(_on_remote_player_disconnected)
	# Listen for grid snapshot
	NetworkManager.grid_snapshot_received.connect(_on_snapshot_received)

func _on_solo_pressed() -> void:
	# Just start without any network
	_panel.visible = false
	_lobby_panel.visible = true
	_status_label.text = "Одиночная игра"
	_play_btn.disabled = false

func _on_back_pressed() -> void:
	back_requested.emit()
	hide_lobby()

func _on_leave_lobby() -> void:
	NetworkManager.disconnect_network()
	_lobby_panel.visible = false
	_panel.visible = true
	_init_grid()
	_grid_draw.queue_redraw()

func _on_reset_grid() -> void:
	_init_grid()
	_grid_draw.queue_redraw()
	if NetworkManager.is_online and multiplayer.is_server():
		var plain: Array = []
		for r in _grid_rows:
			plain.append(r)
		_rpc_receive_snapshot.rpc(plain)

func _on_play_pressed() -> void:
	start_requested.emit(_grid_rows)

# ── Network callbacks ─────────────────────────────────────────────────────────

func _on_remote_player_connected(peer_id: int) -> void:
	_status_label.text = "Игрок подключён ✓  (id=%d)" % peer_id
	# Host sends current grid to the new peer
	if multiplayer.is_server():
		_send_snapshot_to(peer_id)

func _on_remote_player_disconnected(_peer_id: int) -> void:
	_status_label.text = "Игрок отключился"

func _on_snapshot_received(rows: Array) -> void:
	apply_snapshot(rows)

# ── Helper UI factories ───────────────────────────────────────────────────────

func _make_styled_panel(panel_name: String) -> Panel:
	var p := Panel.new()
	p.name = panel_name
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = BORDER_COLOR
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_border_width(side, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	p.add_theme_stylebox_override("panel", style)
	return p

func _make_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 42)
	return b

func _add_styled_label(parent: Control, text: String, size: int, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)

func _show_error(msg: String) -> void:
	_status_label.text = "⚠ " + msg
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3, 1.0))
