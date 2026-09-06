extends Control

const NEXT_SCENE_PATH := "res://scenes/game/formulario1.tscn"

@export var fade_in_duration: float = 2.5
@export var fade_out_duration: float = 2.5
@export var key_background_texture: Texture2D

@onready var background := $Background as TextureRect
@onready var dialogue_box := $DialogueBox
@onready var fade_rect := $FadeRect as ColorRect
@onready var keys_audio := $KeysAudio as AudioStreamPlayer

var _transition_started := false
var _key_background_started := false


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
			"text": "No olvido nada, ¿verdad?"
		},
		{
			"speaker": "",
			"text": "Creo que no."
		},
		{
			"speaker": "",
			"text": "Pero qué emoción haber clasificado..."
		},
		{
			"speaker": "",
			"text": "Espero que todo salga bien."
		}
	])


func _on_dialogue_line_started() -> void:
	if dialogue_box.current_line != 3:
		return

	if keys_audio != null and keys_audio.stream != null:
		keys_audio.play()
	if not _key_background_started:
		_key_background_started = true
		_swap_to_key_background()


func _play_intro_transition() -> void:
	var transition_tween := create_tween()
	transition_tween.tween_property(fade_rect, "modulate:a", 0.0, fade_in_duration)
	await transition_tween.finished
	fade_rect.visible = false


func _on_dialogue_finished() -> void:
	if _transition_started:
		return

	_transition_started = true
	_go_to_next_scene()


func _go_to_next_scene() -> void:
	dialogue_box.visible = false
	fade_rect.visible = true
	fade_rect.color = Color.WHITE
	fade_rect.modulate.a = 0.0

	var transition_tween := create_tween()
	transition_tween.tween_property(fade_rect, "modulate:a", 1.0, fade_out_duration)
	await transition_tween.finished

	get_tree().change_scene_to_file(NEXT_SCENE_PATH)


func _swap_to_key_background() -> void:
	if key_background_texture == null:
		return

	background.texture = key_background_texture
