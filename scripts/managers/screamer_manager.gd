extends Node

const JUMPSCARE_AUDIO_PATH := "res://assets/audio/robotic_jumpscare_3s.wav"
const JUMPSCARE_AUDIO_DURATION := 3.0
const SCREAMER_TEXTURE_PATHS := [
	"res://assets/ui/screamers/screamer_face_eyes.jpg",
	"res://assets/ui/screamers/screamer_body_display.png",
	"res://assets/ui/screamers/screamer_long_face.png",
	"res://assets/ui/screamers/screamer_wires.png",
	"res://assets/ui/desayuno_ciclo3_background.png",
	"res://assets/ui/exit_ciclo3_door_open.png"
]

var _rng := RandomNumberGenerator.new()
var _layer: CanvasLayer
var _image: TextureRect
var _overlay: ColorRect
var _audio: AudioStreamPlayer
var _active := false
var _triggering := false
var _min_interval := 8.0
var _max_interval := 18.0
var _chance := 0.4
var _token := 0
var _audio_token := 0


func _ready() -> void:
	_rng.randomize()
	_build_overlay()


func start_profile(profile: String) -> void:
	match profile:
		"cycle2_normal":
			start_random(10.0, 22.0, 0.35)
		"cycle2_form":
			start_random(8.0, 15.0, 0.4)
		"cycle3_normal":
			start_random(7.0, 15.0, 0.55)
		"cycle3_form":
			start_random(6.0, 12.0, 0.5)
		_:
			stop()


func start_random(min_interval: float, max_interval: float, chance: float) -> void:
	_min_interval = min_interval
	_max_interval = maxf(min_interval, max_interval)
	_chance = clampf(chance, 0.0, 1.0)
	_active = true
	_token += 1
	_random_loop(_token)


func stop() -> void:
	_active = false
	_triggering = false
	_token += 1
	if _audio != null:
		_audio_token += 1
		_audio.stop()
	if _image != null:
		_image.visible = false
	if _overlay != null:
		_overlay.visible = false


func trigger_once() -> void:
	if _triggering:
		return
	await _play_screamer()


func _random_loop(token: int) -> void:
	while _active and token == _token:
		await get_tree().create_timer(_rng.randf_range(_min_interval, _max_interval)).timeout
		if not _active or token != _token:
			return
		if _rng.randf() <= _chance:
			await _play_screamer()


func _build_overlay() -> void:
	_layer = CanvasLayer.new()
	_layer.name = "ScreamerLayer"
	_layer.layer = 120
	add_child(_layer)

	_image = TextureRect.new()
	_image.name = "ScreamerImage"
	_image.visible = false
	_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_layer.add_child(_image)

	_overlay = ColorRect.new()
	_overlay.name = "ScreamerGlitchOverlay"
	_overlay.visible = false
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_overlay)

	_audio = AudioStreamPlayer.new()
	_audio.name = "ScreamerJumpscare"
	_audio.stream = load(JUMPSCARE_AUDIO_PATH) as AudioStream
	_audio.volume_db = 0.0
	_audio.bus = &"SFX"
	add_child(_audio)


func _play_screamer() -> void:
	if _image == null or _overlay == null:
		return

	_triggering = true
	var texture_path: String = SCREAMER_TEXTURE_PATHS[_rng.randi_range(0, SCREAMER_TEXTURE_PATHS.size() - 1)]
	_image.texture = load(texture_path) as Texture2D
	_image.visible = true
	_overlay.visible = true
	_image.modulate.a = 1.0
	if _audio != null and _audio.stream != null:
		_audio.stop()
		_audio.play(0.0)
		_audio_token += 1
		_stop_screamer_audio_after_delay(_audio_token)

	var start_position := _image.position
	var glitch_colors := [
		Color(0.85, 0.0, 1.0, 0.25),
		Color(1.0, 0.08, 0.72, 0.25),
		Color(0.1, 1.0, 0.35, 0.22)
	]

	for shake_index in range(_rng.randi_range(6, 12)):
		if not _active:
			break
		var shake_offset := Vector2(_rng.randf_range(-18.0, 18.0), _rng.randf_range(-10.0, 10.0))
		_image.position = start_position + shake_offset
		_image.modulate = Color(1.0, _rng.randf_range(0.65, 1.0), _rng.randf_range(0.75, 1.0), _rng.randf_range(0.65, 1.0))
		_overlay.color = glitch_colors[_rng.randi_range(0, glitch_colors.size() - 1)]
		_overlay.modulate.a = _rng.randf_range(0.35, 0.9)
		await get_tree().create_timer(0.035).timeout

	_image.position = start_position
	_image.visible = false
	_image.modulate = Color.WHITE
	_overlay.visible = false
	_overlay.modulate.a = 0.0
	_triggering = false


func _stop_screamer_audio_after_delay(audio_token: int) -> void:
	await get_tree().create_timer(JUMPSCARE_AUDIO_DURATION).timeout
	if _audio != null and audio_token == _audio_token:
		_audio.stop()
