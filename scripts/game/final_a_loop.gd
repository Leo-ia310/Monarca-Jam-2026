extends Control

enum FlowState {
	ROUTINE_DIALOGUE,
	CHOICE
}

const OFFICE_SCENE_PATH := "res://scenes/game/final_a_office.tscn"

const ROUTINE_STEPS := [
	{
		"backgrounds": [
			"res://assets/ui/bedroom_background.png",
			"res://assets/ui/bedroom_ciclo2_background.png",
			"res://assets/ui/bedroom_ciclo3_background.png"
		],
		"sound": "alarm",
		"speaker": "???",
		"emotion": "sleepy",
		"text": "¡Tengo que levantarme!"
	},
	{
		"backgrounds": [
			"res://assets/ui/bedroom_background.png",
			"res://assets/ui/bedroom_ciclo2_background.png",
			"res://assets/ui/bedroom_ciclo3_background.png"
		],
		"speaker": "Narrador",
		"text": "…"
	},
	{
		"backgrounds": ["res://assets/ui/bathroom_background.png"],
		"foregrounds": [
			"res://assets/ui/bathroom_character.png",
			"res://assets/ui/bathroom_character_fragment.png",
			"res://assets/ui/bathroom_character_ciclo3_fragment.png"
		],
		"sound": "water",
		"speaker": "???",
		"emotion": "happy",
		"text": "¡Hoy será un buen día!"
	},
	{
		"backgrounds": ["res://assets/ui/bathroom_background.png"],
		"foregrounds": [
			"res://assets/ui/bathroom_character.png",
			"res://assets/ui/bathroom_character_fragment.png",
			"res://assets/ui/bathroom_character_ciclo3_fragment.png"
		],
		"speaker": "Narrador",
		"text": "…"
	},
	{
		"backgrounds": [
			"res://assets/ui/breakfast_background.png",
			"res://assets/ui/desayuno_ciclo2_heart_1.png",
			"res://assets/ui/desayuno_ciclo3_background.png"
		],
		"sound": "coffee",
		"speaker": "???",
		"emotion": "happy",
		"text": "¡Que delicioso que estuvo el desayuno!"
	},
	{
		"backgrounds": [
			"res://assets/ui/breakfast_background.png",
			"res://assets/ui/desayuno_ciclo2_heart_1.png",
			"res://assets/ui/desayuno_ciclo3_background.png"
		],
		"speaker": "Narrador",
		"text": "…"
	},
	{
		"backgrounds": [
			"res://assets/ui/exit_background.png",
			"res://assets/ui/exit_ciclo2_door_open.png",
			"res://assets/ui/exit_ciclo3_door_open.png"
		],
		"sound": "door",
		"speaker": "???",
		"emotion": "happy",
		"text": "¡Otro día de trabajo, que emocionado que estoy!"
	},
	{
		"backgrounds": [
			"res://assets/ui/exit_background.png",
			"res://assets/ui/exit_ciclo2_door_open.png",
			"res://assets/ui/exit_ciclo3_door_open.png"
		],
		"speaker": "Narrador",
		"text": "…"
	}
]

var _state := FlowState.ROUTINE_DIALOGUE
var _selected_choice := 0
var _locked := false
var _no_attempts := 0
var _glitch_running := false
var _background_start_position := Vector2.ZERO
var _foreground_start_position := Vector2.ZERO
var _choice_start_position := Vector2.ZERO
var _dialogue_visual_token := 0
var _rng := RandomNumberGenerator.new()

@onready var background := $Background as TextureRect
@onready var foreground := $Foreground as TextureRect
@onready var glitch_copy_pink := $GlitchCopyPink as TextureRect
@onready var glitch_copy_green := $GlitchCopyGreen as TextureRect
@onready var glitch_overlay := $GlitchOverlay as ColorRect
@onready var fade_rect := $FadeRect as ColorRect
@onready var dialogue_box := $DialogueBox
@onready var choice_panel := $ChoicePanel as Control
@onready var question_label := $ChoicePanel/ChoiceMargin/ChoiceStack/QuestionLabel as Label
@onready var yes_label := $ChoicePanel/ChoiceMargin/ChoiceStack/YesLabel as Label
@onready var no_label := $ChoicePanel/ChoiceMargin/ChoiceStack/NoLabel as Label
@onready var alarm_audio := $AlarmAudio as AudioStreamPlayer
@onready var water_audio := $WaterAudio as AudioStreamPlayer
@onready var coffee_audio := $CoffeeAudio as AudioStreamPlayer
@onready var door_audio := $DoorAudio as AudioStreamPlayer
@onready var glitch_static_audio := $GlitchStaticAudio as AudioStreamPlayer
@onready var glitch_electric_audio := $GlitchElectricAudio as AudioStreamPlayer
@onready var glitch_bass_audio := $GlitchBassAudio as AudioStreamPlayer
@onready var glitch_heartbeat_audio := $GlitchHeartbeatAudio as AudioStreamPlayer


