extends Light3D

@export var min_energy := 0.6
@export var max_energy := 2.2
@export var flicker_speed := 18.0

var _base_energy := 1.2
var _rng := RandomNumberGenerator.new()
var _time := 0.0

func _ready():
	_base_energy = light_energy
	_rng.randomize()
	_time = _rng.randf_range(0.0, 1000.0)

func _process(delta: float):
	_time += delta * flicker_speed
	var noise = _rng.randf_range(-0.18, 0.18)
	var wave  = sin(_time) * 0.22
	light_energy = clamp(_base_energy * (1.0 + wave + noise), min_energy, max_energy)
