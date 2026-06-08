extends Interactable

# ──────────────────────────────────────────────────────────────────────
#  A.R.C.H. — Pickup Item
#
#  Attach to any StaticBody3D or Area3D with a mesh.
#  When player presses E it "picks up" the item:
#    • removes it from the world
#    • fires a signal the inventory / HUD can listen to
#
#  In the future this will feed into the Inventory System and
#  the Greed mechanic (dangerous items raise threat level).
# ──────────────────────────────────────────────────────────────────────

## Display name shown in HUD and logs.
@export var display_name  : String = "Item"

## How many points this item is worth.
@export var point_value   : int    = 10

## If true, picking this up worsens weather / wakes monster.
@export var is_dangerous  : bool   = false

## Small description shown when examined (future examine system).
@export var description   : String = ""

signal item_picked_up(item_name: String, points: int, dangerous: bool)


func _ready() -> void:
	# Auto-set the prompt if not overridden in the editor
	if prompt_text == "Interact":
		prompt_text = "Pick up %s" % display_name

	# Idle float animation
	_start_float()


func _on_interact(player) -> void:
	item_picked_up.emit(display_name, point_value, is_dangerous)
	var manager = get_tree().root.find_child("GameManager", true, false)
	if manager and manager.has_method("register_pickup"):
		manager.register_pickup(display_name, point_value, is_dangerous, description)
	_show_pickup_text()
	# Remove from world after a tiny delay so the animation plays
	var t := get_tree().create_timer(0.08)
	t.timeout.connect(queue_free)


# ── Idle floating animation ────────────────────────────────────────────
var _base_y    : float
var _float_t   : float = 0.0
const FLOAT_AMP   := 0.06
const FLOAT_SPEED := 1.8
const SPIN_SPEED  := 0.9

func _start_float() -> void:
	_base_y = position.y

func _process(delta: float) -> void:
	_float_t += delta
	position.y = _base_y + sin(_float_t * FLOAT_SPEED) * FLOAT_AMP
	rotate_y(SPIN_SPEED * delta)


# ── Tiny pickup label that floats up and fades ─────────────────────────
func _show_pickup_text() -> void:
	var canvas : CanvasLayer = get_tree().root.find_child("CanvasLayer", true, false)
	if not canvas:
		return

	var lbl := Label.new()
	lbl.text = "+ %s  (%d pts)" % [display_name, point_value]
	lbl.add_theme_color_override("font_color",
		Color(1.0, 0.45, 0.35, 1.0) if is_dangerous else Color(0.55, 1.0, 0.72, 1.0))
	lbl.add_theme_font_size_override("font_size", 17)
	lbl.set_anchor_and_offset(SIDE_LEFT,   0.5, -120.0)
	lbl.set_anchor_and_offset(SIDE_RIGHT,  0.5,  120.0)
	lbl.set_anchor_and_offset(SIDE_TOP,    0.5,  -80.0)
	lbl.set_anchor_and_offset(SIDE_BOTTOM, 0.5,  -48.0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(lbl)

	# Animate up and fade then free
	var tween := lbl.create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "position:y",   lbl.position.y - 38.0, 1.1)
	tween.tween_property(lbl, "modulate:a",   0.0,                   1.1)
	tween.chain().tween_callback(lbl.queue_free)
