extends Node3D

const WALL = "#"
const PATH = "."
const START = "S"
const EXIT = "E"
const ROOM = "R"
const LANDMARK = "L"
const FLASHLIGHT_MARKER = "F"
const BATTERY_MARKER = "B"
const ARTIFACT_MARKER = "A"
const KEY_MARKER = "K"
const NOTE_MARKER = "N"

@export var player_path: NodePath
@export var maze_cells_x = 14
@export var maze_cells_y = 12
@export var cell_size = 6.4
@export var min_wall_height = 7.5
@export var max_wall_height = 11.5
@export var branch_rate = 0.90
@export var maze_seed = 1842
@export var extra_loops = 11
@export var dead_end_spurs = 18
@export var room_count = 5
@export var landmark_count = 12
@export var max_dead_end_length = 8
@export var dead_end_removal_rate = 0.0
@export var obstacle_chance = 0.24
@export var wall_uv_scale = Vector3(0.42, 0.42, 0.42)
@export var floor_uv_scale = Vector3(0.34, 0.34, 0.34)

var radar_grid: Array[String] = []
var start_grid = Vector2i.ZERO
var exit_grid = Vector2i.ZERO
var world_origin = Vector3.ZERO

var pickup_cells := {}
var room_cells := {}
var cave_cells := {}
var landmark_cells: Array[Vector2i] = []
var note_cells: Array[Vector2i] = []
var monster_spawn_grid = Vector2i.ZERO

var _maze_root: Node3D

func _ready():
	_remove_test_arena()
	_generate_maze()
	_build_geometry()
	_build_obstacles()
	_build_lights()
	_place_player()
	_place_pickups()

func get_radar_grid() -> Array[String]:
	return radar_grid

func world_to_grid(world_position: Vector3) -> Vector2i:
	if radar_grid.is_empty():
		return Vector2i.ZERO
	var local_x = int(round((world_position.x - world_origin.x) / cell_size))
	var local_z = int(round((world_position.z - world_origin.z) / cell_size))
	return Vector2i(clamp(local_x, 0, radar_grid[0].length() - 1), clamp(local_z, 0, radar_grid.size() - 1))

func grid_to_world(grid_position: Vector2i, y = 0.0) -> Vector3:
	return world_origin + Vector3(grid_position.x * cell_size, y, grid_position.y * cell_size)

func find_path_world(from_world: Vector3, to_world: Vector3) -> Array[Vector3]:
	var start = world_to_grid(from_world)
	var goal = world_to_grid(to_world)
	var grid_path = _find_grid_path(start, goal)
	var world_path: Array[Vector3] = []
	for cell in grid_path:
		world_path.append(grid_to_world(cell, 0.05))
	return world_path

func get_monster_patrol_point(from_world: Vector3) -> Vector3:
	var candidates: Array[Vector2i] = []
	for cell in landmark_cells:
		candidates.append(cell)
	for cell in note_cells:
		candidates.append(cell)
	if candidates.is_empty():
		candidates = _get_walkable_cells(radar_grid)
	var from_grid = world_to_grid(from_world)
	var best = exit_grid
	var best_score = -INF
	for cell in candidates:
		var score = _grid_distance_squared(cell, from_grid) + _grid_distance_squared(cell, start_grid) * 0.25
		if score > best_score:
			best_score = score
			best = cell
	return grid_to_world(best, 0.05)

func _generate_maze():
	room_cells.clear()
	cave_cells.clear()
	landmark_cells.clear()
	note_cells.clear()
	pickup_cells.clear()

	var grid_w = maze_cells_x * 2 + 1
	var grid_h = maze_cells_y * 2 + 1
	start_grid = Vector2i(1, 1)
	exit_grid = Vector2i(grid_w - 2, grid_h - 2)

	var rows: Array[String] = []
	for y in range(grid_h):
		var row = ""
		for x in range(grid_w):
			row += WALL
		rows.append(row)

	var rng = RandomNumberGenerator.new()
	rng.seed = maze_seed
	var visited := {}
	var active: Array[Vector2i] = []
	active.append(Vector2i.ZERO)
	visited[Vector2i.ZERO] = true
	_set_cell(rows, start_grid, PATH)

	while not active.is_empty():
		var idx = active.size() - 1
		if rng.randf() < branch_rate:
			idx = rng.randi_range(0, active.size() - 1)

		var current = active[idx]
		var options: Array[Vector2i] = []
		for dir in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var next = current + dir
			if next.x < 0 or next.y < 0 or next.x >= maze_cells_x or next.y >= maze_cells_y:
				continue
			if not visited.has(next):
				options.append(dir)

		if options.is_empty():
			active.remove_at(idx)
			continue

		var carve_dir = options[rng.randi_range(0, options.size() - 1)]
		var next_cell = current + carve_dir
		var current_grid = _cell_to_grid(current)
		var next_grid = _cell_to_grid(next_cell)
		var between = Vector2i(int((current_grid.x + next_grid.x) / 2), int((current_grid.y + next_grid.y) / 2))
		_set_cell(rows, between, PATH)
		_set_cell(rows, next_grid, PATH)
		visited[next_cell] = true
		active.append(next_cell)

	_add_extra_loops(rows, rng, extra_loops)
	_set_cell(rows, start_grid, START)
	_set_cell(rows, exit_grid, EXIT)
	_carve_story_rooms(rows, rng)
	_carve_cave_sector(rows, rng)
	_add_dead_end_spurs(rows, rng, dead_end_spurs)
	_prune_dead_ends(rows, max_dead_end_length, rng)
	_ensure_connection(rows, start_grid, exit_grid)
	_select_pickup_cells(rows, rng)
	_select_gameplay_cells(rows, rng)
	_select_landmarks(rows, rng)
	_mark_special_cells(rows)
	_ensure_required_connectivity(rows)
	_validate_generated_map(rows)

	radar_grid = rows
	world_origin = Vector3(-float(grid_w - 1) * cell_size * 0.5, 0.0, -float(grid_h - 1) * cell_size * 0.5)

func _add_extra_loops(rows: Array[String], rng: RandomNumberGenerator, loop_count: int):
	if maze_cells_x < 2 or maze_cells_y < 2:
		return

	for i in range(loop_count):
		var cx = rng.randi_range(0, maze_cells_x - 1)
		var cy = rng.randi_range(0, maze_cells_y - 1)
		var dirs: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
		_shuffle_cells(dirs, rng)
		var a = _cell_to_grid(Vector2i(cx, cy))

		for dir in dirs:
			var logical_b = Vector2i(cx, cy) + dir
			if logical_b.x < 0 or logical_b.y < 0 or logical_b.x >= maze_cells_x or logical_b.y >= maze_cells_y:
				continue
			var b = _cell_to_grid(logical_b)
			var between = Vector2i(int((a.x + b.x) / 2), int((a.y + b.y) / 2))
			if _get_cell(rows, between) == WALL:
				_set_cell(rows, between, PATH)
				break

