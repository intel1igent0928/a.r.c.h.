import json

data = {"grid": [], "deco": []}

# Corridor from Z=0 to Z=5
for z in range(0, 6):
    # Floor
    data["grid"].append({"x": 0, "y": -1, "z": z, "item": 1, "orient": 0})
    data["grid"].append({"x": -1, "y": -1, "z": z, "item": 1, "orient": 0})
    data["grid"].append({"x": 1, "y": -1, "z": z, "item": 1, "orient": 0})
    
    # Walls (y=0, y=1)
    for y in range(0, 2):
        data["grid"].append({"x": -1, "y": y, "z": z, "item": 0, "orient": 0})
        data["grid"].append({"x": 1, "y": y, "z": z, "item": 0, "orient": 0})
        
        # Pillars
        if z % 2 == 0:
            data["grid"].append({"x": -1, "y": y, "z": z, "item": 3, "orient": 0})
            data["grid"].append({"x": 1, "y": y, "z": z, "item": 3, "orient": 0})

# Back wall at Z=-1
for y in range(0, 2):
    data["grid"].append({"x": -1, "y": y, "z": -1, "item": 0, "orient": 0})
    data["grid"].append({"x": 1, "y": y, "z": -1, "item": 0, "orient": 0})

# Door
data["grid"].append({"x": 0, "y": 0, "z": -1, "item": 4, "orient": 0})
data["grid"].append({"x": 0, "y": 1, "z": -1, "item": 0, "orient": 0})

# Crate
data["grid"].append({"x": 1, "y": 0, "z": 4, "item": 5, "orient": 0})

# Vaulted Ceiling (item 9)
for z in range(-1, 6):
    data["grid"].append({"x": 0, "y": 2, "z": z, "item": 9, "orient": 0})
    data["grid"].append({"x": -1, "y": 2, "z": z, "item": 9, "orient": 0})
    data["grid"].append({"x": 1, "y": 2, "z": z, "item": 9, "orient": 0})

# Deco
data["deco"].append({"x": -1, "y": 0, "z": 3, "item": 7, "orient": 22}) # Lever
data["deco"].append({"x": -1, "y": 0, "z": 1, "item": 6, "orient": 22}) # Torch
data["deco"].append({"x": 1, "y": 0, "z": 1, "item": 6, "orient": 16}) # Torch

with open('saved_mazes/voxel_map.json', 'w') as f:
    json.dump(data, f, indent='\t')

print("Generated voxel_map.json")
