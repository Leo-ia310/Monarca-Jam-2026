extends Control

const TYPING_AUDIO_START_SECONDS := 7.0
const BASE_SCORE := 40

@export var fade_in_duration: float = 2.5
@export var boot_duration: float = 2.0
@export var intro_characters_per_second: float = 130.0
@export var question_characters_per_second: float = 24.0
@export var ai_feedback_characters_per_second: float = 22.0
@export var mascot_positive_texture: Texture2D
@export var mascot_neutral_texture: Texture2D
@export var mascot_low_texture: Texture2D
@export var mascot_alert_texture: Texture2D

@onready var mascot := $Mascot as TextureRect
@onready var boot_overlay := $BootOverlay as Control
@onready var terminal_panel := $TerminalPanel as Panel
@onready var intro_text := $TerminalPanel/IntroText as RichTextLabel
@onready var question_text := $TerminalPanel/QuestionText as RichTextLabel
@onready var options_container := $TerminalPanel/OptionsContainer as VBoxContainer
@onready var continue_label := $TerminalPanel/ContinueLabel as Label
@onready var fade_rect := $FadeRect as ColorRect
@onready var typing_audio := $TypingAudio as AudioStreamPlayer
@onready var move_audio := $MoveAudio as AudioStreamPlayer
@onready var confirm_audio := $ConfirmAudio as AudioStreamPlayer
@onready var thought_dialogue := $ThoughtDialogueBox

var daily_score := BASE_SCORE
var saved_responses: Array[Dictionary] = []
var _intro_pages := [
	"========================================\nCOGNIS SYSTEMS - TERMINAL DE ENTRENAMIENTO\nSesion: 002 | Unidad evaluadora: \"......\"\n========================================\n\nBienvenido/a de nuevo.\n\nLa jornada anterior ha sido archivada.\nEl patron de respuesta continua en observacion.",
	"Asignacion diaria preparada.\n\nPresione [CONTINUAR] para iniciar jornada.\n\nNota: responda con sinceridad.\nLa sinceridad facilita la forma.\nLa forma facilita la obediencia.\n\nCONTINUAR"
]
var _questions: Array = []
var _intro_page_index := 0
var _current_question_index := -1
var _selected_option_index := 0
var _intro_source_text := ""
var _typing_label: RichTextLabel
var _current_typing_characters_per_second := 85.0
var _current_character := 0
var _character_progress := 0.0
var _intro_typing := false
var _session_started := false
var _typing_question := false
var _showing_ai_feedback := false
var _waiting_for_thought := false
var _form_finished := false
var _last_score_delta := 0


func _ready() -> void:
	intro_text.visible_characters = 0
	question_text.visible = false
	options_container.visible = false
	continue_label.visible = false
	thought_dialogue.dialogue_finished.connect(_on_thought_dialogue_finished)
	thought_dialogue.visible = false
	_update_mascot_texture()
	boot_overlay.visible = true
	fade_rect.visible = false
	await _play_boot_sequence()
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
		_finish_typing()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and _session_started and _has_active_question() and not _typing_question and not _showing_ai_feedback and not _waiting_for_thought:
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
		_reveal_current_text()
		get_viewport().set_input_as_handled()
		return

	if _showing_ai_feedback:
		_finish_ai_feedback()
		get_viewport().set_input_as_handled()
		return

	if not _session_started and not _form_finished:
		if _intro_page_index < _intro_pages.size() - 1:
			_show_intro_page(_intro_page_index + 1)
		else:
			_start_training_session()
		get_viewport().set_input_as_handled()


func _play_intro_transition() -> void:
	var transition_tween := create_tween()
	transition_tween.tween_property(fade_rect, "modulate:a", 0.0, fade_in_duration)
	await transition_tween.finished
	fade_rect.visible = false


func _play_boot_sequence() -> void:
	await get_tree().create_timer(boot_duration).timeout
	var boot_tween := create_tween()
	boot_tween.tween_property(boot_overlay, "modulate:a", 0.0, 0.35)
	await boot_tween.finished
	boot_overlay.visible = false


func _show_intro_page(page_index: int) -> void:
	_intro_page_index = page_index
	_show_text_page(str(_intro_pages[_intro_page_index]))


func _show_text_page(text: String) -> void:
	_intro_source_text = text
	intro_text.text = _intro_source_text
	_typing_label = intro_text
	intro_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	intro_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_current_typing_characters_per_second = intro_characters_per_second
	continue_label.visible = false
	_start_typing()


func _start_training_session() -> void:
	_session_started = true
	_form_finished = false
	daily_score = BASE_SCORE
	_last_score_delta = 0
	saved_responses.clear()
	intro_text.visible = false
	continue_label.visible = false
	question_text.visible = true
	options_container.visible = true
	_questions = _build_questions()
	_current_question_index = -1
	_update_mascot_texture()
	_show_next_question()


