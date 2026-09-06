extends Control

const NEXT_SCENE_PATH := "res://scenes/game/breakfast_scene.tscn"

@export var fade_in_duration: float = 2.5
@export var fade_out_duration: float = 2.5
@export var transition_zoom_scale: float = 1.05

@onready var background := $Background as TextureRect
@onready var character := $Character as TextureRect
@onready var dialogue_box := $DialogueBox
@onready var fade_rect := $FadeRect as ColorRect
@onready var sink_audio := $SinkAudio as AudioStreamPlayer

var _transition_started := false


func _ready() -> void:
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	dialogue_box.visible = false
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	_update_transition_pivots()
	background.scale = Vector2.ONE * transition_zoom_scale
	character.scale = Vector2.ONE * transition_zoom_scale
	if sink_audio != null and sink_audio.stream != null:
		sink_audio.play()
	await _play_intro_transition()
	dialogue_box.start_dialogue([
		{
			"speaker": "",
			"text": "Oh, hoy me veo genial."
		},
		{
			"speaker": "",
			"text": "Me pregunto si hoy podré salir antes del trabajo..."
		},
		{
			"speaker": "",
			"text": "Y empezar a decorar este lugar."
		}
	])


func _exit_tree() -> void:
	if sink_audio != null:
		sink_audio.stop()


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
	transition_tween.tween_property(character, "scale", Vector2.ONE, fade_in_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await transition_tween.finished
	fade_rect.visible = false


func _update_transition_pivots() -> void:
	var viewport_center := Vector2(get_viewport_rect().size) * 0.5
	background.pivot_offset = viewport_center
	character.pivot_offset = character.size * 0.5


func _go_to_next_scene() -> void:
	dialogue_box.visible = false
	if sink_audio != null:
		sink_audio.stop()
	_update_transition_pivots()
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0

	var transition_tween := create_tween()
	transition_tween.set_parallel(true)
	transition_tween.tween_property(fade_rect, "modulate:a", 1.0, fade_out_duration)
	transition_tween.tween_property(background, "scale", Vector2.ONE * transition_zoom_scale, fade_out_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	transition_tween.tween_property(character, "scale", Vector2.ONE * transition_zoom_scale, fade_out_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await transition_tween.finished

	get_tree().change_scene_to_file(NEXT_SCENE_PATH)
