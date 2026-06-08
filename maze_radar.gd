extends Control

@export var maze_builder_path: NodePath
@export var player_path: NodePath
@export var intro_duration = 7.0

var intro_timer = 0.0
var _maze_builder: Node
var _player: Node3D

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_timer = intro_duration
	_maze_builder = get_node_or_null(maze_builder_path)
	_player = get_node_or_null(player_path) as Node3D
	set_anchors_preset(Control.PRESET_FULL_RECT)

func _process(delta: float):
	intro_timer = max(intro_timer - delta, 0.0)
	queue_redraw()

func _draw():
	if not _maze_builder or not _maze_builder.has_method("get_radar_grid"):
		return

	var grid: Array[String] = _maze_builder.get_radar_grid()
	if grid.is_empty():
		return

	var viewport_size = get_viewport_rect().size
	var panel = _get_panel_rect(viewport_size)
	draw_rect(panel, Color(0.015, 0.018, 0.018, 0.74), true)
	draw_rect(panel, Color(0.4, 0.62, 0.58, 0.55), false, 2.0)

	var rows = grid.size()
	var columns = grid[0].length()
	var cell = min(panel.size.x / float(columns), panel.size.y / float(rows))
	var map_size = Vector2(columns * cell, rows * cell)
	var map_origin = panel.position + (panel.size - map_size) * 0.5

	for y in range(rows):
		for x in range(columns):
			var marker = grid[y].substr(x, 1)
			var rect = Rect2(map_origin + Vector2(x * cell, y * cell), Vector2(cell, cell))
			if marker == "#":
				draw_rect(rect, Color(0.44, 0.47, 0.43, 0.95), true)
			elif marker == "R":
				draw_rect(rect.grow(-cell * 0.08), Color(0.15, 0.22, 0.18, 0.88), true)
			elif marker == ".":
				draw_rect(rect.grow(-cell * 0.18), Color(0.08, 0.10, 0.09, 0.55), true)
			elif marker == "E":
				draw_rect(rect.grow(-cell * 0.18), Color(0.17, 0.85, 0.48, 0.92), true)
			elif marker == "S":
				draw_rect(rect.grow(-cell * 0.2), Color(0.42, 0.68, 1.0, 0.85), true)
			elif marker == "L":
				draw_rect(rect.grow(-cell * 0.1), Color(0.18, 0.16, 0.11, 0.74), true)
				draw_circle(rect.get_center(), max(cell * 0.28, 2.0), Color(1.0, 0.62, 0.24, 0.95))
			elif marker == "F":
				draw_circle(rect.get_center(), max(cell * 0.26, 2.0), Color(1.0, 0.82, 0.32, 0.96))
			elif marker == "B":
				draw_circle(rect.get_center(), max(cell * 0.26, 2.0), Color(0.16, 0.95, 0.45, 0.96))
			elif marker == "A":
				draw_circle(rect.get_center(), max(cell * 0.3, 2.0), Color(1.0, 0.12, 0.18, 0.96))
			elif marker == "K":
				draw_rect(rect.grow(-cell * 0.28), Color(1.0, 0.68, 0.16, 0.96), true)
			elif marker == "N":
				draw_rect(rect.grow(-cell * 0.32), Color(0.92, 0.72, 0.36, 0.88), true)

	if _player and _maze_builder.has_method("world_to_grid"):
		var player_grid: Vector2i = _maze_builder.world_to_grid(_player.global_position)
		var player_center = map_origin + Vector2((player_grid.x + 0.5) * cell, (player_grid.y + 0.5) * cell)
		draw_circle(player_center, max(cell * 0.46, 3.5), Color(1.0, 0.18, 0.26, 0.98))
		var forward = Vector2(-sin(_player.global_rotation.y), -cos(_player.global_rotation.y))
		draw_line(player_center, player_center + forward * cell * 1.2, Color(1.0, 0.82, 0.5, 0.95), max(cell * 0.16, 2.0))

func _get_panel_rect(viewport_size: Vector2) -> Rect2:
	if intro_timer > 0.0:
		var width = min(viewport_size.x * 0.82, 760.0)
		var height = min(viewport_size.y * 0.78, 560.0)
		return Rect2((viewport_size - Vector2(width, height)) * 0.5, Vector2(width, height))

	var size = Vector2(210, 160)
	var margin = 24.0
	return Rect2(Vector2(viewport_size.x - size.x - margin, margin), size)
