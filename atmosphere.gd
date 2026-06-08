extends Node

const SAMPLE_RATE = 22050

var _ambient_player: AudioStreamPlayer
var _ambient_playback: AudioStreamGeneratorPlayback
var _phase := 0.0
var _noise_seed := 0.0
var _manager: Node
var _player: Node3D
var _monster: Node3D

func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_manager = get_tree().root.find_child("GameManager", true, false)
	_player = get_tree().root.find_child("Player", true, false) as Node3D
	_monster = get_tree().root.find_child("Monster", true, false) as Node3D
	_build_ambient()

func _process(delta: float):
	if not _ambient_playback:
		return
	var frames_needed = _ambient_playback.get_frames_available()
	for i in range(frames_needed):
		_ambient_playback.push_frame(_next_ambient_frame())

func _build_ambient():
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.name = "ProceduralMazeAmbience"
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = SAMPLE_RATE
	stream.buffer_length = 0.7
	_ambient_player.stream = stream
	_ambient_player.volume_db = -22.0
	add_child(_ambient_player)
	_ambient_player.play()
	_ambient_playback = _ambient_player.get_stream_playback() as AudioStreamGeneratorPlayback

func _next_ambient_frame() -> Vector2:
	var monster_pressure = _get_monster_pressure()
	var manager_threat = float(_manager.get("threat")) if _manager else 0.0
	var intensity = clamp(monster_pressure + manager_threat * 0.25, 0.0, 1.0)
	var freq = lerp(45.0, 72.0, intensity)
	_phase += TAU * freq / float(SAMPLE_RATE)
	if _phase > TAU:
		_phase -= TAU
	_noise_seed = fmod(_noise_seed + 0.6180339, 1.0)
	var tone = sin(_phase) * lerp(0.05, 0.12, intensity)
	var grit = (randf() * 2.0 - 1.0) * lerp(0.005, 0.028, intensity)
	var pulse = sin(_phase * 0.125) * lerp(0.015, 0.05, intensity)
	var sample = tone + grit + pulse
	return Vector2(sample, sample)

func _get_monster_pressure() -> float:
	if not _player or not _monster or not _monster.visible:
		return 0.0
	var distance = _player.global_position.distance_to(_monster.global_position)
	return clamp(1.0 - distance / 28.0, 0.0, 1.0)
