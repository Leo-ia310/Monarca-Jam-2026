extends Control

signal question_started(question_id: String)
signal answer_submitted(question_id: String, answer: String)
signal questionnaire_finished(responses: Array)

const TYPE_CHOICE := "choice"
const TYPE_TEXT := "text"
const RAT_FONT_PATH := "res://assets/fonts/rat-typewriter.ttf"

@export var show_question_number: bool = true

@onready var counter_label := $RootMargin/TerminalPanel/Content/CounterLabel as Label
@onready var question_label := $RootMargin/TerminalPanel/Content/QuestionLabel as RichTextLabel
@onready var options_container := $RootMargin/TerminalPanel/Content/OptionsContainer as VBoxContainer
@onready var answer_input := $RootMargin/TerminalPanel/Content/AnswerInput as LineEdit
@onready var word_count_label := $RootMargin/TerminalPanel/Content/WordCountLabel as Label
@onready var hint_label := $RootMargin/TerminalPanel/Content/HintLabel as Label

var questions: Array = []
var responses: Array[Dictionary] = []
var current_index := -1
var current_line: Dictionary = {}
var selected_option_index := 0
var input_locked := false
var _word_regex := RegEx.new()
var _ui_font: Font


func _ready() -> void:
	_ui_font = load(RAT_FONT_PATH)
	_word_regex.compile("\\S+")
	answer_input.text_changed.connect(_on_answer_input_text_changed)
	answer_input.text_submitted.connect(_on_answer_input_submitted)
	visible = false


func start_questions(new_questions: Array) -> void:
	questions = new_questions.duplicate(true)
	responses.clear()
	current_index = -1
	selected_option_index = 0
	input_locked = true
	visible = true
	_show_next_question()


func get_responses() -> Array[Dictionary]:
	return responses.duplicate(true)


func is_questionnaire_active() -> bool:
	return visible and current_index >= 0 and current_index < questions.size()


func count_words(text: String) -> int:
	return _word_regex.search_all(text.strip_edges()).size()


func _unhandled_input(event: InputEvent) -> void:
	if not is_questionnaire_active() or input_locked:
		return

	if current_line.get("type", TYPE_CHOICE) != TYPE_CHOICE:
		return

	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_UP, KEY_W:
			_change_selected_option(-1)
			get_viewport().set_input_as_handled()
		KEY_DOWN, KEY_S:
			_change_selected_option(1)
			get_viewport().set_input_as_handled()
		KEY_ENTER, KEY_KP_ENTER:
			_submit_choice_answer()
			get_viewport().set_input_as_handled()


func _show_next_question() -> void:
	input_locked = true
	current_index += 1

	if current_index >= questions.size():
		_finish_questionnaire()
		return

	current_line = questions[current_index]
	selected_option_index = 0
	_setup_question_header()
	_clear_options()
	answer_input.hide()
	word_count_label.text = ""

	var question_type := str(current_line.get("type", TYPE_CHOICE))
	if question_type == TYPE_TEXT:
		_setup_text_question()
	else:
		_setup_choice_question()

	question_started.emit(_get_current_question_id())
	await get_tree().process_frame
	input_locked = false


func _setup_question_header() -> void:
	if show_question_number:
		counter_label.text = "Pregunta %d / %d" % [current_index + 1, questions.size()]
	else:
		counter_label.text = ""

	question_label.text = "[b]IA:[/b]\n%s" % str(current_line.get("question", ""))


func _setup_choice_question() -> void:
	hint_label.text = "W/S o flechas para seleccionar. Enter para confirmar."
	var options: Array = current_line.get("options", [])
	for option_index in range(options.size()):
		var option_label := Label.new()
		option_label.name = "Option%d" % option_index
		option_label.add_theme_font_override("font", _ui_font)
		option_label.add_theme_font_size_override("font_size", 24)
		option_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		options_container.add_child(option_label)

	_update_choice_options()


func _setup_text_question() -> void:
	answer_input.text = ""
	answer_input.show()
	answer_input.grab_focus.call_deferred()
	hint_label.text = "Escribe tu respuesta. Enter para confirmar."
	_update_word_count_label()


func _change_selected_option(offset: int) -> void:
	var options: Array = current_line.get("options", [])
	if options.is_empty():
		return

	selected_option_index = wrapi(selected_option_index + offset, 0, options.size())
	_update_choice_options()


func _update_choice_options() -> void:
	var options: Array = current_line.get("options", [])
	for option_index in range(options_container.get_child_count()):
		var option_label := options_container.get_child(option_index) as Label
		var prefix := "  "
		if option_index == selected_option_index:
			prefix = "> "

		option_label.text = "%s%s" % [prefix, str(options[option_index])]


func _submit_choice_answer() -> void:
	var options: Array = current_line.get("options", [])
	if options.is_empty():
		return

	_submit_answer(str(options[selected_option_index]))


func _on_answer_input_submitted(_submitted_text: String) -> void:
	if not is_questionnaire_active() or input_locked:
		return

	if current_line.get("type", TYPE_CHOICE) == TYPE_TEXT:
		_try_submit_text_answer()


func _try_submit_text_answer() -> void:
	var answer := answer_input.text.strip_edges()
	var word_count := count_words(answer)
	var min_words := int(current_line.get("min_words", 1))
	var max_words := int(current_line.get("max_words", 999))

	if word_count < min_words or word_count > max_words:
		_update_word_count_label()
		return

	_submit_answer(answer)


func _submit_answer(answer: String) -> void:
	input_locked = true
	var question_id := _get_current_question_id()
	responses.append({
		"question_id": question_id,
		"answer": answer
	})
	answer_submitted.emit(question_id, answer)
	await get_tree().process_frame
	_show_next_question()


func _finish_questionnaire() -> void:
	input_locked = true
	current_line = {}
	_clear_options()
	answer_input.hide()
	counter_label.text = ""
	question_label.text = ""
	word_count_label.text = ""
	hint_label.text = ""
	visible = false
	questionnaire_finished.emit(get_responses())


func _on_answer_input_text_changed(_new_text: String) -> void:
	if current_line.get("type", TYPE_CHOICE) == TYPE_TEXT:
		_update_word_count_label()


func _update_word_count_label() -> void:
	var word_count := count_words(answer_input.text)
	var min_words := int(current_line.get("min_words", 1))
	var max_words := int(current_line.get("max_words", 999))
	word_count_label.text = "%d / %d palabras" % [word_count, max_words]

	if word_count < min_words:
		word_count_label.text += " - mínimo %d" % min_words
	elif word_count > max_words:
		word_count_label.text += " - demasiadas palabras"


func _clear_options() -> void:
	for child in options_container.get_children():
		child.queue_free()


func _get_current_question_id() -> String:
	return str(current_line.get("id", "q%d" % [current_index + 1]))
