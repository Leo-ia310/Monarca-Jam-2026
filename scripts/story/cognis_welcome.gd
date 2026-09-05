extends Control

const NEXT_SCENE_PATH := "res://scenes/game/game_placeholder.tscn"
# TODO: reemplazar por habitación real.

@export var fade_in_duration: float = 0.7
@export var fade_out_duration: float = 0.6
@export var intro_delay: float = 2.5

@onready var content_root := $PageMargin/ContentRoot as VBoxContainer
@onready var continue_label := $PageMargin/ContentRoot/ContinueLabel as Label
@onready var fade_rect := $FadeRect as ColorRect

var _input_locked := true
var _transition_started := false
var _fade_tween: Tween
var _continue_tween: Tween


func _ready() -> void:
	content_root.modulate.a = 0.0
	continue_label.modulate.a = 1.0
	fade_rect.modulate.a = 1.0
	_play_intro_sequence()


func _unhandled_input(event: InputEvent) -> void:
	if _input_locked or _transition_started:
		return

	if event.is_action_pressed("story_continue") and not event.is_echo():
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
	_input_locked = false
	_start_continue_blink()


func _start_continue_blink() -> void:
	_continue_tween = create_tween()
	_continue_tween.set_loops()
	_continue_tween.tween_property(continue_label, "modulate:a", 0.35, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_continue_tween.tween_property(continue_label, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _go_to_next_scene() -> void:
	if is_instance_valid(_continue_tween):
		_continue_tween.kill()

	fade_rect.modulate.a = 0.0
	_fade_tween = create_tween()
	_fade_tween.tween_property(fade_rect, "modulate:a", 1.0, fade_out_duration)
	await _fade_tween.finished

	get_tree().change_scene_to_file(NEXT_SCENE_PATH)
