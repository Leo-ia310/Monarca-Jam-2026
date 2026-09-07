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
@export var portrait_width: float = 380.0
@export var portrait_bottom_overlap: float = 20.0
@export var portrait_left_inset: float = -35.0

var dialogue_active := false
var is_typing := false
var current_line := -1
var current_character := 0

var _dialogue_lines: Array = []
var _current_text := ""
var _character_progress := 0.0
var _line_finished_emitted := false
var _last_advance_frame := -1
var _current_speaker := ""

@onready var dialogue_texture := get_node("DialogueTexture") as TextureRect
@onready var speaker_portrait := get_node("SpeakerPortrait") as TextureRect
@onready var content_margin := get_node("ContentMargin") as MarginContainer
@onready var speaker_label := get_node("ContentMargin/DialogueContent/SpeakerLabel") as Label
@onready var dialogue_text := get_node("ContentMargin/DialogueContent/DialogueText") as RichTextLabel
@onready var continue_indicator := get_node("ContentMargin/DialogueContent/ContinueRow/ContinueIndicator") as Label
@onready var typing_audio := get_node("TypingAudio") as AudioStreamPlayer

@onready var portrait_happy := preload("res://assets/ui/dialogue_portraits/player_happy.png")
@onready var portrait_sleepy := preload("res://assets/ui/dialogue_portraits/player_sleepy.png")
@onready var portrait_scared := preload("res://assets/ui/dialogue_portraits/player_scared.png")
@onready var portrait_sad := preload("res://assets/ui/dialogue_portraits/player_sad.png")


func _ready() -> void:
	visible = false

	dialogue_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_text.fit_content = false
	dialogue_text.scroll_active = false
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.clip_contents = true

	continue_indicator.visible = false

	if speaker_portrait != null:
		speaker_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		speaker_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		speaker_portrait.visible = false

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

	current_character = mini(
		int(_character_progress),
		dialogue_text.get_total_character_count()
	)

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

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
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

	_current_speaker = speaker
	_current_text = str(line_data.get("text", ""))

	current_character = 0
	_character_progress = 0.0
	_line_finished_emitted = false
	is_typing = true

	if speaker.is_empty():
		speaker_label.text = ""
		speaker_label.visible = false
	else:
		if speaker.ends_with(":"):
			speaker_label.text = speaker
		else:
			speaker_label.text = "%s:" % speaker

		speaker_label.visible = true

	dialogue_text.text = _current_text
	dialogue_text.visible_characters = 0

	continue_indicator.visible = false

	_update_speaker_portrait(
		speaker,
		str(line_data.get("emotion", "")),
		_current_text
	)

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
	_current_speaker = ""

	speaker_label.text = ""
	dialogue_text.text = ""

	continue_indicator.visible = false

	if speaker_portrait != null:
		speaker_portrait.visible = false

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

		_update_portrait_layout(
			Rect2(Vector2.ZERO, box_size),
			1.0
		)

		_update_content_margins(1.0)

		return

	var viewport_size := Vector2(get_viewport_rect().size)

	var width_scale := (
		viewport_size.x
		* max_width_ratio
		/ base_box_size.x
	)

	var height_scale := (
		viewport_size.y
		* max_height_ratio
		/ base_box_size.y
	)

	var scale := minf(
		1.0,
		minf(width_scale, height_scale)
	)

	var box_size := base_box_size * scale

	var box_position := Vector2(
		(viewport_size.x - box_size.x) * 0.5,
		viewport_size.y - box_size.y - bottom_margin
	)

	dialogue_texture.position = box_position
	dialogue_texture.size = box_size

	content_margin.position = box_position
	content_margin.size = box_size

	_update_portrait_layout(
		Rect2(box_position, box_size),
		scale
	)

	_update_content_margins(scale)


func _update_speaker_portrait(
	speaker: String,
	emotion: String,
	text: String
) -> void:

	if speaker_portrait == null:
		return

	if speaker != "???":
		speaker_portrait.visible = false
		return

	speaker_portrait.texture = _get_portrait_texture(
		emotion,
		text
	)

	speaker_portrait.visible = true

	_update_layout()


func _get_portrait_texture(
	emotion: String,
	text: String
) -> Texture2D:

	var normalized_emotion := emotion.strip_edges().to_lower()

	match normalized_emotion:
		"sleepy", "aburrida", "sueno", "sueño", "cansada":
			return portrait_sleepy

		"scared", "asustada", "miedo":
			return portrait_scared

		"sad", "triste":
			return portrait_sad

		"happy", "alegre", "normal":
			return portrait_happy

	var normalized_text := text.to_lower()

	if (
		normalized_text.contains("miedo")
		or normalized_text.contains("raro")
		or normalized_text.contains("no...")
		or normalized_text.contains("¿")
		or normalized_text.contains("dolor")
		or normalized_text.contains("terminal acaba")
	):
		return portrait_scared

	if (
		normalized_text.contains("triste")
		or normalized_text.contains("pereza")
		or normalized_text.contains("detesto")
		or normalized_text.contains("arrepenti")
		or normalized_text.contains("termine")
	):
		return portrait_sad

	if (
		normalized_text.contains("5 minutos")
		or normalized_text.contains("levantarme")
		or normalized_text.contains("despert")
	):
		return portrait_sleepy

	return portrait_happy


func _update_portrait_layout(
	box_rect: Rect2,
	scale: float
) -> void:

	if speaker_portrait == null:
		return

	var width := portrait_width * scale

	var texture_size := Vector2(1.0, 1.0)

	if speaker_portrait.texture != null:
		texture_size = Vector2(
			speaker_portrait.texture.get_width(),
			speaker_portrait.texture.get_height()
		)

	if texture_size.x <= 0.0:
		texture_size.x = 1.0

	if texture_size.y <= 0.0:
		texture_size.y = 1.0

	var aspect_ratio := texture_size.y / texture_size.x
	var height := width * aspect_ratio

	var x := (
		box_rect.position.x
		+ portrait_left_inset * scale
	)

	var y := (
		box_rect.position.y
		- height
		+ portrait_bottom_overlap * scale
	)

	speaker_portrait.position = Vector2(x, y)
	speaker_portrait.size = Vector2(width, height)


func _update_content_margins(scale: float) -> void:
	content_margin.add_theme_constant_override(
		"margin_left",
		int(round(content_margin_left * scale))
	)

	content_margin.add_theme_constant_override(
		"margin_top",
		int(round(content_margin_top * scale))
	)

	content_margin.add_theme_constant_override(
		"margin_right",
		int(round(content_margin_right * scale))
	)

	content_margin.add_theme_constant_override(
		"margin_bottom",
		int(round(content_margin_bottom * scale))
	)


func _play_typing_audio(
	from_character: int,
	to_character: int
) -> void:

	if typing_audio == null or typing_audio.stream == null:
		return

	for character_index in range(from_character, to_character):
		var character := _current_text.substr(character_index, 1)

		if _should_play_typing_audio(character):
			typing_audio.play(typing_audio_start_seconds)
			return


func _should_play_typing_audio(character: String) -> bool:
	return not character in [
		" ",
		"\n",
		"\t",
		".",
		",",
		";",
		":",
		"!",
		"?",
		"¿",
		"¡",
		"\"",
		"'",
		"(",
		")",
		"[",
		"]"
	]
