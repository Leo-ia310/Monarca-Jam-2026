extends Control

signal dialogue_started
signal line_started
signal line_finished
signal dialogue_finished

@export var characters_per_second: float = 24.0
@export var use_manual_box_rect: bool = false
@export var manual_box_rect := Rect2(140.0, 332.0, 1000.0, 368.0)
@export var base_box_size := Vector2(920.0, 368.0)
@export var bottom_margin: float = 20.0
@export var max_width_ratio: float = 0.88
@export var max_height_ratio: float = 0.46
@export var content_margin_left: float = 80.0
@export var content_margin_top: float = 86.0
@export var content_margin_right: float = 70.0
@export var content_margin_bottom: float = 58.0
@export var typing_audio_start_seconds: float = 7.0

var dialogue_active := false
var is_typing := false
var current_line := -1
var current_character := 0

var _dialogue_lines: Array = []
var _current_text := ""
var _character_progress := 0.0
var _line_finished_emitted := false
var _last_advance_frame := -1

@onready var dialogue_texture := get_node("DialogueTexture") as TextureRect
@onready var content_margin := get_node("ContentMargin") as MarginContainer
@onready var speaker_label := get_node("ContentMargin/DialogueContent/SpeakerLabel") as Label
@onready var dialogue_text := get_node("ContentMargin/DialogueContent/DialogueText") as RichTextLabel
@onready var continue_indicator := get_node("ContentMargin/DialogueContent/ContinueRow/ContinueIndicator") as Label
@onready var typing_audio := get_node("TypingAudio") as AudioStreamPlayer


func _ready() -> void:
	visible = false
	continue_indicator.visible = false
	_update_layout()
	get_viewport().size_changed.connect(_update_layout)


func _exit_tree() -> void:
	if typing_audio != null:
		typing_audio.stop()


func _process(delta: float) -> void:
	if not dialogue_active or not is_typing:
		return

	var previous_character := current_character
	_character_progress += characters_per_second * delta
	current_character = mini(int(_character_progress), dialogue_text.get_total_character_count())

	if current_character != previous_character:
		dialogue_text.visible_characters = current_character
		_play_typing_audio(previous_character, current_character)

	if current_character >= dialogue_text.get_total_character_count():
		_finish_current_line()


func _unhandled_input(event: InputEvent) -> void:
	if not dialogue_active:
		return

	if event.is_action_pressed("dialogue_advance") and not event.is_echo():
		_request_advance()


func _gui_input(event: InputEvent) -> void:
	if not dialogue_active:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_request_advance()


func start_dialogue(lines: Array) -> void:
	if lines.is_empty():
		_finish_dialogue()
		return

	_dialogue_lines = lines.duplicate(true)
	dialogue_active = true
	current_line = -1
	current_character = 0
	visible = true
	dialogue_started.emit()
	_start_next_line()


func is_dialogue_active() -> bool:
	return dialogue_active


func _request_advance() -> void:
	var current_frame := Engine.get_process_frames()
	if _last_advance_frame == current_frame:
		return

	_last_advance_frame = current_frame
	get_viewport().set_input_as_handled()

	if is_typing:
		_reveal_current_line()
	else:
		_start_next_line()


func _start_next_line() -> void:
	current_line += 1
	if current_line >= _dialogue_lines.size():
		_finish_dialogue()
		return

	var line_data := _dialogue_lines[current_line] as Dictionary
	var speaker := str(line_data.get("speaker", ""))
	_current_text = str(line_data.get("text", ""))
	current_character = 0
	_character_progress = 0.0
	_line_finished_emitted = false
	is_typing = true

	speaker_label.text = "" if speaker.is_empty() else (speaker if speaker.ends_with(":") else "%s:" % speaker)
	speaker_label.visible = not speaker.is_empty()
	dialogue_text.text = _current_text
	dialogue_text.visible_characters = 0
	continue_indicator.visible = false
	line_started.emit()


func _reveal_current_line() -> void:
	current_character = dialogue_text.get_total_character_count()
	_character_progress = float(current_character)
	dialogue_text.visible_characters = current_character
	_finish_current_line()


func _finish_current_line() -> void:
	if _line_finished_emitted:
		return

	if typing_audio != null:
		typing_audio.stop()

	is_typing = false
	_line_finished_emitted = true
	continue_indicator.visible = true
	line_finished.emit()


func _finish_dialogue() -> void:
	dialogue_active = false
	is_typing = false
	if typing_audio != null:
		typing_audio.stop()
	current_line = -1
	current_character = 0
	_dialogue_lines.clear()
	_current_text = ""
	speaker_label.text = ""
	dialogue_text.text = ""
	continue_indicator.visible = false
	visible = false
	dialogue_finished.emit()


func _update_layout() -> void:
	if dialogue_texture == null or content_margin == null:
		return

	if use_manual_box_rect:
		var box_size := size
		if box_size.x <= 0.0 or box_size.y <= 0.0:
			box_size = manual_box_rect.size

		dialogue_texture.position = Vector2.ZERO
		dialogue_texture.size = box_size
		content_margin.position = Vector2.ZERO
		content_margin.size = box_size
		_update_content_margins(1.0)
		return

	var viewport_size := Vector2(get_viewport_rect().size)
	var width_scale := viewport_size.x * max_width_ratio / base_box_size.x
	var height_scale := viewport_size.y * max_height_ratio / base_box_size.y
	var scale := minf(1.0, minf(width_scale, height_scale))
	var box_size := base_box_size * scale
	var box_position := Vector2(
		(viewport_size.x - box_size.x) * 0.5,
		viewport_size.y - box_size.y - bottom_margin
	)

	dialogue_texture.position = box_position
	dialogue_texture.size = box_size
	content_margin.position = box_position
	content_margin.size = box_size

	_update_content_margins(scale)


func _update_content_margins(scale: float) -> void:
	content_margin.add_theme_constant_override("margin_left", int(round(content_margin_left * scale)))
	content_margin.add_theme_constant_override("margin_top", int(round(content_margin_top * scale)))
	content_margin.add_theme_constant_override("margin_right", int(round(content_margin_right * scale)))
	content_margin.add_theme_constant_override("margin_bottom", int(round(content_margin_bottom * scale)))


func _play_typing_audio(from_character: int, to_character: int) -> void:
	if typing_audio.stream == null:
		return

	for character_index in range(from_character, to_character):
		var character := _current_text.substr(character_index, 1)
		if _should_play_typing_audio(character):
			typing_audio.play(typing_audio_start_seconds)
			return


func _should_play_typing_audio(character: String) -> bool:
	return not character in [" ", "\n", "\t", ".", ",", ";", ":", "!", "?", "¿", "¡", "\"", "'", "(", ")", "[", "]"]
