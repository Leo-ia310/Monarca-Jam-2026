extends Control

const NEXT_SCENE_PATH := "res://scenes/game/bathroom_scene.tscn"

@export var fade_in_duration: float = 2.5
@export var fade_out_duration: float = 5.0
@export var footsteps_duration: float = 4.0
@export var alarm_duration: float = 4.0
@export var transition_zoom_scale: float = 1.05

@onready var background := $Background as TextureRect
@onready var dialogue_box := $DialogueBox
@onready var fade_rect := $FadeRect as ColorRect
@onready var footsteps_audio := $FootstepsAudio as AudioStreamPlayer
@onready var door_audio := $DoorAudio as AudioStreamPlayer
@onready var alarm_audio := $AlarmAudio as AudioStreamPlayer

var _transition_started := false


func _ready() -> void:
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	dialogue_box.visible = false
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	_update_transition_pivot()
	background.scale = Vector2.ONE * transition_zoom_scale
	await _play_intro_transition()
	await _play_alarm_intro()
	dialogue_box.start_dialogue([
		{
			"speaker": "",
			"text": "mmmm, 5 minutos más"
		},
		{
			"speaker": "",
			"text": "*suspiro* que pereza levantarse"
		},
		{
			"speaker": "",
			"text": "Me pregunto por qué seguiré pensando en la entrevista de trabajo."
		},
		{
			"speaker": "",
			"text": "En fin. Hay que levantarse."
		},
		{
			"speaker": "Narrador",
			"text": "La habitación parece pequeña."
		},
		{
			"speaker": "Narrador",
			"text": "Hay poco espacio entre la cama, el escritorio y el resto de los muebles."
		},
		{
			"speaker": "Narrador",
			"text": "No hay demasiadas cosas alrededor; solo lo necesario para el día a día."
		}
	])


func _on_dialogue_finished() -> void:
	if _transition_started:
		return

	_transition_started = true
	_go_to_next_scene()


func _play_intro_transition() -> void:
	var transition_tween := create_tween()
	transition_tween.set_parallel(true)
	transition_tween.tween_property(fade_rect, "modulate:a", 0.0, fade_in_duration)
	transition_tween.tween_property(background, "scale", Vector2.ONE, fade_in_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await transition_tween.finished
	fade_rect.visible = false


func _play_alarm_intro() -> void:
	if alarm_audio == null or alarm_audio.stream == null:
		return

	alarm_audio.play()
	await get_tree().create_timer(alarm_duration).timeout
	alarm_audio.stop()


func _update_transition_pivot() -> void:
	background.pivot_offset = Vector2(get_viewport_rect().size) * 0.5


func _go_to_next_scene() -> void:
	dialogue_box.visible = false
	_update_transition_pivot()
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	if footsteps_audio != null and footsteps_audio.stream != null:
		footsteps_audio.play()

	var transition_tween := create_tween()
	transition_tween.set_parallel(true)
	transition_tween.tween_property(fade_rect, "modulate:a", 1.0, fade_out_duration)
	transition_tween.tween_property(background, "scale", Vector2.ONE * transition_zoom_scale, fade_out_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await get_tree().create_timer(footsteps_duration).timeout
	if footsteps_audio != null:
		footsteps_audio.stop()
	if door_audio != null and door_audio.stream != null:
		door_audio.play()

	await transition_tween.finished
	get_tree().change_scene_to_file(NEXT_SCENE_PATH)
