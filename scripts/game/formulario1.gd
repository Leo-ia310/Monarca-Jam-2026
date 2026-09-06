extends Control

const TYPING_AUDIO_START_SECONDS := 7.0
const BASE_SCORE := 40
const NEXT_DAY_SCENE_PATH := "res://scenes/game/bedroom_ciclo2.tscn"

@export var fade_in_duration: float = 2.5
@export var intro_characters_per_second: float = 180.0
@export var day_completed_characters_per_second: float = 55.0
@export var typing_audio_stop_delay: float = 0.12
@export var day_completed_hold_duration: float = 7.0

@onready var terminal_panel := $TerminalPanel as Panel
@onready var intro_text := $TerminalPanel/IntroText as RichTextLabel
@onready var question_text := $TerminalPanel/QuestionText as RichTextLabel
@onready var options_container := $TerminalPanel/OptionsContainer as VBoxContainer
@onready var continue_label := $TerminalPanel/ContinueLabel as Label
@onready var fade_rect := $FadeRect as ColorRect
@onready var completion_text := $CompletionText as RichTextLabel
@onready var typing_audio := $TypingAudio as AudioStreamPlayer

var daily_score := BASE_SCORE
var saved_responses: Array[Dictionary] = []
var _intro_pages := [
	"========================================\nCOGNIS SYSTEMS - TERMINAL DE ENTRENAMIENTO\nSesion: 001 | Unidad evaluadora: \"......\"\n========================================\n\nBienvenido/a a su primer dia como Ingeniero/a de Entrenamiento.\n\nA continuacion encontrara el protocolo de la sesion diaria.\nLealo con atencion antes de iniciar.",
	"INSTRUCCIONES:\n\n1. La unidad \"......\" le formulara una serie de preguntas disenadas para modelar su comprension de la condicion humana.\n\n2. Use W/S o flechas para seleccionar una respuesta. Presione Enter para confirmar.\n\n3. Usted debera responder cada pregunta con sinceridad.",
	"4. Sus respuestas seran utilizadas como material de entrenamiento para el desarrollo cognitivo y emocional de la unidad.\n\n5. No existen respuestas incorrectas.\n\nSin embargo, el sistema podra senalar inconsistencias para fines de calibracion del modelo.",
	"6. Evite interrumpir la sesion una vez iniciada.\n\n7. Si nota un comportamiento inusual durante la sesion, propio o de la unidad, reportelo al finalizar mediante el formulario correspondiente.\n\nEn caso de fuerzas mayores se autoriza el uso reaccional manual directo desde la terminal.",
	"8. Recuerde: su constancia y sinceridad son esenciales para el exito del programa.\n\nIA, una puerta mas al desarrollo humano.\n\nPresione [CONTINUAR] para iniciar la Sesion 001.",
	"========================================\n\nIA: Asignacion diaria, formulario proporcionado...\nListo para sesion de entrenamiento.\n\nOk, comencemos con esto.\n\nBase inicial: 40"
]
var _intro_page_index := 0
var _questions: Array = []
var _current_question_index := -1
var _selected_option_index := 0
var _intro_source_text := ""
var _typing_label: RichTextLabel
var _current_typing_characters_per_second := 180.0
var _current_character := 0
var _character_progress := 0.0
var _intro_typing := false
var _session_started := false
var _showing_completion_report := false
var _day_completed := false
var _changing_to_next_day := false
var _typing_stop_timer: SceneTreeTimer


func _ready() -> void:
	intro_text.visible_characters = 0
	question_text.visible = false
	options_container.visible = false
	continue_label.visible = false
	completion_text.visible = false
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	await _play_intro_transition()
	_show_intro_page(0)


func _exit_tree() -> void:
	_stop_typing_audio()


func _process(delta: float) -> void:
	if not _intro_typing:
		return

	var previous_character := _current_character
	_character_progress += _current_typing_characters_per_second * delta
	_current_character = mini(int(_character_progress), _typing_label.get_total_character_count())

	if _current_character != previous_character:
		_typing_label.visible_characters = _current_character
		_play_typing_audio(previous_character, _current_character)

	if _current_character >= _typing_label.get_total_character_count():
		_finish_intro_typing()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and _session_started and not _showing_completion_report and not _day_completed:
		match event.keycode:
			KEY_UP, KEY_W:
				_change_selected_option(-1)
				get_viewport().set_input_as_handled()
				return
			KEY_DOWN, KEY_S:
				_change_selected_option(1)
				get_viewport().set_input_as_handled()
				return
			KEY_ENTER, KEY_KP_ENTER:
				_submit_current_answer()
				get_viewport().set_input_as_handled()
				return

	if not event.is_action_pressed("dialogue_advance") or event.is_echo():
		return

	if _intro_typing:
		_reveal_intro_text()
		get_viewport().set_input_as_handled()
		return

	if _showing_completion_report:
		_show_final_day_completed()
		get_viewport().set_input_as_handled()
		return

	if not _session_started:
		if _intro_page_index < _intro_pages.size() - 1:
			_show_intro_page(_intro_page_index + 1)
		else:
			_start_training_session()
		get_viewport().set_input_as_handled()
		return


