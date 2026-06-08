extends Interactable

func _ready() -> void:
	if prompt_text == "Interact":
		prompt_text = "Pick up Flashlight"

func _on_interact(player) -> void:
	if player.has_method("pickup_flashlight"):
		player.pickup_flashlight()
	var manager = get_tree().root.find_child("GameManager", true, false)
	if manager and manager.has_method("register_flashlight"):
		manager.register_flashlight()
	
	_show_pickup_text()
	
	var t := get_tree().create_timer(0.08)
	t.timeout.connect(queue_free)

func _show_pickup_text() -> void:
	var canvas : CanvasLayer = get_tree().root.find_child("CanvasLayer", true, false)
	if not canvas:
		return

	var lbl := Label.new()
	lbl.text = "Acquired: Flashlight"
	lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5, 1.0))
	lbl.add_theme_font_size_override("font_size", 17)
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.offset_top = -60.0
	lbl.offset_bottom = -30.0
	lbl.offset_left = -100.0
	lbl.offset_right = 100.0
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(lbl)

	var tween := lbl.create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "position:y", lbl.position.y - 38.0, 1.1)
	tween.tween_property(lbl, "modulate:a", 0.0, 1.1)
	tween.chain().tween_callback(lbl.queue_free)