func _carve_story_rooms(rows: Array[String], rng: RandomNumberGenerator):
	var candidates = _get_walkable_cells(rows)
	_shuffle_cells(candidates, rng)

	var selected: Array[Vector2i] = []
	var made = 0
	for center in candidates:
		if made >= room_count:
			break
		if center.x <= 2 or center.y <= 2 or center.x >= rows[0].length() - 3 or center.y >= rows.size() - 3:
			continue
		if center.distance_to(start_grid) < 4.0 or center.distance_to(exit_grid) < 4.0:
			continue
		var too_close = false
		for other in selected:
			if center.distance_to(other) < 6.0:
				too_close = true
				break
		if too_close:
			continue

		var half_w = 1
		var half_h = 1
		if rng.randf() < 0.28:
			if rng.randf() < 0.5:
				half_w = 2
			else:
				half_h = 2
		_carve_room(rows, center, half_w, half_h)
		selected.append(center)
		made += 1

	# Small pads make start and exit readable without opening the outer border.
	_carve_room(rows, start_grid, 1, 1)
	_carve_room(rows, exit_grid, 1, 1)
	_set_cell(rows, start_grid, START)
	_set_cell(rows, exit_grid, EXIT)

func _carve_room(rows: Array[String], center: Vector2i, half_w: int, half_h: int):
	var min_x = max(1, center.x - half_w)
	var max_x = min(rows[0].length() - 2, center.x + half_w)
	var min_y = max(1, center.y - half_h)
	var max_y = min(rows.size() - 2, center.y + half_h)

	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var pos = Vector2i(x, y)
			if pos == start_grid or pos == exit_grid:
				continue
			_set_cell(rows, pos, ROOM)
			room_cells[pos] = true

func _carve_cave_sector(rows: Array[String], rng: RandomNumberGenerator):
	var desired_center = Vector2i(int(rows[0].length() * 0.52), int(rows.size() * 0.50))
	var center = _find_reachable_cell_near(rows, desired_center, {}, 4)
	if center == start_grid:
		center = desired_center

	var radius_x = 5
	var radius_y = 4
	var min_x = clamp(center.x - radius_x, 2, rows[0].length() - 4)
	var max_x = clamp(center.x + radius_x, 3, rows[0].length() - 3)
	var min_y = clamp(center.y - radius_y, 2, rows.size() - 4)
	var max_y = clamp(center.y + radius_y, 3, rows.size() - 3)

	center = Vector2i(int((min_x + max_x) * 0.5), int((min_y + max_y) * 0.5))
	var left_gate = Vector2i(min_x, center.y)
	var right_gate = Vector2i(max_x, center.y + rng.randi_range(-1, 1))
	var upper_gate = Vector2i(center.x + rng.randi_range(-1, 1), min_y)
	var lower_gate = Vector2i(center.x + rng.randi_range(-1, 1), max_y)

	_carve_cave_wander(rows, left_gate, center, rng, Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1)))
	_carve_cave_wander(rows, center, right_gate, rng, Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1)))
	_carve_cave_wander(rows, upper_gate, center + Vector2i(rng.randi_range(-2, 2), rng.randi_range(-1, 1)), rng, Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1)))
	_carve_cave_wander(rows, lower_gate, center + Vector2i(rng.randi_range(-2, 2), rng.randi_range(-1, 1)), rng, Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1)))

	var pockets = [
		center,
		center + Vector2i(-3, -2),
		center + Vector2i(3, 2),
		center + Vector2i(-2, 2),
		center + Vector2i(2, -2),
	]
	for pocket in pockets:
		_carve_cave_pocket(rows, pocket, rng)

	_ensure_connection(rows, start_grid, center)
	_ensure_connection(rows, center, exit_grid)

func _carve_cave_wander(rows: Array[String], from_cell: Vector2i, to_cell: Vector2i, rng: RandomNumberGenerator, bounds: Rect2i):
	var current = _clamp_to_rect(from_cell, bounds)
	var target = _clamp_to_rect(to_cell, bounds)
	var guard = bounds.size.x * bounds.size.y * 2
	_carve_cave_cell(rows, current)

	while current != target and guard > 0:
		guard -= 1
		var step = Vector2i.ZERO
		if current.x != target.x and (current.y == target.y or rng.randf() < 0.58):
			step.x = 1 if target.x > current.x else -1
		elif current.y != target.y:
			step.y = 1 if target.y > current.y else -1
		current = _clamp_to_rect(current + step, bounds)
		_carve_cave_cell(rows, current)

		if rng.randf() < 0.38:
			var side = Vector2i(-step.y, step.x)
			if side == Vector2i.ZERO:
				side = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP][rng.randi_range(0, 3)]
			_carve_cave_cell(rows, _clamp_to_rect(current + side, bounds))

func _carve_cave_pocket(rows: Array[String], center: Vector2i, rng: RandomNumberGenerator):
	for y in range(-1, 2):
		for x in range(-1, 2):
			var pos = center + Vector2i(x, y)
			if pos.x <= 1 or pos.y <= 1 or pos.x >= rows[0].length() - 2 or pos.y >= rows.size() - 2:
				continue
			if abs(x) + abs(y) > 2:
				continue
			if abs(x) == 1 and abs(y) == 1 and rng.randf() < 0.55:
				continue
			_carve_cave_cell(rows, pos)

func _carve_cave_cell(rows: Array[String], cell: Vector2i):
	if cell == start_grid or cell == exit_grid:
		return
	_set_cell(rows, cell, ROOM)
	room_cells[cell] = true
	cave_cells[cell] = true

func _clamp_to_rect(cell: Vector2i, rect: Rect2i) -> Vector2i:
	return Vector2i(
		clamp(cell.x, rect.position.x, rect.position.x + rect.size.x - 1),
		clamp(cell.y, rect.position.y, rect.position.y + rect.size.y - 1)
	)