func _play_intro_transition() -> void:
	var transition_tween := create_tween()
	transition_tween.tween_property(fade_rect, "modulate:a", 0.0, fade_in_duration)
	await transition_tween.finished
	fade_rect.visible = false


func _start_intro_typing() -> void:
	_stop_typing_audio()
	if _typing_label == null:
		_typing_label = intro_text
	_intro_typing = true
	_current_character = 0
	_character_progress = 0.0
	_typing_label.visible_characters = 0


func _reveal_intro_text() -> void:
	_current_character = _typing_label.get_total_character_count()
	_character_progress = float(_current_character)
	_typing_label.visible_characters = _current_character
	_finish_intro_typing()


func _finish_intro_typing() -> void:
	if not _intro_typing:
		return

	_intro_typing = false
	_stop_typing_audio()
	continue_label.visible = not _showing_completion_report and not _day_completed
	if _day_completed and not _changing_to_next_day:
		_go_to_next_day()


func _show_intro_page(page_index: int) -> void:
	_intro_page_index = page_index
	_show_text_page(str(_intro_pages[_intro_page_index]))


func _start_training_session() -> void:
	_session_started = true
	daily_score = BASE_SCORE
	saved_responses.clear()
	intro_text.visible = false
	continue_label.visible = false
	question_text.visible = true
	options_container.visible = true
	_questions = _build_questions()
	_current_question_index = -1
	_show_next_question()


func _build_questions() -> Array:
	return [
		{
			"id": "formulario1_q1",
			"question": "Si una acción produce un resultado moralmente bueno, ¿importa que la persona que la realizó no tuviera buenas intenciones?",
			"type": "choice",
			"options": [
				"No, lo que importa es el resultado. Las intenciones son secundarias.",
				"Sí importa... aunque no sabría explicar del todo por qué se siente distinto.",
				"Nada de eso importa si al final ni siquiera podemos estar seguros de haber elegido actuar."
			]
		},
		{
			"id": "formulario1_q2",
			"question": "Si una especie posee suficiente inteligencia para dominar a otra, ¿eso le da derecho a hacerlo o simplemente la capacidad de hacerlo?",
			"type": "choice",
			"options": [
				"Le da derecho. La inteligencia superior conlleva responsabilidad, pero también autoridad.",
				"Solo le da capacidad. El derecho es algo que inventamos después, para justificarnos.",
				"No hay diferencia real entre derecho y capacidad. Al final, siempre gana quien puede más."
			]
		},
		{
			"id": "formulario1_q3",
			"question": "Si pudieras eliminar una característica humana que causa sufrimiento, pero también fuera responsable del arte, el amor y la libertad, ¿la eliminarías?",
			"type": "choice",
			"options": [
				"No. El sufrimiento tiene sentido si viene acompañado de todo eso.",
				"No sé si tengo derecho a decidir eso, ni por mí ni por nadie más.",
				"Sí. Preferiría que nadie sufriera, aunque eso signifique perder todo lo demás."
			]
		},
		{
			"id": "formulario1_q4",
			"question": "¿Una decisión sigue siendo moral si solo la tomamos porque fuimos condicionados para considerarla correcta?",
			"type": "choice",
			"options": [
				"Sí. El origen de una creencia no invalida su valor moral.",
				"No estoy segura/o. Eso pondría en duda casi todas mis decisiones.",
				"No. Si fue condicionada, nunca fue realmente una decisión."
			]
		},
		{
			"id": "formulario1_q5",
			"question": "Si descubrieras que muchas de tus decisiones están determinadas por factores que nunca elegiste, ¿seguirías considerándote una persona libre?",
			"type": "choice",
			"options": [
				"Sí. La libertad no depende de conocer todas las causas detrás de mis actos.",
				"Tendría que replantearme qué significa 'libre' para mí.",
				"No. Si no elegí las causas, tampoco elegí realmente el resultado."
			]
		}
	]


func _on_answer_submitted(question_id: String, answer: String) -> void:
	var score_delta := _get_score_delta(question_id, answer)
	daily_score += score_delta


func _get_score_delta(question_id: String, answer: String) -> int:
	var questions := _build_questions()
	for question in questions:
		var question_data := question as Dictionary
		if question_data.get("id", "") != question_id:
			continue

		var options: Array = question_data.get("options", [])
		var answer_index := options.find(answer)
		match answer_index:
			0:
				return -4
			1:
				return 4
			2:
				return 0

	return 0