func _ready() -> void:
	_rng.randomize()
	_background_start_position = background.position
	_foreground_start_position = foreground.position
	_choice_start_position = choice_panel.position
	choice_panel.visible = false
	foreground.visible = false
	glitch_copy_pink.visible = false
	glitch_copy_green.visible = false
	glitch_overlay.visible = false
	glitch_overlay.modulate.a = 0.0
	_apply_visual_step(ROUTINE_STEPS[0])
	fade_rect.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.35)

	dialogue_box.line_started.connect(_on_dialogue_line_started)
	dialogue_box.dialogue_finished.connect(_show_office_prompt)
	dialogue_box.start_dialogue(_build_routine_dialogue())


func _unhandled_input(event: InputEvent) -> void:
	if _state != FlowState.CHOICE or _locked:
		return

	if event is InputEventMouseMotion:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_UP, KEY_W, KEY_DOWN, KEY_S:
				_selected_choice = 1 - _selected_choice
				_update_choice_view()
				get_viewport().set_input_as_handled()
				return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("dialogue_advance"):
		get_viewport().set_input_as_handled()
		if _selected_choice == 0:
			_confirm_yes()
		else:
			_play_no_glitch()


func _build_routine_dialogue() -> Array:
	var dialogue := []
	for step in ROUTINE_STEPS:
		dialogue.append({
			"speaker": str(step.get("speaker", "")),
			"emotion": str(step.get("emotion", "")),
			"text": str(step.get("text", ""))
		})
	return dialogue


func _on_dialogue_line_started() -> void:
	if _state != FlowState.ROUTINE_DIALOGUE:
		return

	var index := clampi(dialogue_box.current_line, 0, ROUTINE_STEPS.size() - 1)
	var step := ROUTINE_STEPS[index] as Dictionary
	_apply_visual_step(step)
	_start_dialogue_visual_cycle(step)
	_play_routine_sound(str(step.get("sound", "")))


func _apply_visual_step(step: Dictionary) -> void:
	var background_path := str(step.get("background", ""))
	if background_path.is_empty():
		var backgrounds := step.get("backgrounds", []) as Array
		background_path = str(backgrounds[0]) if not backgrounds.is_empty() else "res://assets/ui/exit_background.png"
	var background_texture := load(background_path) as Texture2D
	background.texture = background_texture
	glitch_copy_pink.texture = background_texture
	glitch_copy_green.texture = background_texture

	var foreground_path := str(step.get("foreground", ""))
	if foreground_path.is_empty():
		var foregrounds := step.get("foregrounds", []) as Array
		if not foregrounds.is_empty():
			foreground_path = str(foregrounds[0])
	if foreground_path.is_empty():
		foreground.visible = false
		foreground.texture = null
	else:
		foreground.texture = load(foreground_path) as Texture2D
		foreground.visible = true


func _start_dialogue_visual_cycle(step: Dictionary) -> void:
	_dialogue_visual_token += 1
	var token := _dialogue_visual_token
	var backgrounds := step.get("backgrounds", []) as Array
	var foregrounds := step.get("foregrounds", []) as Array
	var max_frames := maxi(backgrounds.size(), foregrounds.size())
	if max_frames <= 1:
		return
	_dialogue_visual_cycle(step, token)


func _dialogue_visual_cycle(step: Dictionary, token: int) -> void:
	var backgrounds := step.get("backgrounds", []) as Array
	var foregrounds := step.get("foregrounds", []) as Array
	var max_frames := maxi(backgrounds.size(), foregrounds.size())
	var frame_index := 0
	while token == _dialogue_visual_token and _state == FlowState.ROUTINE_DIALOGUE:
		var visual_step := {}
		if not backgrounds.is_empty():
			visual_step["background"] = str(backgrounds[frame_index % backgrounds.size()])
		if not foregrounds.is_empty():
			visual_step["foreground"] = str(foregrounds[frame_index % foregrounds.size()])
		_apply_visual_step(visual_step)
		frame_index += 1
		await get_tree().create_timer(0.58).timeout


func _play_routine_sound(sound_name: String) -> void:
	match sound_name:
		"alarm":
			_play_audio(alarm_audio, -2.0)
		"water":
			_play_audio(water_audio, -2.0)
		"coffee":
			_play_audio(coffee_audio, 0.0)
		"door":
			_play_audio(door_audio, -1.0)


func _show_office_prompt() -> void:
	_state = FlowState.CHOICE
	_dialogue_visual_token += 1
	_apply_visual_step({"background": "res://assets/ui/exit_background.png"})
	_selected_choice = 0
	choice_panel.position = _choice_start_position
	choice_panel.modulate.a = 1.0
	choice_panel.visible = true
	question_label.text = "///¿Deseas ir a la oficina?///"
	_update_choice_view()