func _add_dead_end_spurs(rows: Array[String], rng: RandomNumberGenerator, spur_count: int):
	var attempts = spur_count * 12
	var made = 0
	while made < spur_count and attempts > 0:
		attempts -= 1
		var candidates = _get_walkable_cells(rows)
		if candidates.is_empty():
			return
		var base = candidates[rng.randi_range(0, candidates.size() - 1)]
		if base.distance_to(start_grid) < 5.0 or base.distance_to(exit_grid) < 5.0:
			continue
		if room_cells.has(base) or pickup_cells.values().has(base):
			continue

		var dirs: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
		_shuffle_cells(dirs, rng)
		for dir in dirs:
			var first = base + dir
			if _get_cell(rows, first) != WALL:
				continue
			var length = rng.randi_range(2, 5)
			var carved: Array[Vector2i] = []
			var current = base
			var valid = true
			for i in range(length):
				current += dir
				if current.x <= 0 or current.y <= 0 or current.x >= rows[0].length() - 1 or current.y >= rows.size() - 1:
					valid = false
					break
				if _get_cell(rows, current) != WALL:
					valid = false
					break
				carved.append(current)
				if i > 0 and _count_path_neighbors(rows, current) > 0:
					valid = false
					break
			if not valid or carved.is_empty():
				continue
			for cell in carved:
				_set_cell(rows, cell, PATH)
			made += 1
			break

func _select_pickup_cells(rows: Array[String], rng: RandomNumberGenerator):
	var reserved := {}
	reserved[start_grid] = true
	reserved[exit_grid] = true

	var flashlight = _find_reachable_cell_near(rows, start_grid + Vector2i(2, 0), reserved, 1)
	pickup_cells["flashlight"] = flashlight
	reserved[flashlight] = true

	var distances = _get_distance_map(rows, start_grid)
	var max_dist = 0
	for key in distances.keys():
		max_dist = max(max_dist, int(distances[key]))

	var battery = _choose_cell_by_route_distance(rows, distances, int(max_dist * 0.36), int(max_dist * 0.66), reserved, rng)
	if battery == Vector2i(-1, -1):
		battery = _find_reachable_cell_near(rows, Vector2i(int(rows[0].length() / 2), int(rows.size() / 2)), reserved, 4)
	pickup_cells["battery"] = battery
	reserved[battery] = true

	var artifact = _find_reachable_cell_near(rows, exit_grid + Vector2i(-2, 0), reserved, max(4, int(max_dist * 0.68)))
	pickup_cells["artifact"] = artifact

func _select_gameplay_cells(rows: Array[String], rng: RandomNumberGenerator):
	var reserved := {}
	reserved[start_grid] = true
	reserved[exit_grid] = true
	for cell in pickup_cells.values():
		reserved[cell] = true

	var distances = _get_distance_map(rows, start_grid)
	var max_dist = 0
	for key in distances.keys():
		max_dist = max(max_dist, int(distances[key]))

	var key_cell = _choose_cell_by_route_distance(rows, distances, int(max_dist * 0.50), int(max_dist * 0.78), reserved, rng)
	if key_cell == Vector2i(-1, -1):
		key_cell = _find_reachable_cell_near(rows, exit_grid + Vector2i(-4, -2), reserved, int(max_dist * 0.45))
	pickup_cells["key"] = key_cell
	reserved[key_cell] = true

	note_cells.clear()
	var note_ranges = [
		Vector2i(int(max_dist * 0.16), int(max_dist * 0.32)),
		Vector2i(int(max_dist * 0.34), int(max_dist * 0.52)),
		Vector2i(int(max_dist * 0.62), int(max_dist * 0.86)),
	]
	for route_range in note_ranges:
		var note_cell = _choose_cell_by_route_distance(rows, distances, route_range.x, route_range.y, reserved, rng)
		if note_cell == Vector2i(-1, -1):
			note_cell = _find_reachable_cell_near(rows, start_grid + Vector2i(rng.randi_range(2, rows[0].length() - 3), rng.randi_range(2, rows.size() - 3)), reserved, route_range.x)
		note_cells.append(note_cell)
		reserved[note_cell] = true

	monster_spawn_grid = _find_reachable_cell_near(rows, exit_grid + Vector2i(-4, -4), reserved, int(max_dist * 0.58))

func _select_landmarks(rows: Array[String], rng: RandomNumberGenerator):
	landmark_cells.clear()
	var reserved := {}
	reserved[start_grid] = true
	reserved[exit_grid] = true
	for cell in pickup_cells.values():
		reserved[cell] = true

	var candidates: Array[Vector2i] = []
	for y in range(1, rows.size() - 1):
		for x in range(1, rows[0].length() - 1):
			var cell = Vector2i(x, y)
			if reserved.has(cell):
				continue
			if not _is_walkable_cell(rows, cell):
				continue
			var neighbors = _count_path_neighbors(rows, cell)
			if room_cells.has(cell) or neighbors >= 3 or neighbors == 1:
				candidates.append(cell)

	_shuffle_cells(candidates, rng)
	for cell in candidates:
		if landmark_cells.size() >= landmark_count:
			break
		var too_close = false
		for other in landmark_cells:
			if cell.distance_to(other) < 4.0:
				too_close = true
				break
		if too_close:
			continue
		landmark_cells.append(cell)

func _mark_special_cells(rows: Array[String]):
	for cell in room_cells.keys():
		if _get_cell(rows, cell) != WALL:
			_set_cell(rows, cell, ROOM)

	for cell in landmark_cells:
		if _is_walkable_cell(rows, cell):
			_set_cell(rows, cell, LANDMARK)

	if pickup_cells.has("flashlight"):
		_set_cell(rows, pickup_cells["flashlight"], FLASHLIGHT_MARKER)
	if pickup_cells.has("battery"):
		_set_cell(rows, pickup_cells["battery"], BATTERY_MARKER)
	if pickup_cells.has("artifact"):
		_set_cell(rows, pickup_cells["artifact"], ARTIFACT_MARKER)
	if pickup_cells.has("key"):
		_set_cell(rows, pickup_cells["key"], KEY_MARKER)
	for cell in note_cells:
		if _is_walkable_cell(rows, cell):
			_set_cell(rows, cell, NOTE_MARKER)

	_set_cell(rows, start_grid, START)
	_set_cell(rows, exit_grid, EXIT)

func _ensure_required_connectivity(rows: Array[String]):
	var required: Array[Vector2i] = [start_grid, exit_grid]
	for cell in pickup_cells.values():
		required.append(cell)
	for cell in note_cells:
		required.append(cell)

	if _are_cells_reachable(rows, required):
		return

	for target in required:
		_ensure_connection(rows, start_grid, target)
	_mark_special_cells(rows)

func _validate_generated_map(rows: Array[String]):
	var required: Array[Vector2i] = [start_grid, exit_grid]
	for cell in pickup_cells.values():
		required.append(cell)
	for cell in note_cells:
		required.append(cell)

	if not _are_cells_reachable(rows, required):
		push_error("Maze validation failed: exit or pickup is not reachable from start.")

	for pickup_name in pickup_cells.keys():
		var cell = pickup_cells[pickup_name]
		if not _is_walkable_cell(rows, cell):
			push_error("Maze validation failed: pickup '%s' was placed in a wall at %s." % [pickup_name, str(cell)])
	for cell in note_cells:
		if not _is_walkable_cell(rows, cell):
			push_error("Maze validation failed: note was placed in a wall at %s." % str(cell))