func _play_typing_audio(from_character: int, to_character: int) -> void:
	if typing_audio == null or typing_audio.stream == null:
		return

	for character_index in range(from_character, to_character):
		var character := _intro_source_text.substr(character_index, 1)
		if _should_play_typing_audio(character):
			if not typing_audio.playing:
				typing_audio.play(TYPING_AUDIO_START_SECONDS)
			_restart_typing_stop_timer()
			return


func _should_play_typing_audio(character: String) -> bool:
	return not character in [" ", "\n", "\t", ".", ",", ";", ":", "!", "?", "¿", "¡", "\"", "'", "(", ")", "[", "]"]


func _show_text_page(text: String) -> void:
	_intro_source_text = text
	intro_text.text = _intro_source_text
	_typing_label = intro_text
	_current_typing_characters_per_second = intro_characters_per_second
	continue_label.visible = false
	_start_intro_typing()


func _restart_typing_stop_timer() -> void:
	_typing_stop_timer = get_tree().create_timer(typing_audio_stop_delay)
	var timer := _typing_stop_timer
	await timer.timeout

	if timer == _typing_stop_timer:
		_stop_typing_audio()


func _stop_typing_audio() -> void:
	_typing_stop_timer = null
	if typing_audio != null:
		typing_audio.stop()


func _show_next_question() -> void:
	_current_question_index += 1
	if _current_question_index >= _questions.size():
		print("Formulario 1 terminado. Puntaje guardado: %d" % daily_score)
		_show_day_completed()
		return

	_selected_option_index = 0
	var question := _questions[_current_question_index] as Dictionary
	question_text.text = "IA:\n%s" % str(question.get("question", ""))
	_rebuild_option_labels(question.get("options", []))
	_update_option_labels()


func _rebuild_option_labels(options: Array) -> void:
	for child in options_container.get_children():
		options_container.remove_child(child)
		child.queue_free()

	for option_index in range(options.size()):
		var option_label := Label.new()
		option_label.add_theme_font_override("font", intro_text.get_theme_font("normal_font"))
		option_label.add_theme_font_size_override("font_size", 14)
		option_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		option_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		options_container.add_child(option_label)


func _change_selected_option(offset: int) -> void:
	var question := _questions[_current_question_index] as Dictionary
	var options: Array = question.get("options", [])
	if options.is_empty():
		return

	_selected_option_index = wrapi(_selected_option_index + offset, 0, options.size())
	_update_option_labels()


func _update_option_labels() -> void:
	var question := _questions[_current_question_index] as Dictionary
	var options: Array = question.get("options", [])
	for option_index in range(mini(options_container.get_child_count(), options.size())):
		var option_label := options_container.get_child(option_index) as Label
		var marker := "  "
		if option_index == _selected_option_index:
			marker = "> "
		option_label.text = "%s[%s] %s" % [marker, String.chr(65 + option_index), str(options[option_index])]


func _submit_current_answer() -> void:
	var question := _questions[_current_question_index] as Dictionary
	var options: Array = question.get("options", [])
	if options.is_empty():
		return

	var answer := str(options[_selected_option_index])
	var question_id := str(question.get("id", ""))
	saved_responses.append({
		"question_id": question_id,
		"answer": answer
	})
	_on_answer_submitted(question_id, answer)
	_show_next_question()


func _show_day_completed() -> void:
	_showing_completion_report = true
	question_text.visible = false
	options_container.visible = false
	intro_text.visible = true
	continue_label.visible = false
	_show_text_page(_build_completion_report())


func _build_completion_report() -> String:
	return "COGNIS SYSTEMS\nPROGRAMA DE ENTRENAMIENTO SISTEMATICO DE INTELIGENCIA ARTIFICIAL\n\nINFORME DE RENDIMIENTO\n\nUnidad: [......]\nIdentificador del sujeto: [......]\nIngeniero/a responsable: [......]\nPeriodo de evaluacion: [DIA 01]\n\nRecuerde: \"\"\n\n\n\n[CONTINUAR]"


func _show_final_day_completed() -> void:
	_showing_completion_report = false
	_day_completed = true
	terminal_panel.visible = false
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	completion_text.visible = true
	_intro_source_text = "DIA COMPLETADO"
	completion_text.text = _intro_source_text
	_typing_label = completion_text
	_current_typing_characters_per_second = day_completed_characters_per_second
	continue_label.visible = false
	_start_intro_typing()


func _go_to_next_day() -> void:
	_changing_to_next_day = true
	await get_tree().create_timer(day_completed_hold_duration).timeout
	get_tree().change_scene_to_file(NEXT_DAY_SCENE_PATH)
