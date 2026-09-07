extends Control

const NEXT_SCENE_PATH := "res://scenes/game/salidaciclo3.tscn"

@export var fade_in_duration: float = 2.5
@export var transition_zoom_scale: float = 1.05
@export var hold_duration: float = 2.2

@onready var background := $Background as TextureRect
@onready var dialogue_box := $DialogueBox
@onready var fade_rect := $FadeRect as ColorRect
@onready var cup_audio := $CupAudio as AudioStreamPlayer
@onready var sip_audio := $SipAudio as AudioStreamPlayer

var _transition_started := false


func _ready() -> void:
	ScreamerManager.start_profile("cycle3_normal")
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	dialogue_box.visible = false
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	_update_transition_pivot()
	background.scale = Vector2.ONE * transition_zoom_scale
	await _play_intro_transition()
	if cup_audio != null and cup_audio.stream != null:
		cup_audio.play()
	await get_tree().create_timer(hold_duration).timeout
	if sip_audio != null and sip_audio.stream != null:
		sip_audio.play()
	dialogue_box.start_dialogue([
		{
			"speaker": "Narrador",
			"text": "En la mesa yacian los restos de aquello que pretendia ser."
		},
		{
			"speaker": "Narrador",
			"text": "Como si consumiendo aquello, naciera dentro del espectro del yo."
		},
		{
			"speaker": "???",
			"emotion": "sad",
			"text": "Hundo las manos en el fondo esperando tocar la verdad."
		},
		{
			"speaker": "???",
			"emotion": "sad",
			"text": "Caigo en el mismo, cedo y vuelve a cerrarse la posibilidad."
		},
		{
			"speaker": "???",
			"emotion": "sleepy",
			"text": "Sentido; residua un dejo en la lengua."
		},
		{
			"speaker": "???",
			"emotion": "sad",
			"text": "Quiza por eso sigo tragando, porque hasta un vacio necesita una garganta por la cual pasar."
		}
	])


func _exit_tree() -> void:
	ScreamerManager.stop()


func _on_dialogue_finished() -> void:
	if _transition_started:
		return

	_transition_started = true
	dialogue_box.visible = false
	get_tree().change_scene_to_file(NEXT_SCENE_PATH)


func _play_intro_transition() -> void:
	var transition_tween := create_tween()
	transition_tween.set_parallel(true)
	transition_tween.tween_property(fade_rect, "modulate:a", 0.0, fade_in_duration)
	transition_tween.tween_property(background, "scale", Vector2.ONE, fade_in_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await transition_tween.finished
	fade_rect.visible = false


func _update_transition_pivot() -> void:
	background.pivot_offset = Vector2(get_viewport_rect().size) * 0.5