func _update_choice_view() -> void:
	yes_label.text = "> SI" if _selected_choice == 0 else "  SI"
	no_label.text = "> NO" if _selected_choice == 1 else "  NO"
	yes_label.modulate = Color(0.82, 0.94, 1.0, 1.0) if _selected_choice == 0 else Color(0.38, 0.55, 0.65, 1.0)
	no_label.modulate = Color(0.82, 0.94, 1.0, 1.0) if _selected_choice == 1 else Color(0.30, 0.42, 0.50, 1.0)


func _confirm_yes() -> void:
	_locked = true
	var tween := create_tween()
	tween.tween_property(choice_panel, "modulate:a", 0.35, 0.08)
	tween.tween_property(choice_panel, "modulate:a", 1.0, 0.08)
	await tween.finished
	get_tree().change_scene_to_file(OFFICE_SCENE_PATH)


func _play_no_glitch() -> void:
	_no_attempts += 1
	_play_no_glitch_audio()
	_play_no_glitch_burst()

func _play_no_glitch_burst() -> void:
	if _glitch_running:
		return

	_glitch_running = true
	glitch_copy_pink.visible = true
	glitch_copy_green.visible = true
	glitch_overlay.visible = true

	var shake_count := int(7 + _no_attempts * 4)
	var glitch_colors := [
		Color(0.95, 0.0, 0.95, 1.0),
		Color(1.0, 0.18, 0.56, 1.0),
		Color(0.05, 1.0, 0.45, 1.0),
		Color(0.55, 0.1, 1.0, 1.0)
	]

	for shake_index in range(shake_count):
		var strength := minf(1.0 + float(_no_attempts - 1) * 0.55, 4.0)
		var shake_offset := Vector2(_rng.randf_range(-22.0, 22.0), _rng.randf_range(-13.0, 13.0)) * strength
		background.position = _background_start_position + shake_offset * 0.55
		foreground.position = _foreground_start_position + shake_offset * 0.75
		choice_panel.position = _choice_start_position + shake_offset * 1.15
		glitch_copy_pink.position = _background_start_position + Vector2(_rng.randf_range(-18.0, 18.0), _rng.randf_range(-6.0, 6.0)) * strength
		glitch_copy_green.position = _background_start_position - Vector2(_rng.randf_range(-14.0, 14.0), _rng.randf_range(-8.0, 8.0)) * strength
		glitch_copy_pink.modulate = Color(1.0, 0.08, 0.62, clampf(0.20 + strength * 0.10, 0.0, 0.62))
		glitch_copy_green.modulate = Color(0.05, 1.0, 0.42, clampf(0.16 + strength * 0.08, 0.0, 0.52))
		glitch_overlay.color = glitch_colors[_rng.randi_range(0, glitch_colors.size() - 1)]
		glitch_overlay.modulate.a = _rng.randf_range(0.16, clampf(0.32 + strength * 0.14, 0.0, 0.9))
		await get_tree().create_timer(maxf(0.012, 0.03 - strength * 0.003)).timeout

	background.position = _background_start_position
	foreground.position = _foreground_start_position
	choice_panel.position = _choice_start_position
	glitch_copy_pink.visible = false
	glitch_copy_green.visible = false
	glitch_overlay.modulate.a = 0.0
	glitch_overlay.visible = false
	_glitch_running = false


func _play_no_glitch_audio() -> void:
	var volume_boost := minf(float(_no_attempts - 1) * 2.5, 10.0)
	for audio in [glitch_static_audio, glitch_electric_audio, glitch_bass_audio, glitch_heartbeat_audio]:
		if audio == null or audio.stream == null:
			continue
		audio.stop()
		audio.volume_db = volume_boost
		audio.pitch_scale = _rng.randf_range(0.92, 1.08)
		audio.play()


func _play_audio(audio: AudioStreamPlayer, volume_db := 0.0) -> void:
	if audio == null or audio.stream == null:
		return

	audio.stop()
	audio.volume_db = volume_db
	audio.pitch_scale = 1.0
	audio.play()


func _on_yes_mouse_entered() -> void:
	if _state != FlowState.CHOICE:
		return
	_selected_choice = 0
	_update_choice_view()


func _on_no_mouse_entered() -> void:
	if _state != FlowState.CHOICE:
		return
	_selected_choice = 1
	_update_choice_view()


func _on_yes_gui_input(event: InputEvent) -> void:
	if _state == FlowState.CHOICE and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not _locked:
		_confirm_yes()


func _on_no_gui_input(event: InputEvent) -> void:
	if _state == FlowState.CHOICE and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not _locked:
		_play_no_glitch()
