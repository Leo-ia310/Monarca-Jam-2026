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

var _key_background_started := false
var _transition_started := false


func _ready() -> void:
	dialogue_box.line_started.connect(_on_dialogue_line_started)
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	dialogue_box.visible = false
	fade_rect.visible = true
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 1.0
	await _play_intro_transition()
	dialogue_box.start_dialogue([
		{
			"speaker": "",
			"text": "No se me olvida nada, ¿verdad?"
		},
		{
			"speaker": "",
			"text": "Que tengas un buen dia..."
		},
		{
			"speaker": "",
			"text": "eh..."
		},
		{
			"speaker": "",
			"text": "¿Que fue eso?"
		},
		{
			"speaker": "",
			"text": "Mmm... he..."
		},
		{
			"speaker": "",
			"text": "Creo que seria mejor irme ya."
		}
	])


func _on_dialogue_line_started() -> void:
	if dialogue_box.current_line == 0:
		if keys_audio != null and keys_audio.stream != null:
			keys_audio.play()
		if not _key_background_started:
			_key_background_started = true
			_swap_to_key_background()
	elif dialogue_box.current_line == 1:
		_play_glitch()


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


func _play_glitch() -> void:
	if glitch_static_audio != null and glitch_static_audio.stream != null:
		glitch_static_audio.play()


func _go_to_next_scene() -> void:
	dialogue_box.visible = false
	fade_rect.visible = true
	fade_rect.color = Color.WHITE
	fade_rect.modulate.a = 0.0

	var transition_tween := create_tween()
	transition_tween.tween_property(fade_rect, "modulate:a", 1.0, fade_out_duration)
	await transition_tween.finished

	get_tree().change_scene_to_file(NEXT_SCENE_PATH)
