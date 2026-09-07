extends Control

const NEXT_SCENE_PATH := "res://scenes/game/formulariociclo2.tscn"

@export var fade_in_duration: float = 2.5
@export var fade_out_duration: float = 2.5
@export var key_background_texture: Texture2D

@onready var background := $Background as TextureRect
@onready var dialogue_box := $DialogueBox
@onready var fade_rect := $FadeRect as ColorRect
@onready var keys_audio := $KeysAudio as AudioStreamPlayer
@onready var glitch_static_audio := $GlitchStaticAudio as AudioStreamPlayer
@onready var glitch_overlay := $GlitchOverlay as ColorRect
@onready var glitch_eyes := $GlitchEyes as TextureRect

var _key_background_started := false
var _transition_started := false
var _rng := RandomNumberGenerator.new()
var _background_start_position := Vector2.ZERO
var _dialogue_start_position := Vector2.ZERO
var _glitch_eyes_start_position := Vector2.ZERO


func _ready() -> void:
	_rng.randomize()
	dialogue_box.line_started.connect(_on_dialogue_line_started)
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	dialogue_box.visible = false
	glitch_overlay.visible = false
	glitch_overlay.modulate.a = 0.0
	glitch_eyes.visible = false
	glitch_eyes.modulate.a = 0.0
	fade_rect.visible = true
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 1.0
	_background_start_position = background.position
	_dialogue_start_position = dialogue_box.position
	_glitch_eyes_start_position = glitch_eyes.position
	await _play_intro_transition()
	dialogue_box.start_dialogue([
		{
			"speaker": "",
			"text": "Una vez lista,\ny sin entender completamente..."
		},
		{
			"speaker": "",
			"text": "la situación en la que se encuentra..."
		},
		{
			"speaker": "",
			"text": "sale de la casa."
		},
		{
			"speaker": "",
			"text": "Y decide ignorar\nlos sucesos de la mañana."
		},
		{
			"speaker": "???",
			"emotion": "sad",
			"text": "*suspira*"
		},
		{
			"speaker": "???",
			"emotion": "sad",
			"text": "Espero que este pueda ser\nun buen día en el trabajo."
		},
		{
			"speaker": "???",
			"emotion": "scared",
			"text": "necesito un respiro."
		},
		{
			"speaker": "???",
			"emotion": "scared",
			"text": "Algo que me permita\nescapar de esta locura."
		},
		{
			"speaker": "???",
			"emotion": "scared",
			"text": "No se me olvida nada, ¿verdad?"
		},
		{
			"speaker": "???",
			"emotion": "happy",
			"text": "Que tengas un buen dia..."
		},
		{
			"speaker": "???",
			"emotion": "scared",
			"text": "eh..."
		},
		{
			"speaker": "???",
			"emotion": "scared",
			"text": "¿Que fue eso?"
		},
		{
			"speaker": "???",
			"emotion": "scared",
			"text": "Mmm... he..."
		},
		{
			"speaker": "???",
			"emotion": "scared",
			"text": "Creo que seria mejor irme ya."
		}
	])


func _on_dialogue_line_started() -> void:
	if dialogue_box.current_line == 3:
		if keys_audio != null and keys_audio.stream != null:
			keys_audio.play()
		if not _key_background_started:
			_key_background_started = true
			_swap_to_key_background()
			_play_glitch(false, 8)
	elif dialogue_box.current_line == 4:
		_play_glitch(true, 12)


func _on_dialogue_finished() -> void:
	if _transition_started:
		return

	_transition_started = true
	_go_to_next_scene()


func _play_intro_transition() -> void:
	var transition_tween := create_tween()
	transition_tween.tween_property(fade_rect, "modulate:a", 0.0, fade_in_duration)
	await transition_tween.finished
	fade_rect.visible = false


func _swap_to_key_background() -> void:
	if key_background_texture == null:
		return

	background.texture = key_background_texture


func _play_glitch(show_eyes: bool = true, shake_count: int = 12) -> void:
	if glitch_static_audio != null and glitch_static_audio.stream != null:
		glitch_static_audio.stop()
		glitch_static_audio.play()

	glitch_overlay.visible = true
	glitch_eyes.visible = show_eyes
	var glitch_colors := [
		Color(0.85, 0.0, 1.0, 0.22),
		Color(1.0, 0.08, 0.72, 0.22),
		Color(0.1, 1.0, 0.35, 0.18)
	]

	for shake_index in range(shake_count):
		var shake_offset := Vector2(_rng.randf_range(-8.0, 8.0), _rng.randf_range(-5.0, 5.0))
		background.position = _background_start_position + shake_offset * 0.35
		dialogue_box.position = _dialogue_start_position + shake_offset
		glitch_eyes.position = _glitch_eyes_start_position - shake_offset * 0.45
		glitch_eyes.modulate.a = _rng.randf_range(0.62, 1.0) if show_eyes else 0.0
		glitch_overlay.color = glitch_colors[_rng.randi_range(0, glitch_colors.size() - 1)]
		glitch_overlay.modulate.a = _rng.randf_range(0.32, 0.72)
		await get_tree().create_timer(0.035).timeout

	background.position = _background_start_position
	dialogue_box.position = _dialogue_start_position
	glitch_eyes.position = _glitch_eyes_start_position
	glitch_eyes.modulate.a = 0.0
	glitch_eyes.visible = false
	glitch_overlay.modulate.a = 0.0
	glitch_overlay.visible = false


func _go_to_next_scene() -> void:
	dialogue_box.visible = false
	fade_rect.visible = true
	fade_rect.color = Color.WHITE
	fade_rect.modulate.a = 0.0

	var transition_tween := create_tween()
	transition_tween.tween_property(fade_rect, "modulate:a", 1.0, fade_out_duration)
	await transition_tween.finished

	get_tree().change_scene_to_file(NEXT_SCENE_PATH)
