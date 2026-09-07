extends Control

const NEXT_SCENE_PATH := "res://scenes/game/salidaciclo2.tscn"
const HEART_BACKGROUND_1 := preload("res://assets/ui/desayuno_ciclo2_heart_1.png")
const HEART_BACKGROUND_2 := preload("res://assets/ui/desayuno_ciclo2_heart_2.png")

@export var fade_in_duration: float = 2.5
@export var fade_out_duration: float = 2.5
@export var transition_zoom_scale: float = 1.05
@export var heartbeat_frame_duration: float = 0.7

@onready var background := $Background as TextureRect
@onready var dialogue_box := $DialogueBox
@onready var fade_rect := $FadeRect as ColorRect
@onready var cup_audio := $CupAudio as AudioStreamPlayer
@onready var sip_audio := $SipAudio as AudioStreamPlayer
@onready var heartbeat_audio := $HeartbeatAudio as AudioStreamPlayer

var _transition_started := false
var _heartbeat_frame := 0


func _ready() -> void:
	ScreamerManager.start_profile("cycle2_normal")
	dialogue_box.line_started.connect(_on_dialogue_line_started)
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	dialogue_box.visible = false
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	_update_transition_pivot()
	background.scale = Vector2.ONE * transition_zoom_scale
	_start_heartbeat_background_loop()
	if heartbeat_audio != null and heartbeat_audio.stream != null:
		heartbeat_audio.play()
	await _play_intro_transition()
	dialogue_box.start_dialogue([
		{
			"speaker": "???",
			"emotion": "scared",
			"text": "No entiendo...\n¿Qué me sucede?"
		},
		{
			"speaker": "???",
			"emotion": "scared",
			"text": "Esta mañana ha sido extraña."
		},
		{
			"speaker": "???",
			"emotion": "scared",
			"text": "Siento miedo, angustia, terror."
		},
		{
			"speaker": "???",
			"emotion": "scared",
			"text": "Solo necesito una taza de..."
		},
		{
			"speaker": "???",
			"emotion": "sad",
			"text": "De cafe."
		},
		{
			"speaker": "???",
			"emotion": "sad",
			"text": "*toma un sorbo*"
		},
		{
			"speaker": "???",
			"emotion": "sad",
			"text": "Ahg... detesto el cafe."
		},
		{
			"speaker": "???",
			"emotion": "sad",
			"text": "No se por que pense\nque iba a querer esto."
		},
		{
			"speaker": "???",
			"emotion": "sad",
			"text": "Mejor un te."
		},
		{
			"speaker": "???",
			"emotion": "sad",
			"text": "Algo mas suave...\ncualquier cosa menos cafe."
		}
	])


func _exit_tree() -> void:
	ScreamerManager.stop()
	if heartbeat_audio != null:
		heartbeat_audio.stop()


func _start_heartbeat_background_loop() -> void:
	background.texture = HEART_BACKGROUND_1
	_heartbeat_frame = 0
	_heartbeat_background_loop()


func _heartbeat_background_loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(heartbeat_frame_duration).timeout
		if not is_inside_tree():
			return
		_heartbeat_frame = 1 - _heartbeat_frame
		background.texture = HEART_BACKGROUND_1 if _heartbeat_frame == 0 else HEART_BACKGROUND_2


func _on_dialogue_line_started() -> void:
	if dialogue_box.current_line == 3 and cup_audio != null and cup_audio.stream != null:
		cup_audio.play()
	elif dialogue_box.current_line == 4 and sip_audio != null and sip_audio.stream != null:
		sip_audio.play()


func _on_dialogue_finished() -> void:
	if _transition_started:
		return

	_transition_started = true
	if heartbeat_audio != null:
		heartbeat_audio.stop()
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
