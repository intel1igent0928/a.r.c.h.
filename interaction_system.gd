extends Node
class_name InteractionSystem

# ──────────────────────────────────────────────────────────────────────
#  A.R.C.H. — Interaction System
#
#  Attach to the Player node (sibling of CameraPivot).
#  Each frame casts a short ray from the camera forward.
#  If it hits an Interactable, shows a prompt.
#  E key triggers the interaction.
#
#  Designed to be extended later for:
#    • item pickup,  door open,  examine,  key-card reader, etc.
# ──────────────────────────────────────────────────────────────────────

const REACH          := 2.6    # metres the player can reach
const RAY_LENGTH     := 3.2    # slightly longer to detect before touch
const INTERACT_KEY   := "interact"

@export var show_debug_label : bool = true

# ── Internal refs ──────────────────────────────────────────────────────
var _camera        : Camera3D
var _space         : PhysicsDirectSpaceState3D
var _player_rid    : RID

var _current_target : Interactable = null
var _prompt_label   : Label        = null
var _hint_panel     : Panel        = null


func _ready() -> void:
	# Find camera (Player/CameraPivot/Camera3D)
	_camera = get_parent().find_child("Camera3D", true, false)
	_player_rid = get_parent().get_rid()

	_ensure_input_action()
	_build_ui()


func _process(_delta: float) -> void:
	_space = get_parent().get_world_3d().direct_space_state
	var target := _raycast_for_interactable()
	_update_target(target)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(INTERACT_KEY) and _current_target:
		_current_target.interact(get_parent())


# ── Ray cast ───────────────────────────────────────────────────────────
func _raycast_for_interactable() -> Interactable:
	if not _camera or not _space:
		return null

	var origin: Vector3 = _camera.global_position
	var forward: Vector3 = -_camera.global_transform.basis.z
	var end: Vector3 = origin + forward * RAY_LENGTH

	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [_player_rid]
	query.collide_with_areas = true

	var hit := _space.intersect_ray(query)
	if hit.is_empty():
		return null

	var col: Object = hit["collider"]
	# Walk up the scene tree looking for an Interactable
	var node: Node = col as Node
	while node:
		if node is Interactable and node.enabled:
			var dist: float = origin.distance_to(hit["position"] as Vector3)
			if dist <= REACH:
				return node as Interactable
		node = node.get_parent()
	return null


# ── Update focused object ──────────────────────────────────────────────
func _update_target(new_target: Interactable) -> void:
	if new_target == _current_target:
		return

	_current_target = new_target
	_refresh_prompt()


# ── UI helpers ─────────────────────────────────────────────────────────
func _refresh_prompt() -> void:
	if not _prompt_label:
		return
	if _current_target:
		_prompt_label.text = "[E]  %s" % _current_target.prompt_text
		_hint_panel.visible = true
	else:
		_hint_panel.visible = false


func _build_ui() -> void:
	# Find the CanvasLayer already in the scene
	var canvas : CanvasLayer = get_tree().root.find_child("CanvasLayer", true, false)
	if not canvas:
		push_warning("InteractionSystem: no CanvasLayer found in scene tree.")
		return

	# Semi-transparent background panel
	_hint_panel = Panel.new()
	_hint_panel.name = "InteractPanel"
	_hint_panel.visible = false
	_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Anchor to bottom-centre of screen securely for Godot 4
	_hint_panel.anchor_left = 0.5
	_hint_panel.anchor_right = 0.5
	_hint_panel.anchor_top = 1.0
	_hint_panel.anchor_bottom = 1.0
	_hint_panel.offset_left = -150.0
	_hint_panel.offset_right = 150.0
	_hint_panel.offset_top = -100.0
	_hint_panel.offset_bottom = -60.0

	# Style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.08, 0.72)
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.border_width_top    = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.35, 0.85, 0.65, 0.55)
	_hint_panel.add_theme_stylebox_override("panel", style)

	canvas.add_child(_hint_panel)

	# Label inside panel
	_prompt_label = Label.new()
	_prompt_label.name = "InteractLabel"
	_prompt_label.text = "[E]  Interact"
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_prompt_label.anchor_left = 0.0
	_prompt_label.anchor_right = 1.0
	_prompt_label.anchor_top = 0.0
	_prompt_label.anchor_bottom = 1.0
	_prompt_label.offset_left = 0
	_prompt_label.offset_right = 0
	_prompt_label.offset_top = 0
	_prompt_label.offset_bottom = 0
	_prompt_label.add_theme_color_override("font_color", Color(0.90, 0.98, 0.88, 1.0))
	_prompt_label.add_theme_font_size_override("font_size", 15)
	_hint_panel.add_child(_prompt_label)

	# Cross-hair dot (always visible, small)
	var dot := ColorRect.new()
	dot.name        = "Crosshair"
	dot.color       = Color(1, 1, 1, 0.75)
	dot.custom_minimum_size = Vector2(5, 5)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.anchor_left = 0.5
	dot.anchor_right = 0.5
	dot.anchor_top = 0.5
	dot.anchor_bottom = 0.5
	dot.offset_left = -2.5
	dot.offset_right = 2.5
	dot.offset_top = -2.5
	dot.offset_bottom = 2.5
	canvas.add_child(dot)


# ── Input action setup ─────────────────────────────────────────────────
func _ensure_input_action() -> void:
	if InputMap.has_action(INTERACT_KEY):
		return
	InputMap.add_action(INTERACT_KEY)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_E
	key.keycode          = KEY_E
	InputMap.action_add_event(INTERACT_KEY, key)
