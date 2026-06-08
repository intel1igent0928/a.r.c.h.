extends Interactable

@export var open_rotation_degrees := 88.0

var _opened := false

func _ready():
	prompt_text = "Open Exit Gate"

func _on_interact(player):
	if _opened:
		return
	var manager = get_tree().root.find_child("GameManager", true, false)
	if manager and manager.has_method("try_exit") and manager.try_exit():
		_open_gate()

func _open_gate():
	_opened = true
	enabled = false
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees:y", rotation_degrees.y + open_rotation_degrees, 0.75).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