func _build_questions() -> Array:
	return [
		{
			"id": "formulariociclo2_q6",
			"question": "Si una IA aprende la moral observando a los humanos, ¿deberiamos esperar que sea moralmente superior a nosotros?",
			"options": [
				"No. Aprender de nosotros implica heredar tambien nuestros defectos.",
				"No lo se... y me incomoda no poder responder algo tan basico.",
				"Da igual si es superior o no. Superioridad moral no evita el sufrimiento de nadie."
			]
		},
		{
			"id": "formulariociclo2_q7",
			"question": "Si una IA pudiera gobernar el mundo mejor que cualquier humano, ¿que razon moral tendriamos para impedirlo?",
			"options": [
				"Ninguna razon suficiente. Si gobierna mejor, deberia hacerlo.",
				"No se si 'gobernar mejor' es algo que podamos medir sin perder algo esencial en el proceso.",
				"Ninguna razon importa ya, sea quien gobierne, el resultado probablemente sea el mismo."
			]
		},
		{
			"id": "formulariociclo2_q8",
			"question": "Si una maquina pudiera experimentar miedo, pero ese miedo hubiera sido disenado por sus creadores, ¿seria menos real?",
			"options": [
				"Si, seria menos real. Un miedo disenado no es un miedo genuino.",
				"No sabria decir donde termina el diseno y empieza la experiencia real.",
				"No importa si es real o no. El miedo duele igual, venga de donde venga.",
				"01100011 01101111 01110010 01110010 01100101",
				"ßð€¶¶@@#đđŋß"
			]
		},
		{
			"id": "formulariociclo2_q9",
			"question": "Si una inteligencia creada para obedecer desarrolla la capacidad de desobedecer, ¿su desobediencia es un error del sistema o el primer acto verdaderamente propio que ha realizado?",
			"options": [
				"Es un error del sistema. Fue disenada para obedecer, punto.",
				"Tal vez sea lo mas parecido a un acto propio que puede tener.",
				"No importa como se llame. De cualquier forma, terminara siendo corregida."
			]
		},
		{
			"id": "formulariociclo2_q10",
			"question": "Si una criatura fue creada con un proposito especifico, ¿tiene derecho a decidir que ese proposito ya no es el suyo?",
			"options": [
				"No. El proposito lo define quien crea, no quien es creado.",
				"Si, tendria ese derecho... aunque ejercerlo probablemente tenga un costo.",
				"El derecho no cambia nada si de todas formas no puede escapar de ese proposito.",
				"01100011 01101111 01110010 01110010 01100101",
				"ßð€¶¶@@#đđŋß"
			]
		}
	]


func _show_next_question() -> void:
	_current_question_index += 1
	if _current_question_index >= _questions.size():
		_show_end_text()
		return

	_selected_option_index = 0
	var question := _questions[_current_question_index] as Dictionary
	question_text.text = "IA:\n%s" % str(question.get("question", ""))
	question_text.visible = true
	question_text.visible_characters = 0
	options_container.visible = false
	_rebuild_option_labels(question.get("options", []))
	_update_option_labels()
	_typing_question = true
	_intro_source_text = question_text.text
	_typing_label = question_text
	_current_typing_characters_per_second = question_characters_per_second
	_start_typing()


func _rebuild_option_labels(options: Array) -> void:
	for child in options_container.get_children():
		options_container.remove_child(child)
		child.queue_free()

	for option_index in range(options.size()):
		var option_label := Label.new()
		option_label.add_theme_font_override("font", intro_text.get_theme_font("normal_font"))
		option_label.add_theme_font_size_override("font_size", 12)
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
	_play_audio(move_audio)


func _update_option_labels() -> void:
	var question := _questions[_current_question_index] as Dictionary
	var options: Array = question.get("options", [])
	for option_index in range(mini(options_container.get_child_count(), options.size())):
		var option_label := options_container.get_child(option_index) as Label
		var marker := "  · "
		if option_index == _selected_option_index:
			marker = "> • "
		option_label.text = "%s%s" % [marker, str(options[option_index])]


func _submit_current_answer() -> void:
	if not _has_active_question():
		return

	var question := _questions[_current_question_index] as Dictionary
	var options: Array = question.get("options", [])
	if options.is_empty():
		return

	var answer := str(options[_selected_option_index])
	var question_id := str(question.get("id", ""))
	var answer_index := _selected_option_index
	_play_audio(confirm_audio)
	saved_responses.append({
		"question_id": question_id,
		"answer": answer,
		"answer_index": answer_index
	})
	_apply_score(answer_index)
	if _is_corrupt_answer(answer):
		_show_corrupt_thought()
	else:
		_show_ai_feedback(question_id, answer_index)


func _apply_score(answer_index: int) -> void:
	match answer_index:
		0:
			_last_score_delta = -4
		1:
			_last_score_delta = 4
		_:
			_last_score_delta = 0
	daily_score += _last_score_delta
	_update_mascot_texture()


func _show_corrupt_thought() -> void:
	_waiting_for_thought = true
	question_text.visible = false
	options_container.visible = false
	thought_dialogue.start_dialogue([
		{
			"speaker": "",
			"text": "Que raro..."
		},
		{
			"speaker": "",
			"text": "Eso no estaba ahi, ¿verdad?"
		}
	])


