extends Control

const NEXT_SCENE_PATH := "res://scenes/game/breakfast_scene.tscn"

@export var fade_in_duration: float = 2.5
@export var fade_out_duration: float = 2.5
@export var transition_zoom_scale: float = 1.05
@export var blink_texture: Texture2D

@onready var background := $Background as TextureRect
@onready var character := $Character as TextureRect
@onready var dialogue_box := $DialogueBox
@onready var fade_rect := $FadeRect as ColorRect
@onready var sink_audio := $SinkAudio as AudioStreamPlayer

var _transition_started := false
var _normal_texture: Texture2D
var _blinking_active := true
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_normal_texture = character.texture
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	dialogue_box.visible = false
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	_update_transition_pivots()
	background.scale = Vector2.ONE * transition_zoom_scale
	character.scale = Vector2.ONE * transition_zoom_scale
	if sink_audio != null and sink_audio.stream != null:
		sink_audio.play()
	_start_blink_loop()
	await _play_intro_transition()
	dialogue_box.start_dialogue([
		{
			"speaker": "???",
			"text": "Oh, hoy me veo genial."
		},
		{
			"speaker": "???",
			"text": "Me pregunto si hoy podré salir antes del trabajo..."
		},
		{
			"speaker": "???",
			"text": "Y empezar a decorar este lugar."
		},
		{
			"speaker": "",
			"text": "El baño es pequeño y sencillo."
		},
		{
			"speaker": "",
			"text": "Tiene únicamente lo necesario para el día a día:"
		},
		{
			"speaker": "",
			"text": "Un lavabo, un espejo, una ducha..."
		},
		{
			"speaker": "",
			"text": "Y algunos productos de higiene personal."
		},
		{
			"speaker": "",
			"text": "Todo está ordenado y en su lugar."
		}
	])


func _exit_tree() -> void:
	_blinking_active = false
	if sink_audio != null:
		sink_audio.stop()


func _on_dialogue_finished() -> void:
	if _transition_started:
		return

	_transition_started = true
	_blinking_active = false
	_go_to_next_scene()


func _start_blink_loop() -> void:
	if blink_texture == null or _normal_texture == null:
		return
	_blink_loop()


func _blink_loop() -> void:
	while is_inside_tree() and _blinking_active:
		await get_tree().create_timer(_rng.randf_range(2.0, 4.2)).timeout
		if not is_inside_tree() or not _blinking_active:
			break
		character.texture = blink_texture
		await get_tree().create_timer(_rng.randf_range(0.13, 0.2)).timeout
		if is_inside_tree():
			character.texture = _normal_texture


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