func _build_geometry():
	_maze_root = Node3D.new()
	_maze_root.name = "GeneratedMaze"
	add_child(_maze_root)

	var wall_material = _create_stone_material("res://assets/wall_texture 1", Color(0.67, 0.66, 0.61), wall_uv_scale, true, 0.65)
	var floor_material = _create_stone_material("res://assets/wall texture 2", Color(0.48, 0.46, 0.40), floor_uv_scale, false, 0.38)
	var cave_material = _create_stone_material("res://assets/wall_texture 1", Color(0.38, 0.39, 0.36), wall_uv_scale * 0.85, false, 0.75)
	var landmark_material = _create_emissive_material(Color(0.72, 0.61, 0.36), Color(0.95, 0.62, 0.18), 0.25)
	var detail_material = _create_emissive_material(Color(0.24, 0.22, 0.19), Color(0.02, 0.012, 0.006), 0.02)
	detail_material.roughness = 1.0

	var grid_w = radar_grid[0].length()
	var grid_h = radar_grid.size()
	var floor_body = StaticBody3D.new()
	floor_body.name = "MazeFloor"
	_maze_root.add_child(floor_body)
	floor_body.position = grid_to_world(Vector2i(int(grid_w / 2), int(grid_h / 2)), -0.18)

	var floor_mesh = MeshInstance3D.new()
	var floor_box = BoxMesh.new()
	floor_box.size = Vector3(grid_w * cell_size, 0.36, grid_h * cell_size)
	floor_box.material = floor_material
	floor_mesh.mesh = floor_box
	floor_body.add_child(floor_mesh)

	var floor_collision = CollisionShape3D.new()
	var floor_shape = BoxShape3D.new()
	floor_shape.size = floor_box.size
	floor_collision.shape = floor_shape
	floor_body.add_child(floor_collision)

	var height_rng = RandomNumberGenerator.new()
	height_rng.seed = maze_seed + 999

	for y in range(grid_h):
		for x in range(grid_w):
			var cell = Vector2i(x, y)
			var marker = radar_grid[y].substr(x, 1)
			if marker == WALL:
				_add_wall(cell, wall_material, height_rng)
			else:
				if room_cells.has(cell):
					if _should_add_room_ruin(cell):
						_add_room_ruin(cell, wall_material, height_rng)
				if cave_cells.has(cell) and _should_add_cave_feature(cell):
					_add_cave_feature(cell, cave_material, height_rng)

				match marker:
					LANDMARK:
						_add_landmark(cell, landmark_material, height_rng)

				if _should_add_floor_detail(cell):
					_add_floor_detail(cell, detail_material, height_rng)

func _create_stone_material(folder: String, tint: Color, uv_scale: Vector3, use_displacement: bool, normal_scale: float) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = tint
	material.metallic = 0.0
	material.roughness = 0.96
	material.uv1_triplanar = true
	material.uv1_scale = uv_scale

	var tex_albedo = load(folder + "/Albedo.jpg")
	if tex_albedo:
		material.albedo_texture = tex_albedo

	var tex_normal = load(folder + "/Normal.jpg")
	if tex_normal:
		material.normal_enabled = true
		material.normal_texture = tex_normal
		material.normal_scale = normal_scale

	var tex_roughness = load(folder + "/Roughness.jpg")
	if tex_roughness:
		material.roughness_texture = tex_roughness
		material.roughness = 0.96

	var tex_ao = load(folder + "/AO.jpg")
	if tex_ao:
		material.ao_enabled = true
		material.ao_texture = tex_ao
		material.ao_light_affect = 0.32

	return material

func _create_emissive_material(albedo: Color, emission: Color, energy: float) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = albedo
	material.metallic = 0.0
	material.roughness = 0.88
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = energy
	return material

func _add_wall(grid_position: Vector2i, material: Material, height_rng: RandomNumberGenerator):
	var w_height = height_rng.randf_range(min_wall_height, max_wall_height)

	var body = StaticBody3D.new()
	body.name = "Wall_%d_%d" % [grid_position.x, grid_position.y]
	body.position = grid_to_world(grid_position, w_height * 0.5)
	_maze_root.add_child(body)

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.rotation.y = height_rng.randf_range(-0.035, 0.035)
	var mesh = BoxMesh.new()
	mesh.size = Vector3(cell_size, w_height, cell_size)
	mesh.subdivide_width = 4
	mesh.subdivide_height = 5
	mesh.subdivide_depth = 4
	mesh.material = material
	mesh_instance.mesh = mesh
	body.add_child(mesh_instance)

	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(cell_size, w_height, cell_size)
	collision.shape = shape
	body.add_child(collision)

func _add_landmark(grid_position: Vector2i, material: Material, rng: RandomNumberGenerator):
	var root = Node3D.new()
	root.name = "Landmark_%d_%d" % [grid_position.x, grid_position.y]
	root.position = grid_to_world(grid_position, 0.0)
	root.rotation.y = rng.randf_range(0.0, TAU)
	_maze_root.add_child(root)

	var base = MeshInstance3D.new()
	var base_mesh = CylinderMesh.new()
	base_mesh.top_radius = 0.95
	base_mesh.bottom_radius = 1.15
	base_mesh.height = 0.28
	base_mesh.radial_segments = 10
	base_mesh.material = material
	base.mesh = base_mesh
	base.position.y = 0.14
	root.add_child(base)

	var pillar = MeshInstance3D.new()
	var pillar_mesh = CylinderMesh.new()
	pillar_mesh.top_radius = 0.32
	pillar_mesh.bottom_radius = 0.42
	pillar_mesh.height = 2.35
	pillar_mesh.radial_segments = 8
	pillar_mesh.material = material
	pillar.mesh = pillar_mesh
	pillar.position.y = 1.45
	root.add_child(pillar)

	var cap = MeshInstance3D.new()
	var cap_mesh = SphereMesh.new()
	cap_mesh.radius = 0.42
	cap_mesh.height = 0.84
	cap_mesh.radial_segments = 12
	cap_mesh.rings = 6
	cap_mesh.material = material
	cap.mesh = cap_mesh
	cap.position.y = 2.75
	root.add_child(cap)

	var light = OmniLight3D.new()
	light.name = "LandmarkLight"
	light.position = Vector3(0.0, 2.9, 0.0)
	light.light_color = Color(1.0, 0.62, 0.28)
	light.light_energy = 1.15
	light.omni_range = 7.5
	light.shadow_enabled = false
	_setup_flicker(light)
	root.add_child(light)

