extends Control

const NEXT_SCENE_PATH := "res://scenes/game/desayunociclo3.tscn"

@export var fade_in_duration: float = 2.5
@export var transition_zoom_scale: float = 1.05
@export var transform_delay: float = 0.6
@export var hold_after_transform_duration: float = 2.2

@onready var background := $Background as TextureRect
@onready var character := $Character as TextureRect
@onready var fragment_character := $FragmentCharacter as TextureRect
@onready var fade_rect := $FadeRect as ColorRect
@onready var sink_audio := $SinkAudio as AudioStreamPlayer
@onready var glitch_audio := $GlitchAudio as AudioStreamPlayer
@onready var glitch_overlay := $GlitchOverlay as ColorRect
@onready var dialogue_box := $DialogueBox

var _rng := RandomNumberGenerator.new()
var _background_start_position := Vector2.ZERO
var _character_start_position := Vector2.ZERO
var _fragment_start_position := Vector2.ZERO
var _transition_started := false


func _ready() -> void:
	ScreamerManager.start_profile("cycle3_normal")
	_rng.randomize()
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	dialogue_box.visible = false
	fragment_character.visible = false
	glitch_overlay.visible = false
	glitch_overlay.modulate.a = 0.0
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	_background_start_position = background.position
	_character_start_position = character.position
	_fragment_start_position = fragment_character.position
	_update_transition_pivots()
	background.scale = Vector2.ONE * transition_zoom_scale
	character.scale = Vector2.ONE * transition_zoom_scale
	fragment_character.scale = Vector2.ONE * transition_zoom_scale
	if sink_audio != null and sink_audio.stream != null:
		sink_audio.play()
	await _play_intro_transition()
	await get_tree().create_timer(transform_delay).timeout
	await _play_transformation_glitch()
	await get_tree().create_timer(hold_after_transform_duration).timeout
	dialogue_box.start_dialogue([
		{
			"speaker": "Narrador",
			"text": "Miraba hacia el abismo, no era dueño de su cuerpo."
		},
		{
			"speaker": "Narrador",
			"text": "Como un ente sin alma."
		},
		{
			"speaker": "???",
			"emotion": "scared",
			"text": "El agente imito al sujeto; segunda carne."
		},
		{
			"speaker": "???",
			"emotion": "scared",
			"text": "Sus ojos recuerdan lo que nunca vio."
		},
		{
			"speaker": "???",
			"emotion": "sad",
			"text": "Quien investiga y combate la oscuridad termina siendo contaminado por ella."
		}
	])


func _exit_tree() -> void:
	ScreamerManager.stop()
	if sink_audio != null:
		sink_audio.stop()


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
	transition_tween.tween_property(character, "scale", Vector2.ONE, fade_in_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	transition_tween.tween_property(fragment_character, "scale", Vector2.ONE, fade_in_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await transition_tween.finished
	fade_rect.visible = false


func _play_transformation_glitch() -> void:
	if glitch_audio != null and glitch_audio.stream != null:
		glitch_audio.stop()
		glitch_audio.play()

	character.visible = false
	fragment_character.visible = true
	glitch_overlay.visible = true
	var glitch_colors := [
		Color(0.85, 0.0, 1.0, 0.24),
		Color(1.0, 0.08, 0.72, 0.24),
		Color(0.1, 1.0, 0.35, 0.2)
	]

	for shake_index in range(14):
		var shake_offset := Vector2(_rng.randf_range(-9.0, 9.0), _rng.randf_range(-6.0, 6.0))
		background.position = _background_start_position + shake_offset * 0.35
		character.position = _character_start_position + shake_offset
		fragment_character.position = _fragment_start_position + shake_offset
		glitch_overlay.color = glitch_colors[_rng.randi_range(0, glitch_colors.size() - 1)]
		glitch_overlay.modulate.a = _rng.randf_range(0.45, 0.9)
		await get_tree().create_timer(0.035).timeout

	background.position = _background_start_position
	character.position = _character_start_position
	fragment_character.position = _fragment_start_position
	glitch_overlay.modulate.a = 0.0
	glitch_overlay.visible = false


func _update_transition_pivots() -> void:
	var viewport_center := Vector2(get_viewport_rect().size) * 0.5
	background.pivot_offset = viewport_center
	character.pivot_offset = character.size * 0.5
	fragment_character.pivot_offset = fragment_character.size * 0.5
