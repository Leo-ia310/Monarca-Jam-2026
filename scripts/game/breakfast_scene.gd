extends Control

const NEXT_SCENE_PATH := "res://scenes/game/exit_scene.tscn"

@export var fade_in_duration: float = 2.5
@export var fade_out_duration: float = 2.5
@export var transition_zoom_scale: float = 1.05

@onready var background := $Background as TextureRect
@onready var dialogue_box := $DialogueBox
@onready var fade_rect := $FadeRect as ColorRect
@onready var cup_audio := $CupAudio as AudioStreamPlayer
@onready var sip_audio := $SipAudio as AudioStreamPlayer

var _transition_started := false


func _ready() -> void:
	dialogue_box.line_started.connect(_on_dialogue_line_started)
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	dialogue_box.visible = false
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	_update_transition_pivot()
	background.scale = Vector2.ONE * transition_zoom_scale
	await _play_intro_transition()
	dialogue_box.start_dialogue([
		{
			"speaker": "???",
			"text": "2 de azúcar y un poco de leche..."
		},
		{
			"speaker": "???",
			"text": "Y listo, una taza perfecta de café."
		},
		{
			"speaker": "???",
			"text": "*toma un trago*"
		},
		{
			"speaker": "???",
			"text": "Café, ¿qué haría sin ti?"
		},
		{
			"speaker": "???",
			"text": "Eres lo más lindo de mis mañanas."
		},
		{
			"speaker": "???",
			"text": "Bueno, este lugar no es tan malo."
		},
		{
			"speaker": "???",
			"text": "Esperaba más por parte de [b]COGNIS SYSTEMS[/b]."
		},
		{
			"speaker": "???",
			"text": "Pero bueno, supongo que los fondos se desvían a otro lado. Quién sabe."
		},
		{
			"speaker": "",
			"text": "La ventana ofrece una vista de la ciudad que comienza a despertar."
		},
		{
			"speaker": "",
			"text": "Las cortinas dejan pasar algunos rayos de sol."
		},
		{
			"speaker": "",
			"text": "Los sonidos del exterior se filtran suavemente al interior."
		},
		{
			"speaker": "",
			"text": "Por un momento, todo parece seguir su rutina habitual."
		}
	])


func _on_dialogue_line_started() -> void:
	if dialogue_box.current_line == 1 and cup_audio != null and cup_audio.stream != null:
		cup_audio.play()
	elif dialogue_box.current_line == 2 and sip_audio != null and sip_audio.stream != null:
		sip_audio.play()


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


func _update_transition_pivot() -> void:
	background.pivot_offset = Vector2(get_viewport_rect().size) * 0.5


func _go_to_next_scene() -> void:
	dialogue_box.visible = false
	_update_transition_pivot()
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0

	var transition_tween := create_tween()
	transition_tween.set_parallel(true)
	transition_tween.tween_property(fade_rect, "modulate:a", 1.0, fade_out_duration)
	transition_tween.tween_property(background, "scale", Vector2.ONE * transition_zoom_scale, fade_out_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await transition_tween.finished

	get_tree().change_scene_to_file(NEXT_SCENE_PATH)
