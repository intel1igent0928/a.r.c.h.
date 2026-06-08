extends Node3D
class_name Interactable

# ──────────────────────────────────────────────────────────────────────
#  A.R.C.H. — Base Interactable Component
#
#  Attach this script to any object the player can interact with.
#  Override _on_interact() in a child script to define behaviour.
#
#  Signals fired on the InteractionSystem allow UI / sound / effects
#  to react without coupling to individual item scripts.
# ──────────────────────────────────────────────────────────────────────

## Label shown in the interaction prompt.
## Example: "Pick up Battery"  or  "Open Door"
@export var prompt_text : String = "Interact"

## Whether this item can currently be interacted with.
@export var enabled : bool = true

## Optional: unique item id for save/loot tracking later.
@export var item_id : String = ""

signal interacted(interactable: Interactable)


# ── Called by InteractionSystem when player presses E ─────────────────
func interact(player) -> void:
	if not enabled:
		return
	_on_interact(player)
	interacted.emit(self)


# ── Override in child scripts ──────────────────────────────────────────
func _on_interact(_player) -> void:
	pass


# ── Helpers ────────────────────────────────────────────────────────────
func disable() -> void:
	enabled = false

func enable() -> void:
	enabled = true
