extends Control

const NEXT_SCENE_PATH := "res://scenes/game/formulario3.tscn"

@export var fade_in_duration: float = 2.5
@export var transition_zoom_scale: float = 1.05
@export var hold_duration: float = 2.2

@onready var background := $Background as TextureRect
@onready var dialogue_box := $DialogueBox
@onready var fade_rect := $FadeRect as ColorRect


func _ready() -> void:
	ScreamerManager.start_profile("cycle3_normal")
	dialogue_box.visible = false
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	_update_transition_pivot()
	background.scale = Vector2.ONE * transition_zoom_scale
	await _play_intro_transition()
	await get_tree().create_timer(hold_duration).timeout
	get_tree().change_scene_to_file(NEXT_SCENE_PATH)


func _exit_tree() -> void:
	ScreamerManager.stop()


func _play_intro_transition() -> void:
	var transition_tween := create_tween()
	transition_tween.set_parallel(true)
	transition_tween.tween_property(fade_rect, "modulate:a", 0.0, fade_in_duration)
	transition_tween.tween_property(background, "scale", Vector2.ONE, fade_in_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await transition_tween.finished
	fade_rect.visible = false


func _update_transition_pivot() -> void:
	background.pivot_offset = Vector2(get_viewport_rect().size) * 0.5