func _should_add_room_ruin(cell: Vector2i) -> bool:
	if cell == start_grid or cell == exit_grid:
		return false
	if pickup_cells.values().has(cell) or note_cells.has(cell) or landmark_cells.has(cell):
		return false
	return int(abs(cell.x * 31 + cell.y * 17 + maze_seed)) % 4 == 0

func _add_room_ruin(grid_position: Vector2i, material: Material, rng: RandomNumberGenerator):
	var root = Node3D.new()
	root.name = "InnerRuin_%d_%d" % [grid_position.x, grid_position.y]
	root.position = grid_to_world(grid_position, 0.0)
	root.rotation.y = rng.randf_range(0.0, TAU)
	_maze_root.add_child(root)

	var wall = MeshInstance3D.new()
	var wall_mesh = BoxMesh.new()
	wall_mesh.size = Vector3(cell_size * rng.randf_range(0.28, 0.42), rng.randf_range(1.2, 2.5), 0.34)
	wall_mesh.material = material
	wall.mesh = wall_mesh
	wall.position = Vector3(rng.randf_range(-1.3, 1.3), wall_mesh.size.y * 0.5, rng.randf_range(-1.3, 1.3))
	root.add_child(wall)

	var pillar = MeshInstance3D.new()
	var pillar_mesh = CylinderMesh.new()
	pillar_mesh.top_radius = 0.22
	pillar_mesh.bottom_radius = 0.32
	pillar_mesh.height = rng.randf_range(1.6, 3.2)
	pillar_mesh.radial_segments = 7
	pillar_mesh.material = material
	pillar.mesh = pillar_mesh
	pillar.position = Vector3(rng.randf_range(-2.0, 2.0), pillar_mesh.height * 0.5, rng.randf_range(-2.0, 2.0))
	root.add_child(pillar)

func _should_add_cave_feature(cell: Vector2i) -> bool:
	if pickup_cells.values().has(cell) or note_cells.has(cell) or landmark_cells.has(cell):
		return false
	return int(abs(cell.x * 47 + cell.y * 19 + maze_seed)) % 2 == 0

func _add_cave_feature(grid_position: Vector2i, material: Material, rng: RandomNumberGenerator):
	var root = Node3D.new()
	root.name = "CaveRock_%d_%d" % [grid_position.x, grid_position.y]
	root.position = grid_to_world(grid_position, 0.0)
	root.rotation.y = rng.randf_range(0.0, TAU)
	_maze_root.add_child(root)

	var ceiling = MeshInstance3D.new()
	var ceiling_mesh = BoxMesh.new()
	ceiling_mesh.size = Vector3(rng.randf_range(2.6, 4.8), rng.randf_range(0.22, 0.55), rng.randf_range(2.4, 4.4))
	ceiling_mesh.material = material
	ceiling.mesh = ceiling_mesh
	ceiling.position = Vector3(rng.randf_range(-0.8, 0.8), rng.randf_range(5.4, 6.8), rng.randf_range(-0.8, 0.8))
	ceiling.rotation = Vector3(rng.randf_range(-0.10, 0.10), rng.randf_range(0.0, TAU), rng.randf_range(-0.08, 0.08))
	root.add_child(ceiling)

	var rock_count = rng.randi_range(1, 3)
	for i in range(rock_count):
		var rock = MeshInstance3D.new()
		var rock_mesh = CylinderMesh.new()
		rock_mesh.top_radius = rng.randf_range(0.08, 0.18)
		rock_mesh.bottom_radius = rng.randf_range(0.24, 0.46)
		rock_mesh.height = rng.randf_range(0.8, 1.9)
		rock_mesh.radial_segments = 6
		rock_mesh.material = material
		rock.mesh = rock_mesh
		var side_offset = Vector3(rng.randf_range(-2.45, 2.45), rock_mesh.height * 0.5, rng.randf_range(-2.45, 2.45))
		rock.position = side_offset
		rock.rotation.z = rng.randf_range(-0.16, 0.16)
		root.add_child(rock)

func _should_add_floor_detail(cell: Vector2i) -> bool:
	if cell.distance_to(start_grid) < 3.0 or cell.distance_to(exit_grid) < 2.0:
		return false
	if pickup_cells.values().has(cell) or note_cells.has(cell) or landmark_cells.has(cell):
		return false
	var chance_divisor = 3 if room_cells.has(cell) else 5
	return int(abs(cell.x * 13 + cell.y * 29 + maze_seed)) % chance_divisor == 0

func _add_floor_detail(grid_position: Vector2i, material: Material, rng: RandomNumberGenerator):
	var root = Node3D.new()
	root.name = "FloorDetail_%d_%d" % [grid_position.x, grid_position.y]
	root.position = grid_to_world(grid_position, 0.0)
	root.rotation.y = rng.randf_range(0.0, TAU)
	_maze_root.add_child(root)

	var pieces = rng.randi_range(2, 5)
	for i in range(pieces):
		var mesh_instance = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = Vector3(rng.randf_range(0.28, 0.72), rng.randf_range(0.08, 0.24), rng.randf_range(0.24, 0.68))
		mesh.material = material
		mesh_instance.mesh = mesh
		mesh_instance.position = Vector3(rng.randf_range(-1.8, 1.8), mesh.size.y * 0.5, rng.randf_range(-1.8, 1.8))
		mesh_instance.rotation.y = rng.randf_range(0.0, TAU)
		root.add_child(mesh_instance)

func _build_lights():
	var light_rng = RandomNumberGenerator.new()
	light_rng.seed = maze_seed + 1234
	var grid_w = radar_grid[0].length()
	var grid_h = radar_grid.size()

	_add_map_light("StartLight", start_grid, Color(1.0, 0.70, 0.40), 1.8, 12.0, false)
	_add_map_light("ExitLight", exit_grid, Color(0.16, 0.82, 0.46), 2.3, 13.5, false)

	for cell in pickup_cells.values():
		_add_map_light("PickupLight_%d_%d" % [cell.x, cell.y], cell, Color(0.90, 0.70, 0.30), 0.85, 6.8, false)
	for cell in note_cells:
		_add_map_light("NoteLight_%d_%d" % [cell.x, cell.y], cell, Color(0.88, 0.50, 0.22), 0.55, 5.4, false)

	for y in range(1, grid_h - 1):
		for x in range(1, grid_w - 1):
			var cell = Vector2i(x, y)
			if not _is_walkable_cell(radar_grid, cell):
				continue
			if cell.distance_to(start_grid) < 3.0:
				continue
			if pickup_cells.values().has(cell) or landmark_cells.has(cell):
				continue

			var neighbors = _count_path_neighbors(radar_grid, cell)
			var chance = 0.10
			if room_cells.has(cell):
				chance = 0.05
			elif neighbors == 1 or neighbors >= 3:
				chance = 0.22

			if light_rng.randf() < chance:
				var energy = light_rng.randf_range(0.65, 1.25)
				var range_value = light_rng.randf_range(8.5, 11.5)
				_add_map_light("PathLight_%d_%d" % [x, y], cell, Color(1.0, 0.73, 0.46), energy, range_value, false)

