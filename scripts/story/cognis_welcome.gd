extends Control

const NEXT_SCENE_PATH := "res://scenes/game/bedroom_scene.tscn"
const TYPING_AUDIO_START_SECONDS := 7.0

@export var fade_in_duration: float = 0.7
@export var fade_out_duration: float = 2.5
@export var intro_delay: float = 2.5
@export var characters_per_second: float = 95.0
@export var transition_zoom_scale: float = 1.05

@onready var background := $Background as TextureRect
@onready var content_root := $PageMargin/ContentRoot as VBoxContainer
@onready var story_text := $PageMargin/ContentRoot/StoryText as RichTextLabel
@onready var continue_label := $PageMargin/ContentRoot/ContinueLabel as Label
@onready var fade_rect := $FadeRect as ColorRect
@onready var typing_audio := $TypingAudio as AudioStreamPlayer

var _input_locked := true
var _transition_started := false
var _is_typing := false
var _current_character := 0
var _character_progress := 0.0
var _typing_text := ""
var _fade_tween: Tween
var _continue_tween: Tween


func _ready() -> void:
	content_root.modulate.a = 0.0
	continue_label.visible = false
	continue_label.modulate.a = 1.0
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	_update_transition_pivots()
	story_text.visible_characters = 0
	_typing_text = story_text.get_parsed_text()
	_play_intro_sequence()


func _exit_tree() -> void:
	if typing_audio != null:
		typing_audio.stop()


func _process(delta: float) -> void:
	if not _is_typing:
		return

	var previous_character := _current_character
	_character_progress += characters_per_second * delta
	_current_character = mini(int(_character_progress), story_text.get_total_character_count())

	if _current_character != previous_character:
		story_text.visible_characters = _current_character
		_play_typing_audio(previous_character, _current_character)

	if _current_character >= story_text.get_total_character_count():
		_finish_typing()


func _unhandled_input(event: InputEvent) -> void:
	if _transition_started:
		return

	if event.is_action_pressed("story_continue") and not event.is_echo():
		if _is_typing:
			_reveal_story_text()
			get_viewport().set_input_as_handled()
			return

		if _input_locked:
			return

		_transition_started = true
		_input_locked = true
		get_viewport().set_input_as_handled()
		_go_to_next_scene()


func _play_intro_sequence() -> void:
	if intro_delay > 0.0:
		await get_tree().create_timer(intro_delay).timeout

	_fade_tween = create_tween()
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(fade_rect, "modulate:a", 0.0, fade_in_duration)
	_fade_tween.tween_property(content_root, "modulate:a", 1.0, fade_in_duration)
	_fade_tween.finished.connect(_on_fade_in_finished)


func _on_fade_in_finished() -> void:
	_start_typing()


func _start_typing() -> void:
	_input_locked = true
	_is_typing = true
	_current_character = 0
	_character_progress = 0.0
	story_text.visible_characters = 0


func _reveal_story_text() -> void:
	_current_character = story_text.get_total_character_count()
	_character_progress = float(_current_character)
	story_text.visible_characters = _current_character
	_finish_typing()


func _finish_typing() -> void:
	if not _is_typing:
		return

	_is_typing = false
	if typing_audio != null:
		typing_audio.stop()

	_input_locked = false
	continue_label.visible = true
	_start_continue_blink()


func _start_continue_blink() -> void:
	_continue_tween = create_tween()
	_continue_tween.set_loops()
	_continue_tween.tween_property(continue_label, "modulate:a", 0.35, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_continue_tween.tween_property(continue_label, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _go_to_next_scene() -> void:
	if is_instance_valid(_continue_tween):
		_continue_tween.kill()

	if typing_audio != null:
		typing_audio.stop()

	_update_transition_pivots()
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	_fade_tween = create_tween()
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(fade_rect, "modulate:a", 1.0, fade_out_duration)
	_fade_tween.tween_property(background, "scale", Vector2.ONE * transition_zoom_scale, fade_out_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_fade_tween.tween_property(content_root, "modulate:a", 0.0, fade_out_duration * 0.45)
	await _fade_tween.finished

	get_tree().change_scene_to_file(NEXT_SCENE_PATH)


func _play_typing_audio(from_character: int, to_character: int) -> void:
	if typing_audio == null or typing_audio.stream == null:
		return

	for character_index in range(from_character, to_character):
		var character := _typing_text.substr(character_index, 1)
		if _should_play_typing_audio(character):
			if not typing_audio.playing:
				typing_audio.play(TYPING_AUDIO_START_SECONDS)
			return


func _should_play_typing_audio(character: String) -> bool:
	return not character in [" ", "\n", "\t", ".", ",", ";", ":", "!", "?", "¿", "¡", "\"", "'", "(", ")", "[", "]"]


func _update_transition_pivots() -> void:
	var viewport_size := Vector2(get_viewport_rect().size)
	background.pivot_offset = viewport_size * 0.5
	content_root.pivot_offset = content_root.size * 0.5
