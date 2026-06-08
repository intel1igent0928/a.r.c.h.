extends Node3D

func _ready():
	visible = true
	_apply_shadow_only(self)

func _apply_shadow_only(node: Node):
	if node is GeometryInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		node.visible = true

	for child in node.get_children():
		_apply_shadow_only(child)
