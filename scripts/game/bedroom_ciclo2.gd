extends Control

@export var fade_in_duration: float = 2.5
@export var alarm_duration: float = 4.0
@export var transition_zoom_scale: float = 1.05

@onready var background := $Background as TextureRect
@onready var dialogue_box := $DialogueBox
@onready var fade_rect := $FadeRect as ColorRect
@onready var alarm_audio := $AlarmAudio as AudioStreamPlayer


func _ready() -> void:
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
			"text": "mmm, *busca algo al lado de ella*"
		},
		{
			"speaker": "",
			"text": "No, no esta, oh que?"
		},
		{
			"speaker": "",
			"text": "*bosteza* aun tengo mucho sueño"
		}
	])


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
