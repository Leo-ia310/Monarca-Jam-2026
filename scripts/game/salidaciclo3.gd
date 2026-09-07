extends Control

const NEXT_SCENE_PATH := "res://scenes/game/desayunociclo3.tscn"

@export var fade_in_duration: float = 2.5
@export var open_delay: float = 0.7
@export var hold_after_open_duration: float = 2.2
@export var key_background_texture: Texture2D

@onready var background := $Background as TextureRect
@onready var dialogue_box := $DialogueBox
@onready var fade_rect := $FadeRect as ColorRect
@onready var keys_audio := $KeysAudio as AudioStreamPlayer
@onready var glitch_static_audio := $GlitchStaticAudio as AudioStreamPlayer
@onready var glitch_overlay := $GlitchOverlay as ColorRect
@onready var glitch_eyes := $GlitchEyes as TextureRect

var _rng := RandomNumberGenerator.new()
var _background_start_position := Vector2.ZERO
var _glitch_eyes_start_position := Vector2.ZERO


func _ready() -> void:
	ScreamerManager.start_profile("cycle3_normal")
	_rng.randomize()
	dialogue_box.visible = false
	glitch_overlay.visible = false
	glitch_overlay.modulate.a = 0.0
	glitch_eyes.visible = false
	glitch_eyes.modulate.a = 0.0
	fade_rect.visible = true
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 1.0
	_background_start_position = background.position
	_glitch_eyes_start_position = glitch_eyes.position
	await _play_intro_transition()
	await get_tree().create_timer(open_delay).timeout
	await _open_door()
	await get_tree().create_timer(hold_after_open_duration).timeout
	get_tree().change_scene_to_file(NEXT_SCENE_PATH)


func _exit_tree() -> void:
	ScreamerManager.stop()


func _play_intro_transition() -> void:
	var transition_tween := create_tween()
	transition_tween.tween_property(fade_rect, "modulate:a", 0.0, fade_in_duration)
	await transition_tween.finished
	fade_rect.visible = false


func _open_door() -> void:
	if keys_audio != null and keys_audio.stream != null:
		keys_audio.play()
	if key_background_texture != null:
		background.texture = key_background_texture
	await _play_glitch()


func _play_glitch() -> void:
	if glitch_static_audio != null and glitch_static_audio.stream != null:
		glitch_static_audio.stop()
		glitch_static_audio.play()

	glitch_overlay.visible = true
	var glitch_colors := [
		Color(0.85, 0.0, 1.0, 0.24),
		Color(1.0, 0.08, 0.72, 0.24),
		Color(0.1, 1.0, 0.35, 0.2)
	]

	for shake_index in range(14):
		var shake_offset := Vector2(_rng.randf_range(-9.0, 9.0), _rng.randf_range(-6.0, 6.0))
		background.position = _background_start_position + shake_offset * 0.35
		glitch_eyes.position = _glitch_eyes_start_position - shake_offset * 0.45
		glitch_overlay.color = glitch_colors[_rng.randi_range(0, glitch_colors.size() - 1)]
		glitch_overlay.modulate.a = _rng.randf_range(0.4, 0.85)
		await get_tree().create_timer(0.035).timeout

	background.position = _background_start_position
	glitch_eyes.position = _glitch_eyes_start_position
	glitch_overlay.modulate.a = 0.0
	glitch_overlay.visible = false
