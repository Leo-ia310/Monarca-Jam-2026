extends Control

const COGNIS_WELCOME_PATH := "res://scenes/story/cognis_welcome.tscn"

@export var message_hold_duration: float = 2.2
@export var fade_duration: float = 1.2

@onready var message_label := $MessageLabel as Label
@onready var fade_rect := $FadeRect as ColorRect


func _ready() -> void:
	message_label.modulate.a = 0.0
	fade_rect.modulate.a = 0.0
	var intro_tween := create_tween()
	intro_tween.tween_property(message_label, "modulate:a", 1.0, fade_duration)
	await intro_tween.finished
	await get_tree().create_timer(message_hold_duration).timeout

	var exit_tween := create_tween()
	exit_tween.set_parallel(true)
	exit_tween.tween_property(message_label, "modulate:a", 0.0, fade_duration)
	exit_tween.tween_property(fade_rect, "modulate:a", 1.0, fade_duration)
	await exit_tween.finished
	get_tree().change_scene_to_file(COGNIS_WELCOME_PATH)
