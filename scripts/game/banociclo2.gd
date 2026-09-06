extends Control

const NEXT_SCENE_PATH := "res://scenes/game/desayunociclo2.tscn"

@export var fade_in_duration: float = 2.5
@export var fade_out_duration: float = 2.5
@export var transition_zoom_scale: float = 1.05
@export var blink_texture: Texture2D

@onready var background := $Background as TextureRect
@onready var character := $Character as TextureRect
@onready var fragment_character := $FragmentCharacter as TextureRect
@onready var dialogue_box := $DialogueBox
@onready var fade_rect := $FadeRect as ColorRect
@onready var sink_audio := $SinkAudio as AudioStreamPlayer
@onready var glitch_audio := $GlitchAudio as AudioStreamPlayer
@onready var glitch_overlay := $GlitchOverlay as ColorRect

var _transition_started := false
var _fragment_glitch_played := false
var _rng := RandomNumberGenerator.new()
var _background_start_position := Vector2.ZERO
var _character_start_position := Vector2.ZERO
var _fragment_start_position := Vector2.ZERO
var _normal_texture: Texture2D
var _blinking_active := true


func _ready() -> void:
	_rng.randomize()
	_normal_texture = character.texture
	dialogue_box.line_started.connect(_on_dialogue_line_started)
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
	_start_blink_loop()
	await _play_intro_transition()
	dialogue_box.start_dialogue([
		{
			"speaker": "",
			"text": "Deberia de llamar a mama."
		},
		{
			"speaker": "",
			"text": "Hace rato que no hablo con ella."
		},
		{
			"speaker": "",
			"text": "*se mire al espejo*"
		},
		{
			"speaker": "",
			"text": "..."
		},
		{
			"speaker": "",
			"text": "yo..."
		}
	])


func _exit_tree() -> void:
	_blinking_active = false
	if sink_audio != null:
		sink_audio.stop()


func _on_dialogue_line_started() -> void:
	if dialogue_box.current_line != 3:
		return

	character.visible = false
	_blinking_active = false
	fragment_character.visible = true
	if not _fragment_glitch_played:
		_fragment_glitch_played = true
		_play_fragment_glitch()


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


func _play_fragment_glitch() -> void:
	if glitch_audio != null and glitch_audio.stream != null:
		glitch_audio.stop()
		glitch_audio.play()

	glitch_overlay.visible = true
	var glitch_colors := [
		Color(0.85, 0.0, 1.0, 0.22),
		Color(1.0, 0.08, 0.72, 0.22),
		Color(0.1, 1.0, 0.35, 0.18)
	]

	for shake_index in range(12):
		var shake_offset := Vector2(_rng.randf_range(-8.0, 8.0), _rng.randf_range(-5.0, 5.0))
		background.position = _background_start_position + shake_offset * 0.35
		character.position = _character_start_position + shake_offset
		fragment_character.position = _fragment_start_position + shake_offset
		glitch_overlay.color = glitch_colors[_rng.randi_range(0, glitch_colors.size() - 1)]
		glitch_overlay.modulate.a = _rng.randf_range(0.45, 0.85)
		await get_tree().create_timer(0.035).timeout

	background.position = _background_start_position
	character.position = _character_start_position
	fragment_character.position = _fragment_start_position
	glitch_overlay.modulate.a = 0.0
	glitch_overlay.visible = false


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
	transition_tween.tween_property(fragment_character, "scale", Vector2.ONE, fade_in_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await transition_tween.finished
	fade_rect.visible = false


func _update_transition_pivots() -> void:
	var viewport_center := Vector2(get_viewport_rect().size) * 0.5
	background.pivot_offset = viewport_center
	character.pivot_offset = character.size * 0.5
	fragment_character.pivot_offset = fragment_character.size * 0.5


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
	transition_tween.tween_property(fragment_character, "scale", Vector2.ONE * transition_zoom_scale, fade_out_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await transition_tween.finished

	get_tree().change_scene_to_file(NEXT_SCENE_PATH)