func _add_map_light(node_name: String, cell: Vector2i, color: Color, energy: float, range_value: float, casts_shadow: bool):
	var lamp = OmniLight3D.new()
	lamp.name = node_name
	lamp.position = grid_to_world(cell, 3.1)
	lamp.light_color = color
	lamp.light_energy = energy
	lamp.omni_range = range_value
	lamp.shadow_enabled = casts_shadow
	_setup_flicker(lamp)
	_maze_root.add_child(lamp)

func _setup_flicker(light: Light3D):
	var flicker_script = load("res://flickering_light.gd")
	if flicker_script:
		light.set_script(flicker_script)

func _build_obstacles():
	var obs_rng = RandomNumberGenerator.new()
	obs_rng.seed = maze_seed + 7777
	var obstacle_material = _create_stone_material("res://assets/wall_texture 1", Color(0.62, 0.60, 0.55), wall_uv_scale, false, 0.45)
	var used_cells := {}

	for y in range(1, radar_grid.size() - 1):
		for x in range(1, radar_grid[0].length() - 1):
			var cell = Vector2i(x, y)
			if _get_cell(radar_grid, cell) != PATH:
				continue
			if cell.distance_to(start_grid) < 5.0 or cell.distance_to(exit_grid) < 4.0:
				continue
			if _is_pickup_or_landmark_near(cell, 2):
				continue
			if _count_path_neighbors(radar_grid, cell) != 2:
				continue
			if not _has_straight_corridor(radar_grid, cell):
				continue
			if obs_rng.randf() > obstacle_chance:
				continue
			if _has_used_obstacle_neighbor(used_cells, cell):
				continue

			used_cells[cell] = true
			if obs_rng.randf() < 0.45:
				_add_crouch_beam(cell, obstacle_material, obs_rng)
			else:
				_add_side_rubble(cell, obstacle_material, obs_rng)

func _add_crouch_beam(cell: Vector2i, material: Material, rng: RandomNumberGenerator):
	var axis = _get_corridor_axis(radar_grid, cell)
	if axis == "":
		return

	var body = StaticBody3D.new()
	body.name = "CrouchBeam_%d_%d" % [cell.x, cell.y]
	body.position = grid_to_world(cell, 2.02)
	_maze_root.add_child(body)

	var beam_size = Vector3(cell_size * 1.08, 0.72, 1.45)
	if axis == "x":
		beam_size = Vector3(1.45, 0.72, cell_size * 1.08)
	body.rotation.y = rng.randf_range(-0.05, 0.05)

	var mesh_instance = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = beam_size
	mesh.subdivide_width = 3
	mesh.subdivide_height = 2
	mesh.subdivide_depth = 3
	mesh.material = material
	mesh_instance.mesh = mesh
	body.add_child(mesh_instance)

	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = beam_size
	collision.shape = shape
	body.add_child(collision)

func _add_side_rubble(cell: Vector2i, material: Material, rng: RandomNumberGenerator):
	var axis = _get_corridor_axis(radar_grid, cell)
	if axis == "":
		return

	var side = -1.0 if rng.randf() < 0.5 else 1.0
	var offset = Vector3.ZERO
	if axis == "x":
		offset.z = side * rng.randf_range(2.15, 2.65)
	else:
		offset.x = side * rng.randf_range(2.15, 2.65)

	var body = StaticBody3D.new()
	body.name = "SideRubble_%d_%d" % [cell.x, cell.y]
	body.position = grid_to_world(cell, 0.45) + offset
	body.rotation.y = rng.randf_range(0.0, TAU)
	_maze_root.add_child(body)

	var mesh_instance = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	var rock_x = rng.randf_range(1.25, 1.85)
	var rock_y = rng.randf_range(0.55, 0.95)
	var rock_z = rng.randf_range(1.25, 1.85)
	mesh.size = Vector3(rock_x, rock_y, rock_z)
	mesh.subdivide_width = 2
	mesh.subdivide_height = 2
	mesh.subdivide_depth = 2
	mesh.material = material
	mesh_instance.mesh = mesh
	body.add_child(mesh_instance)

	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(rock_x * 0.72, rock_y, rock_z * 0.72)
	collision.shape = shape
	body.add_child(collision)

func _place_player():
	var player = get_node_or_null(player_path)
	if not player:
		return
	player.global_position = grid_to_world(start_grid, 1.0)
	player.rotation = Vector3.ZERO

func _place_pickups():
	_move_node_to_grid("/root/Main/TestFlashlight", _get_pickup_cell("flashlight", start_grid + Vector2i(2, 0)), 0.28)
	_move_node_to_grid("/root/Main/TestBattery", _get_pickup_cell("battery", Vector2i(int(radar_grid[0].length() / 2), int(radar_grid.size() / 2))), 0.5)
	_move_node_to_grid("/root/Main/TestArtifact", _get_pickup_cell("artifact", exit_grid + Vector2i(-2, 0)), 0.5)
	_move_node_to_grid("/root/Main/GateKey", _get_pickup_cell("key", exit_grid + Vector2i(-4, -2)), 0.45)
	_move_node_to_grid("/root/Main/ExitGate", exit_grid, 0.0)
	_move_node_to_grid("/root/Main/NotePickup1", note_cells[0] if note_cells.size() > 0 else start_grid + Vector2i(2, 2), 0.18)
	_move_node_to_grid("/root/Main/NotePickup2", note_cells[1] if note_cells.size() > 1 else start_grid + Vector2i(4, 2), 0.18)
	_move_node_to_grid("/root/Main/NotePickup3", note_cells[2] if note_cells.size() > 2 else exit_grid + Vector2i(-4, -2), 0.18)
	_place_monsters()

