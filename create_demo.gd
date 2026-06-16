extends SceneTree

func _init() -> void:
	var data := {"grid": [], "deco": []}
	
	# Corridor along Z axis from z=0 to z=5. Player starts at z=4.
	# X=-1 is Left Wall, X=0 is Center, X=1 is Right Wall
	
	# --- BASE LAYER (grid) ---
	for z in range(0, 6):
		# Floor
		data["grid"].append({"x": 0, "y": -1, "z": z, "item": 1, "orient": 0}) # Stone Floor
		data["grid"].append({"x": -1, "y": -1, "z": z, "item": 1, "orient": 0})
		data["grid"].append({"x": 1, "y": -1, "z": z, "item": 1, "orient": 0})
		
		# Walls (y=0, y=1)
		for y in range(0, 2):
			data["grid"].append({"x": -1, "y": y, "z": z, "item": 0, "orient": 0}) # Left Brick Wall
			data["grid"].append({"x": 1, "y": y, "z": z, "item": 0, "orient": 0})  # Right Brick Wall
			
			# Pillars every 2 units
			if z % 2 == 0:
				data["grid"].append({"x": -1, "y": y, "z": z, "item": 3, "orient": 0}) # Left Pillar
				data["grid"].append({"x": 1, "y": y, "z": z, "item": 3, "orient": 0})  # Right Pillar
	
	# Back wall at Z=-1
	for y in range(0, 2):
		data["grid"].append({"x": -1, "y": y, "z": -1, "item": 0, "orient": 0})
		data["grid"].append({"x": 1, "y": y, "z": -1, "item": 0, "orient": 0})
	
	# Door at the end (Z=-1, X=0, Y=0)
	data["grid"].append({"x": 0, "y": 0, "z": -1, "item": 4, "orient": 0}) # Arch Door
	data["grid"].append({"x": 0, "y": 1, "z": -1, "item": 0, "orient": 0}) # Brick over door
	
	# Crate
	data["grid"].append({"x": 1, "y": 0, "z": 4, "item": 5, "orient": 0}) # Crate on the right
	
	# Vaulted Ceiling (y=2)
	for z in range(-1, 6):
		data["grid"].append({"x": 0, "y": 2, "z": z, "item": 2, "orient": 0}) # Wood Ceiling
		data["grid"].append({"x": -1, "y": 2, "z": z, "item": 2, "orient": 0})
		data["grid"].append({"x": 1, "y": 2, "z": z, "item": 2, "orient": 0})
	
	# --- DECO LAYER (deco) ---
	# Lever on the left wall (X=-1, Y=0, Z=3). Normal is X+ -> orient = 22
	data["deco"].append({"x": -1, "y": 0, "z": 3, "item": 7, "orient": 22})
	
	# Torch on the left wall (X=-1, Y=0, Z=1). Normal is X+ -> orient = 22
	data["deco"].append({"x": -1, "y": 0, "z": 1, "item": 6, "orient": 22})
	
	# Torch on the right wall (X=1, Y=0, Z=1). Normal is X- -> orient = 16
	data["deco"].append({"x": 1, "y": 0, "z": 1, "item": 6, "orient": 16})
	
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("saved_mazes"):
		dir.make_dir("saved_mazes")
		
	var f = FileAccess.open("res://saved_mazes/voxel_map.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	
	print("Demo room generated!")
	quit()
