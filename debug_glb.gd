extends SceneTree

func _init():
	var scene = load("res://assets/Kenney Modlar/Models/GLB format/corridor.glb")
	if scene:
		var instance = scene.instantiate()
		print("Loaded corridor.glb. Nodes:")
		_print_nodes(instance, "")
	else:
		print("FAILED to load scene.")
	quit()

func _print_nodes(node: Node, indent: String):
	print(indent + node.name + " (" + node.get_class() + ")")
	if node is MeshInstance3D:
		print(indent + "  - has mesh! AABB: ", node.get_aabb())
	for child in node.get_children():
		_print_nodes(child, indent + "  ")