func _place_monsters():
	var distances = _get_distance_map(radar_grid, start_grid)
	var route_length = int(distances.get(exit_grid, radar_grid.size() + radar_grid[0].length()))
	var rng = RandomNumberGenerator.new()
	rng.seed = maze_seed + 917
	var reserved := {}
	var monster_paths = [
		"/root/Main/Monster",
		"/root/Main/MonsterHie",
		"/root/Main/MonsterChest",
		"/root/Main/MonsterNoFace",
		"/root/Main/MonsterRaphael",
	]
	var route_windows = [
		Vector2(0.28, 0.44),
		Vector2(0.40, 0.58),
		Vector2(0.52, 0.70),
		Vector2(0.64, 0.84),
		Vector2(0.72, 0.93),
	]
	var monster_targets: Array[Vector2i] = []
	for i in range(monster_paths.size()):
		var window = route_windows[min(i, route_windows.size() - 1)]
		var cell = _choose_cell_by_route_distance(radar_grid, distances, int(route_length * window.x), int(route_length * window.y), reserved, rng)
		if i == monster_paths.size() - 1 and _is_walkable_cell(radar_grid, monster_spawn_grid):
			cell = monster_spawn_grid
		if cell != Vector2i(-1, -1):
			reserved[cell] = true
		monster_targets.append(cell)

	for i in range(monster_paths.size()):
		var cell = monster_targets[i]
		if cell == Vector2i(-1, -1) or not _is_walkable_cell(radar_grid, cell):
			var t = float(i + 2) / float(monster_paths.size() + 2)
			var fallback = Vector2i(
				int(round(lerp(float(start_grid.x), float(exit_grid.x), t))),
				int(round(lerp(float(start_grid.y), float(exit_grid.y), t)))
			)
			cell = _find_reachable_cell_near(radar_grid, fallback, reserved, int(route_length * 0.28))
		reserved[cell] = true
		_move_node_to_grid(monster_paths[i], cell, 0.0)

func _move_node_to_grid(path, grid_position: Vector2i, y: float):
	var node = get_node_or_null(path)
	if not node:
		return
	if not _is_inside_grid(grid_position):
		return
	if not _is_walkable_cell(radar_grid, grid_position):
		grid_position = _find_reachable_cell_near(radar_grid, grid_position, {}, 0)
	node.global_position = grid_to_world(grid_position, y)

func _get_pickup_cell(name: String, fallback: Vector2i) -> Vector2i:
	if pickup_cells.has(name):
		return pickup_cells[name]
	return fallback

func _remove_test_arena():
	for node_name in [
		"Floor", "WallNorth", "WallSouth", "WallEast", "WallWest", "MovementMarker",
		"MixamoPreview", "JumpBlockLowA", "JumpBlockLowB", "JumpBlockMid", "LongJumpBlock",
		"PracticePlatform", "TallJumpBlockA", "TallJumpBlockB", "UpperFloor",
		"StairStep01", "StairStep02", "StairStep03", "StairStep04", "StairStep05",
		"StairStep06", "StairStep07"
	]:
		var node = get_parent().get_node_or_null(node_name)
		if node:
			node.queue_free()

func _cell_to_grid(cell: Vector2i) -> Vector2i:
	return Vector2i(cell.x * 2 + 1, cell.y * 2 + 1)

func _set_cell(rows: Array[String], position: Vector2i, value: String):
	if position.y < 0 or position.y >= rows.size() or position.x < 0 or position.x >= rows[position.y].length():
		return
	var row = rows[position.y]
	rows[position.y] = row.substr(0, position.x) + value + row.substr(position.x + 1)

func _get_cell(rows: Array[String], pos: Vector2i) -> String:
	if pos.x < 0 or pos.y < 0 or pos.y >= rows.size() or pos.x >= rows[pos.y].length():
		return WALL
	return rows[pos.y].substr(pos.x, 1)

func _is_inside_grid(pos: Vector2i) -> bool:
	return not radar_grid.is_empty() and pos.y >= 0 and pos.y < radar_grid.size() and pos.x >= 0 and pos.x < radar_grid[pos.y].length()

func _is_walkable_marker(marker: String) -> bool:
	return marker == PATH or marker == START or marker == EXIT or marker == ROOM or marker == LANDMARK or marker == FLASHLIGHT_MARKER or marker == BATTERY_MARKER or marker == ARTIFACT_MARKER or marker == KEY_MARKER or marker == NOTE_MARKER

func _is_walkable_cell(rows: Array[String], pos: Vector2i) -> bool:
	return _is_walkable_marker(_get_cell(rows, pos))

func _count_path_neighbors(rows: Array[String], pos: Vector2i) -> int:
	var count = 0
	for dir in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		if _is_walkable_cell(rows, pos + dir):
			count += 1
	return count

func _get_path_neighbors_list(rows: Array[String], pos: Vector2i) -> Array[Vector2i]:
	var list: Array[Vector2i] = []
	for dir in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		var n = pos + dir
		if _is_walkable_cell(rows, n):
			list.append(n)
	return list

func _get_walkable_cells(rows: Array[String]) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(1, rows.size() - 1):
		for x in range(1, rows[0].length() - 1):
			var cell = Vector2i(x, y)
			if _is_walkable_cell(rows, cell):
				cells.append(cell)
	return cells

func _shuffle_cells(cells: Array[Vector2i], rng: RandomNumberGenerator):
	if cells.size() < 2:
		return
	for i in range(cells.size()):
		var j = rng.randi_range(i, cells.size() - 1)
		var temp = cells[i]
		cells[i] = cells[j]
		cells[j] = temp

func _prune_dead_ends(rows: Array[String], max_len: int, rng: RandomNumberGenerator):
	if max_len < 0:
		return

	var iterations = 0
	var pruned_any = true
	while pruned_any and iterations < 320:
		iterations += 1
		pruned_any = false
		var leaves: Array[Vector2i] = []

		for y in range(1, rows.size() - 1):
			for x in range(1, rows[0].length() - 1):
				var cell = Vector2i(x, y)
				if _get_cell(rows, cell) != PATH:
					continue
				if _count_path_neighbors(rows, cell) == 1:
					leaves.append(cell)

		_shuffle_cells(leaves, rng)
		for leaf in leaves:
			var path = _trace_dead_end(rows, leaf)
			if path.is_empty():
				continue

			var max_grid_steps = max(0, max_len * 2)
			var candidate: Array[Vector2i] = []
			if rng.randf() < dead_end_removal_rate:
				candidate = path
			elif path.size() > max_grid_steps:
				for i in range(path.size() - max_grid_steps):
					candidate.append(path[i])

			if candidate.is_empty():
				continue
			if _try_turn_cells_to_walls(rows, candidate):
				pruned_any = true
				break

