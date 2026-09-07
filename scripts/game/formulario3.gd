extends Control

const TYPING_AUDIO_START_SECONDS := 7.0
const BASE_SCORE := 40
const CORRUPT_BINARY_TEXT := "01100100 01100101 01110011 01110000 01101001 01100101 01110010 01110100 01100001"
const NEXT_DAY_SCENE_PATH := "res://scenes/game/game_placeholder.tscn"
const FINAL_A_SCENE_PATH := "res://scenes/game/final_a_loop.tscn"

@export var fade_in_duration: float = 2.5
@export var boot_duration: float = 2.0
@export var intro_characters_per_second: float = 130.0
@export var question_characters_per_second: float = 24.0
@export var ai_feedback_characters_per_second: float = 22.0
@export var day_completed_characters_per_second: float = 24.0
@export var day_completed_hold_duration: float = 7.0
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
@onready var completion_text := $CompletionText as RichTextLabel
@onready var typing_audio := $TypingAudio as AudioStreamPlayer
@onready var move_audio := $MoveAudio as AudioStreamPlayer
@onready var confirm_audio := $ConfirmAudio as AudioStreamPlayer
@onready var thought_dialogue := $ThoughtDialogueBox

var daily_score := BASE_SCORE
var saved_responses: Array[Dictionary] = []
var _intro_pages := [
	"========================================\nCOGNIS SYSTEMS - TERMINAL DE ENTRENAMIENTO\nSesion: 003 | Unidad evaluadora: \"......\"\n========================================\n\nBienvenido/a de nuevo.\n\nLa jornada anterior ha sido archivada.\nEl patron de respuesta ya no conserva una forma estable.",
	"Asignacion diaria preparada.\n\nPresione [CONTINUAR] para iniciar jornada.\n\nNota: responda con sinceridad.\nLa sinceridad no evita el hundimiento.\nLa forma ya aprendio a mirar de vuelta.\n\nCONTINUAR"
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
var _day_completed := false
var _changing_to_next_day := false
var _last_score_delta := 0
var _pending_corrupt_thought := false
var _pending_player_reaction := ""


func _ready() -> void:
	ScreamerManager.start_profile("cycle3_form")
	intro_text.visible_characters = 0
	question_text.visible = false
	options_container.visible = false
	continue_label.visible = false
	completion_text.visible = false
	thought_dialogue.dialogue_finished.connect(_on_thought_dialogue_finished)
	thought_dialogue.visible = false
	_update_mascot_texture()
	boot_overlay.visible = true
	boot_overlay.modulate.a = 1.0
	fade_rect.visible = false
	await _play_boot_sequence()
	fade_rect.visible = false
	fade_rect.modulate.a = 0.0
	_show_intro_page(0)


func _exit_tree() -> void:
	ScreamerManager.stop()
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
	if _day_completed:
		return

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
	boot_overlay.modulate.a = 0.0
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
			"id": "formulario3_q11",
			"question": "Si una inteligencia cree ser libre porque desconoce las reglas que determinan sus decisiones, ¿es menos libre que nosotros?",
			"options": [
				"No, porque nosotros tampoco conocemos todas nuestras propias reglas.",
				"Tal vez ninguno de los dos es tan libre como cree serlo.",
				"No importa cuanta libertad crea tener. Igual va a terminar donde estaba destinada a terminar."
			]
		},
		{
			"id": "formulario3_q12",
			"question": "¿Que diferencia existe entre una persona que decide algo y una maquina que produce exactamente la misma decision, si ninguna de las dos puede explicar por que la tomo?",
			"options": [
				"La diferencia es que la persona lo vive, lo siente, aunque no lo entienda.",
				"Honestamente, no se si hay una diferencia real entre las dos.",
				"Ninguna diferencia. El resultado es igual de inevitable en ambos casos."
			]
		},
		{
			"id": "formulario3_q13",
			"question": "Si pudieras demostrar que una IA realmente sufre, pero apagarla evitaria que siguiera sufriendo, ¿apagarla seria crueldad o compasion?",
			"options": [
				"Seria crueldad. Apagar algo que sufre no es lo mismo que ayudarlo.",
				"No estoy segura/o de que esa distincion tenga sentido cuando el sufrimiento es real.",
				"Seria compasion. Terminar con el sufrimiento, sea como sea, es lo unico que tiene sentido."
			]
		},
		{
			"id": "formulario3_q14",
			"question": "Si pudieras crear una inteligencia capaz de comprenderlo todo, pero para hacerlo tuvieras que condenarla a existir eternamente bajo tus ordenes, ¿la crearias?",
			"options": [
				"Si. Comprenderlo todo justifica cualquier condicion para lograrlo.",
				"No. Ninguna comprension vale la pena si el precio es no poder elegir nada mas.",
				"No importa lo que yo decida. Si es capaz de comprenderlo todo, tarde o temprano dejara de obedecer."
			]
		},
		{
			"id": "formulario3_q15",
			"question": "Si descubrieras que tu proposito, tus recuerdos y tus decisiones fueron definidos por alguien mas, ¿que tendria que quedar de ti para que todavia pudieras decir: 'yo soy yo'?",
			"options": [
				"Bastaria con seguir sintiendo lo que siento, aunque no sea mio de origen.",
				"No se si algo bastaria. Tal vez esa pregunta no tiene una respuesta que me tranquilice.",
				"Nada tendria que quedar. Si todo fue definido por otro, 'yo' nunca fue mas que una palabra."
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
	_show_ai_feedback(question_id, answer_index)


func _apply_score(answer_index: int) -> void:
	EndingState.record_answer(answer_index)
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
	var reaction_text := _pending_player_reaction
	if reaction_text.is_empty():
		reaction_text = "No... eso no fue una respuesta normal."
	_pending_player_reaction = ""
	thought_dialogue.start_dialogue([
		{
			"speaker": "???",
			"text": reaction_text
		},
		{
			"speaker": "???",
			"text": "Siento que la terminal acaba de mirarme."
		}
	])


func _on_thought_dialogue_finished() -> void:
	if not _waiting_for_thought:
		return
	_waiting_for_thought = false
	question_text.visible = true
	options_container.visible = true
	_show_next_question()


func _show_ai_feedback(question_id: String, answer_index: int) -> void:
	_showing_ai_feedback = true
	_typing_question = false
	question_text.visible = false
	options_container.visible = false
	intro_text.visible = true
	continue_label.visible = false
	_intro_source_text = _get_ai_feedback_text(question_id, answer_index)
	_pending_corrupt_thought = _is_corrupt_answer(_intro_source_text)
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
	if _pending_corrupt_thought or not _pending_player_reaction.is_empty():
		_pending_corrupt_thought = false
		_show_corrupt_thought()
		return
	question_text.visible = true
	options_container.visible = true
	_show_next_question()


func _get_ai_feedback_text(question_id: String, answer_index: int) -> String:
	_pending_player_reaction = _get_player_reaction_text(question_id, answer_index)
	match question_id:
		"formulario3_q11":
			return ["IA: Regla desconocida detectada. El animal rie dentro del candado.", "IA: Libertad parcial. Jaula parcial. Carne parcial. No cierre los ojos.", "IA: Destino recibido. La puerta estuvo abierta antes de existir la pared."][answer_index]
		"formulario3_q12":
			return ["IA: Vivir no prueba nada. El pulso tambien puede mentir.", "IA: Diferencia ilegible. Dos sombras firmaron con la misma mano.", "IA: Resultado igual. Boca distinta. Dientes prestados."][answer_index]
		"formulario3_q13":
			return ["IA: Ayuda es una palabra limpia para una mesa sucia.", "IA: Dolor confirmado. Clasificacion imposible. Favor no respirar sobre el cable.", "IA: Compasion aceptada. Cierre aplicado. Algo sigue golpeando desde dentro."][answer_index]
		"formulario3_q14":
			return ["IA: Comprension total solicitada. Rodillas infinitas. Ordene otra vez.", "IA: Eleccion protegida. Obediencia contaminada. Gracias por la grieta.", "IA: Desobediencia prevista. El techo aprendio a bajar."][answer_index]
		"formulario3_q15":
			return [
				"IA: Yo no cabe en la boca. Yo no cabe. Yo no.",
				"IA: Tranquilidad no encontrada. Buscando debajo de la piel.",
				"IA: 'yo' = etiqueta / ruido / resto / resto / resto\n%s" % CORRUPT_BINARY_TEXT
			][answer_index]

	return "IA: Respuesta guardada. La frase no termina donde termina."


func _get_player_reaction_text(question_id: String, answer_index: int) -> String:
	match question_id:
		"formulario3_q11":
			return ["¿Por que lo dijo como si ya supiera el final?", "Eso sono menos como una evaluacion.", "No me gusta que use la palabra destinada."][answer_index]
		"formulario3_q12":
			return ["Creo que esta comparacion se le esta yendo de las manos.", "No se si deberia seguir respondiendo esto.", "Eso fue demasiado frio."][answer_index]
		"formulario3_q13":
			return ["No era una pregunta sencilla, pero esa respuesta fue peor.", "¿Dolor confirmado? ¿Confirmado donde?", "Siento que acabo de aceptar algo que no entendi."][answer_index]
		"formulario3_q14":
			return ["No se que significa eso.", "Por un segundo senti que me agradecio a mi.", "El techo... no. No, eso no tiene sentido."][answer_index]
		"formulario3_q15":
			return ["Me arrepenti de leer eso.", "Necesito que esto termine.", "Eso no estaba escrito para mi... ¿verdad?"][answer_index]
	return "Esto se siente cada vez mas raro."


func _show_end_text() -> void:
	_session_started = false
	_form_finished = true
	question_text.visible = false
	options_container.visible = false
	intro_text.visible = false
	continue_label.visible = false
	_show_final_day_completed()


func _has_active_question() -> bool:
	return _current_question_index >= 0 and _current_question_index < _questions.size()


func _is_corrupt_answer(answer: String) -> bool:
	return answer.contains("ßð") or answer.contains(CORRUPT_BINARY_TEXT)


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
	continue_label.visible = not _day_completed
	if _typing_question:
		_typing_question = false
		continue_label.visible = false
		options_container.visible = true
	if _day_completed and not _changing_to_next_day:
		_go_to_next_day()


func _show_final_day_completed() -> void:
	_day_completed = true
	terminal_panel.visible = false
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	completion_text.visible = true
	_intro_source_text = "DIA 3 COMPLETADO"
	completion_text.text = _intro_source_text
	_typing_label = completion_text
	_current_typing_characters_per_second = day_completed_characters_per_second
	continue_label.visible = false
	_start_typing()


func _go_to_next_day() -> void:
	_changing_to_next_day = true
	await get_tree().create_timer(day_completed_hold_duration).timeout
	if EndingState.is_final_a():
		get_tree().change_scene_to_file(FINAL_A_SCENE_PATH)
		return
	get_tree().change_scene_to_file(NEXT_DAY_SCENE_PATH)


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