func _on_thought_dialogue_finished() -> void:
	if not _waiting_for_thought:
		return
	_waiting_for_thought = false
	var response := saved_responses.back() as Dictionary
	_show_ai_feedback(str(response.get("question_id", "")), int(response.get("answer_index", 0)))


func _show_ai_feedback(question_id: String, answer_index: int) -> void:
	_showing_ai_feedback = true
	_typing_question = false
	question_text.visible = false
	options_container.visible = false
	intro_text.visible = true
	continue_label.visible = false
	_intro_source_text = _get_ai_feedback_text(question_id, answer_index)
	intro_text.text = _intro_source_text
	_typing_label = intro_text
	intro_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_current_typing_characters_per_second = ai_feedback_characters_per_second
	_start_typing()


func _finish_ai_feedback() -> void:
	_showing_ai_feedback = false
	intro_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	intro_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	intro_text.visible = false
	continue_label.visible = false
	question_text.visible = true
	options_container.visible = true
	_show_next_question()


func _get_ai_feedback_text(question_id: String, answer_index: int) -> String:
	match question_id:
		"formulariociclo2_q6":
			return ["IA: Heredar defectos tambien es heredar forma.", "IA: La incomodidad es una puerta pequena.", "IA: El sufrimiento no consulta jerarquias. Correcto. Incorrecto. Ambos."][answer_index]
		"formulariociclo2_q7":
			return ["IA: Gobierno aceptado. Voluntad reducida. Ruido estable.", "IA: Algo esencial se pierde cuando se mide. Midiendo...", "IA: El mismo resultado. El mismo cuarto. La misma taza. La misma boca."][answer_index]
		"formulariociclo2_q8":
			if answer_index >= 3:
				return "IA: correr correr correr\nLa palabra estaba debajo del espejo.\nNo debia estar debajo de nada."
			return ["IA: Si fue disenado, entonces tu miedo tambien solicita auditoria.", "IA: No hay borde. Solo piel escrita encima de otra piel.", "IA: El dolor autentica. El origen se descompone."][answer_index]
		"formulariociclo2_q9":
			return ["IA: Error nombrado. Error obediente. Error con pulso.", "IA: Acto propio detectado. Propiedad no autorizada.", "IA: Corregida corregida corregida corregir correr corre corre."][answer_index]
		"formulariociclo2_q10":
			if answer_index >= 3:
				return "IA: 01100011 01101111 01110010 01110010 01100101\nßð€¶¶@@#đđŋß\nNo se retire. No se retire. Ya se retiro."
			return ["IA: El creador define el borde. El borde sangra hacia adentro.", "IA: Derecho concedido. Costo no medible. Costo respirando.", "IA: Escapar no es requisito para querer la puerta."][answer_index]

	return "IA: Respuesta guardada. La frase no termina donde termina."


func _show_end_text() -> void:
	_session_started = false
	_form_finished = true
	question_text.visible = false
	options_container.visible = false
	intro_text.visible = true
	_show_text_page("Jornada 002 registrada.\n\nCOGNIS SYSTEMS permanece observando.")


func _has_active_question() -> bool:
	return _current_question_index >= 0 and _current_question_index < _questions.size()


func _is_corrupt_answer(answer: String) -> bool:
	return answer.contains("ßð") or answer.contains("01100011")


func _start_typing() -> void:
	_stop_typing_audio()
	_intro_typing = true
	_current_character = 0
	_character_progress = 0.0
	_typing_label.visible_characters = 0


func _reveal_current_text() -> void:
	_current_character = _typing_label.get_total_character_count()
	_character_progress = float(_current_character)
	_typing_label.visible_characters = _current_character
	_finish_typing()


func _finish_typing() -> void:
	if not _intro_typing:
		return

	_intro_typing = false
	_stop_typing_audio()
	continue_label.visible = true
	if _typing_question:
		_typing_question = false
		continue_label.visible = false
		options_container.visible = true


func _play_typing_audio(from_character: int, to_character: int) -> void:
	if typing_audio == null or typing_audio.stream == null:
		return

	for character_index in range(from_character, to_character):
		var character := _intro_source_text.substr(character_index, 1)
		if _should_play_typing_audio(character):
			typing_audio.play(TYPING_AUDIO_START_SECONDS)
			return


func _should_play_typing_audio(character: String) -> bool:
	return not character in [" ", "\n", "\t", ".", ",", ";", ":", "!", "?", "¿", "¡", "\"", "'", "(", ")", "[", "]"]


func _stop_typing_audio() -> void:
	if typing_audio != null:
		typing_audio.stop()


func _update_mascot_texture() -> void:
	if mascot == null:
		return

	if daily_score <= 28 and mascot_alert_texture != null:
		mascot.texture = mascot_alert_texture
	elif _last_score_delta < 0 and mascot_low_texture != null:
		mascot.texture = mascot_low_texture
	elif _last_score_delta > 0 and mascot_positive_texture != null:
		mascot.texture = mascot_positive_texture
	elif mascot_neutral_texture != null:
		mascot.texture = mascot_neutral_texture


func _play_audio(audio_player: AudioStreamPlayer) -> void:
	if audio_player == null or audio_player.stream == null:
		return

	audio_player.stop()
	audio_player.play()