func _trace_dead_end(rows: Array[String], leaf: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var previous = Vector2i(-999, -999)
	var current = leaf

	while true:
		if _get_cell(rows, current) != PATH:
			break
		path.append(current)

		var forward_neighbors: Array[Vector2i] = []
		for n in _get_path_neighbors_list(rows, current):
			if n != previous:
				forward_neighbors.append(n)

		if forward_neighbors.size() != 1:
			break

		var next_cell = forward_neighbors[0]
		if next_cell == start_grid or next_cell == exit_grid:
			break
		if _get_cell(rows, next_cell) != PATH:
			break
		if _count_path_neighbors(rows, next_cell) > 2:
			break

		previous = current
		current = next_cell

	return path

func _try_turn_cells_to_walls(rows: Array[String], cells: Array[Vector2i]) -> bool:
	var old_values := {}
	for cell in cells:
		if cell == start_grid or cell == exit_grid or _get_cell(rows, cell) != PATH:
			return false
		old_values[cell] = _get_cell(rows, cell)
		_set_cell(rows, cell, WALL)

	if _are_cells_reachable(rows, [start_grid, exit_grid]):
		return true

	for cell in old_values.keys():
		_set_cell(rows, cell, old_values[cell])
	return false

func _are_cells_reachable(rows: Array[String], required: Array[Vector2i]) -> bool:
	if required.is_empty():
		return true
	var distance_map = _get_distance_map(rows, required[0])
	for cell in required:
		if not distance_map.has(cell):
			return false
	return true

func _get_distance_map(rows: Array[String], from_cell: Vector2i) -> Dictionary:
	var distances := {}
	if not _is_walkable_cell(rows, from_cell):
		return distances

	var queue: Array[Vector2i] = []
	queue.append(from_cell)
	distances[from_cell] = 0

	while not queue.is_empty():
		var current = queue.pop_front()
		var current_distance = int(distances[current])
		for next_cell in _get_path_neighbors_list(rows, current):
			if distances.has(next_cell):
				continue
			distances[next_cell] = current_distance + 1
			queue.append(next_cell)

	return distances

func _find_grid_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if radar_grid.is_empty():
		return result
	if not _is_walkable_cell(radar_grid, start):
		start = _find_reachable_cell_near(radar_grid, start, {}, 0)
	if not _is_walkable_cell(radar_grid, goal):
		goal = _find_reachable_cell_near(radar_grid, goal, {}, 0)

	var queue: Array[Vector2i] = [start]
	var came_from := {}
	came_from[start] = start

	while not queue.is_empty():
		var current = queue.pop_front()
		if current == goal:
			break
		for next_cell in _get_path_neighbors_list(radar_grid, current):
			if came_from.has(next_cell):
				continue
			came_from[next_cell] = current
			queue.append(next_cell)

	if not came_from.has(goal):
		result.append(goal)
		return result

	var current = goal
	while current != start:
		result.push_front(current)
		current = came_from[current]
	result.push_front(start)
	return result

func _ensure_connection(rows: Array[String], from_cell: Vector2i, to_cell: Vector2i):
	if _are_cells_reachable(rows, [from_cell, to_cell]):
		return

	var current = from_cell
	while current.x != to_cell.x:
		current.x += 1 if to_cell.x > current.x else -1
		if _get_cell(rows, current) == WALL:
			_set_cell(rows, current, PATH)
	while current.y != to_cell.y:
		current.y += 1 if to_cell.y > current.y else -1
		if _get_cell(rows, current) == WALL:
			_set_cell(rows, current, PATH)

func _find_reachable_cell_near(rows: Array[String], desired: Vector2i, reserved: Dictionary, min_start_distance: int) -> Vector2i:
	var distances = _get_distance_map(rows, start_grid)
	var best = Vector2i(-1, -1)
	var best_score = INF

	for key in distances.keys():
		var cell = key
		if reserved.has(cell):
			continue
		if cell == start_grid or cell == exit_grid:
			continue
		if int(distances[cell]) < min_start_distance:
			continue
		if not _is_pickup_safe_cell(rows, cell):
			continue
		var score = _grid_distance_squared(cell, desired) + abs(int(distances[cell]) - min_start_distance) * 0.03
		if score < best_score:
			best_score = score
			best = cell

	if best == Vector2i(-1, -1):
		return start_grid
	return best

func _choose_cell_by_route_distance(rows: Array[String], distances: Dictionary, min_distance: int, max_distance: int, reserved: Dictionary, rng: RandomNumberGenerator) -> Vector2i:
	var candidates: Array[Vector2i] = []
	for key in distances.keys():
		var cell = key
		if reserved.has(cell):
			continue
		if cell == start_grid or cell == exit_grid:
			continue
		var distance = int(distances[cell])
		if distance < min_distance or distance > max_distance:
			continue
		if not _is_pickup_safe_cell(rows, cell):
			continue
		if room_cells.has(cell) or _count_path_neighbors(rows, cell) >= 3:
			candidates.append(cell)

	if candidates.is_empty():
		for key in distances.keys():
			var cell = key
			if reserved.has(cell) or cell == start_grid or cell == exit_grid:
				continue
			var distance = int(distances[cell])
			if distance >= min_distance and distance <= max_distance and _is_pickup_safe_cell(rows, cell):
				candidates.append(cell)

	if candidates.is_empty():
		return Vector2i(-1, -1)
	return candidates[rng.randi_range(0, candidates.size() - 1)]

func _is_pickup_safe_cell(rows: Array[String], cell: Vector2i) -> bool:
	if not _is_walkable_cell(rows, cell):
		return false
	if _count_path_neighbors(rows, cell) == 0:
		return false
	for dir in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		if _get_cell(rows, cell + dir) == WALL:
			continue
	return true

func _grid_distance_squared(a: Vector2i, b: Vector2i) -> float:
	var dx = float(a.x - b.x)
	var dy = float(a.y - b.y)
	return dx * dx + dy * dy

func _is_pickup_or_landmark_near(cell: Vector2i, radius: int) -> bool:
	for pickup_cell in pickup_cells.values():
		if cell.distance_to(pickup_cell) <= float(radius):
			return true
	for landmark_cell in landmark_cells:
		if cell.distance_to(landmark_cell) <= float(radius):
			return true
	return false

func _has_used_obstacle_neighbor(used_cells: Dictionary, cell: Vector2i) -> bool:
	for y in range(-1, 2):
		for x in range(-1, 2):
			if used_cells.has(cell + Vector2i(x, y)):
				return true
	return false

func _has_straight_corridor(rows: Array[String], cell: Vector2i) -> bool:
	var left = _is_walkable_cell(rows, cell + Vector2i.LEFT)
	var right = _is_walkable_cell(rows, cell + Vector2i.RIGHT)
	var up = _is_walkable_cell(rows, cell + Vector2i.UP)
	var down = _is_walkable_cell(rows, cell + Vector2i.DOWN)
	return (left and right and not up and not down) or (up and down and not left and not right)

func _get_corridor_axis(rows: Array[String], cell: Vector2i) -> String:
	var left = _is_walkable_cell(rows, cell + Vector2i.LEFT)
	var right = _is_walkable_cell(rows, cell + Vector2i.RIGHT)
	var up = _is_walkable_cell(rows, cell + Vector2i.UP)
	var down = _is_walkable_cell(rows, cell + Vector2i.DOWN)
	if left and right and not up and not down:
		return "x"
	if up and down and not left and not right:
		return "z"
	return ""
