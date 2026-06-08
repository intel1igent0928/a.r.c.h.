extends Node3D

# ──────────────────────────────────────────────
#  A.R.C.H. — Player Hands (First-Person View)
#  Short stubby dark arms of the creature,
#  visible at the bottom of the screen.
# ──────────────────────────────────────────────

@onready var right_arm: Node3D = $RightArm
@onready var left_arm:  Node3D = $LeftArm

# Base resting positions (camera-local space)
const RIGHT_BASE := Vector3( 0.21, -0.26, -0.40)
const LEFT_BASE  := Vector3(-0.21, -0.26, -0.40)

# Offsets per state
const CROUCH_OFFSET  := Vector3(0.0, -0.055, 0.06)
const SLIDE_OFFSET   := Vector3(0.0, -0.11,  0.10)
const TIRED_OFFSET   := Vector3(0.0, -0.035, 0.0 )
const RUN_SPREAD     := Vector3(0.04, 0.0,   0.0 )   # arms spread while running

var bob_time      : float = 0.0
var idle_time     : float = 0.0
var landing_shock : float = 0.0     # kick on landing
var equip_lerp    : float = 0.0     # 0 = holstered (down), 1 = ready (up)

# State received from player.gd
var _running   : bool  = false
var _crouching : bool  = false
var _sliding   : bool  = false
var _moving    : bool  = false
var _sprint_locked : bool  = false
var _h_speed   : float = 0.0


# ── Called by player.gd every physics frame ───
func update_state(running: bool, crouching: bool, sliding: bool,
				  moving: bool, sprint_locked: bool, h_speed: float) -> void:
	_running      = running
	_crouching    = crouching
	_sliding      = sliding
	_moving       = moving
	_sprint_locked = sprint_locked
	_h_speed      = h_speed


# ── Called by player.gd on landing ────────────
func trigger_landing(fall_speed: float) -> void:
	if fall_speed > 2.5:
		landing_shock = clamp(fall_speed * 0.04, 0.08, 0.30)


# ── Main animation loop ────────────────────────
func _process(delta: float) -> void:
	idle_time += delta

	# --- bob timing ---
	var bob_speed  : float
	var bob_h      : float   # horizontal sway amplitude
	var bob_v      : float   # vertical pump amplitude

	if _sliding:
		bob_time = move_toward(bob_time, 0.0, delta * 6.0)
		bob_h = 0.0
		bob_v = 0.0
	elif _running and _moving:
		bob_speed = 19.0
		bob_time += delta * bob_speed
		bob_h = 0.022
		bob_v = 0.018
	elif _moving:
		bob_speed = 12.5
		bob_time += delta * bob_speed
		bob_h = 0.012
		bob_v = 0.010
	else:
		bob_time = move_toward(bob_time, 0.0, delta * 5.0)
		bob_h = 0.0
		bob_v = 0.0

	# --- landing shock decay ---
	landing_shock = lerp(landing_shock, 0.0, delta * 9.0)

	# --- idle breathing ---
	var breathe := sin(idle_time * 1.15) * 0.004

	# --- state offsets ---
	var state_ofs := Vector3.ZERO
	if _sliding:
		state_ofs = SLIDE_OFFSET
	elif _crouching:
		state_ofs = CROUCH_OFFSET
	elif _sprint_locked:
		state_ofs = TIRED_OFFSET

	# --- run spread (arms pump outward slightly) ---
	var spread := RUN_SPREAD if (_running and _moving) else Vector3.ZERO

	# --- compose bob ---
	var pump_y: float = -abs(sin(bob_time)) * bob_v - landing_shock * 0.10
	var sway_x: float = sin(bob_time) * bob_h
	var bob_ofs: Vector3 = Vector3(sway_x, pump_y + breathe, 0.0)

	# --- apply to right arm ---
	var r_target := RIGHT_BASE + bob_ofs + state_ofs + spread
	right_arm.position = right_arm.position.lerp(r_target, delta * 22.0)
	right_arm.rotation.z = lerp(right_arm.rotation.z, -sway_x * 1.8, delta * 14.0)
	right_arm.rotation.x = lerp(right_arm.rotation.x,
								 -0.12 - landing_shock * 0.4, delta * 18.0)

	# --- apply to left arm (mirrored sway) ---
	var l_target := LEFT_BASE + bob_ofs * Vector3(-1, 1, 1) + state_ofs + spread * Vector3(-1,1,1)
	left_arm.position = left_arm.position.lerp(l_target, delta * 22.0)
	left_arm.rotation.z = lerp(left_arm.rotation.z,  sway_x * 1.8, delta * 14.0)
	left_arm.rotation.x = lerp(left_arm.rotation.x,
								-0.12 - landing_shock * 0.4, delta * 18.0)

# ── Show Flashlight ───────────────────────────────────────────────────
func show_flashlight(is_visible: bool) -> void:
	var fl = right_arm.get_node_or_null("FlashlightProp")
	if fl:
		fl.visible = is_visible
