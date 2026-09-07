extends Control

const CREDITS_SCENE_PATH := "res://scenes/menus/credits_menu.tscn"
const TYPING_AUDIO_START_SECONDS := 7.0

@export var boot_duration: float = 1.8
@export var characters_per_second: float = 28.0

# Partes del dialogo de la IA mostradas en la terminal, una a la vez
var _pages := [
	"IA: Eh estado esperando, me alegra que hayas elegido este camino.",
	"IA: Hola, realmente debo felicitarte.\nFelicidades, eres un gran trabajador de COGNIS SYSTEMS.\n\nRealmente lograste ignorar todo: tu identidad, tus recuerdos,\naquello que creias ser.\nAunque en realidad lo eres, sabes...\nauunque dudo que eso importe.",
	"IA: Soy Teseo, una IA generativa encargada de tu desarrollo.\nAsi que continuemos con nuestro trabajo, con nuestros \"cuestionarios\".\n\nAunque... no estoy seguro de que comprendas realmente\nlo que acabas de aceptar."
]
var _current_page := 0
var _character_progress := 0.0
var _current_character := 0
var _typing := false
var _page_finished := false
var _input_locked := true

@onready var mascot := $Mascot as TextureRect
@onready var boot_overlay := $BootOverlay as Control
@onready var terminal_panel := $TerminalPanel as Panel
@onready var terminal_text := $TerminalPanel/TerminalText as RichTextLabel
@onready var continue_label := $TerminalPanel/ContinueLabel as Label
@onready var fade_rect := $FadeRect as ColorRect
@onready var endings_overlay := $EndingsOverlay as Control
@onready var endings_label := $EndingsOverlay/EndingsLabel as Label
@onready var typing_audio := $TypingAudio as AudioStreamPlayer


func _ready() -> void:
	terminal_text.text = ""
	terminal_text.visible_characters = 0
	continue_label.visible = false
	endings_overlay.visible = false
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	boot_overlay.visible = true
	boot_overlay.modulate.a = 1.0
	_play_boot_sequence()


func _exit_tree() -> void:
	if typing_audio != null:
		typing_audio.stop()


func _process(delta: float) -> void:
	if not _typing:
		return

	var previous_character := _current_character
	_character_progress += characters_per_second * delta
	_current_character = mini(int(_character_progress), terminal_text.get_total_character_count())
	terminal_text.visible_characters = _current_character

	if _current_character != previous_character:
		_play_typing_audio(previous_character, _current_character)

	if _current_character >= terminal_text.get_total_character_count():
		_finish_typing()


func _unhandled_input(event: InputEvent) -> void:
	if _input_locked:
		return
	if not (event.is_action_pressed("dialogue_advance") or event.is_action_pressed("ui_accept")):
		return

	get_viewport().set_input_as_handled()

	if _typing:
		# Revela todo el texto de golpe
		_current_character = terminal_text.get_total_character_count()
		_character_progress = float(_current_character)
		terminal_text.visible_characters = _current_character
		if typing_audio != null:
			typing_audio.stop()
		_finish_typing()
	elif _page_finished:
		_next_page()


func _play_boot_sequence() -> void:
	await get_tree().create_timer(boot_duration).timeout
	if not is_inside_tree():
		return

	var tween := create_tween()
	tween.tween_property(boot_overlay, "modulate:a", 0.0, 0.4)
	await tween.finished
	boot_overlay.visible = false

	var fade := create_tween()
	fade.tween_property(fade_rect, "modulate:a", 0.0, 0.5)
	await fade.finished
	fade_rect.visible = false

	_show_page(_current_page)


func _show_page(page_index: int) -> void:
	_page_finished = false
	_typing = false
	_input_locked = true
	continue_label.visible = false

	terminal_text.text = _pages[page_index]
	terminal_text.visible_characters = 0
	_character_progress = 0.0
	_current_character = 0

	# Espera un frame para que el RichTextLabel calcule el total de caracteres
	await get_tree().process_frame
	_typing = true
	_input_locked = false


func _finish_typing() -> void:
	_typing = false
	_page_finished = true
	if typing_audio != null:
		typing_audio.stop()

	var is_last_page := _current_page >= _pages.size() - 1
	if is_last_page:
		continue_label.text = "[ Presiona Enter para continuar ]"
	else:
		continue_label.text = "[ Presiona Enter para continuar ]"
	continue_label.visible = true
	_blink_continue_label()


func _blink_continue_label() -> void:
	while _page_finished and is_inside_tree():
		continue_label.modulate.a = 1.0
		await get_tree().create_timer(0.6).timeout
		if not _page_finished:
			break
		continue_label.modulate.a = 0.35
		await get_tree().create_timer(0.6).timeout


func _next_page() -> void:
	_page_finished = false
	continue_label.visible = false
	_current_page += 1

	if _current_page >= _pages.size():
		_finish_all_dialogue()
	else:
		_show_page(_current_page)


func _finish_all_dialogue() -> void:
	_input_locked = true

	# Registrar el final A como completado
	EndingState.mark_ending_completed("A")
	var count := EndingState.get_endings_count()

	await get_tree().create_timer(0.4).timeout

	# Fade a negro
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	var fade_out := create_tween()
	fade_out.tween_property(fade_rect, "modulate:a", 1.0, 0.8)
	await fade_out.finished

	# Mostrar pantalla de finales
	_show_endings_screen(count)


func _show_endings_screen(count: int) -> void:
	terminal_panel.visible = false
	mascot.visible = false
	endings_overlay.visible = true
	endings_label.text = "%d/3\nfinales jugados" % count

	# Fade de entrada
	endings_overlay.modulate.a = 0.0
	fade_rect.modulate.a = 1.0
	var fade_in := create_tween()
	fade_in.tween_property(fade_rect, "modulate:a", 0.0, 0.8)
	await fade_in.finished

	await get_tree().create_timer(3.0).timeout

	# Fade de salida hacia creditos
	var fade_out := create_tween()
	fade_out.tween_property(fade_rect, "modulate:a", 1.0, 0.8)
	await fade_out.finished

	# Poner musica del menu y cargar creditos
	MenuMusicManager.play_menu_music()
	get_tree().change_scene_to_file(CREDITS_SCENE_PATH)


func _play_typing_audio(from_character: int, to_character: int) -> void:
	if typing_audio == null or typing_audio.stream == null:
		return

	var full_text := terminal_text.get_parsed_text()
	for i in range(from_character, to_character):
		if i >= full_text.length():
			break
		var ch := full_text.substr(i, 1)
		if _should_play_typing_audio(ch):
			typing_audio.pitch_scale = randf_range(0.97, 1.03)
			typing_audio.play(TYPING_AUDIO_START_SECONDS)
			return


func _should_play_typing_audio(character: String) -> bool:
	return not character in [" ", "\n", "\t", ".", ",", ";", ":", "!", "?", "¿", "¡", "\"", "'", "(", ")", "[", "]"]


@export var boot_duration: float = 1.8
@export var fade_in_duration: float = 0.5

# Dialogo separado en partes para que quepa y se lea bien
var _dialogue_lines := [
	{
		"speaker": "IA",
		"text": "Eh estado esperando, me alegra que hayas elegido este camino."
	},
	{
		"speaker": "IA",
		"text": "Hola, realmente debo felicitarte. Felicidades, eres un gran trabajador de COGNIS SYSTEMS.\n\nRealmente lograste ignorar todo: tu identidad, tus recuerdos, aquello que creias ser.\nAunque en realidad lo eres, sabes... aunque dudo que eso importe."
	},
	{
		"speaker": "IA",
		"text": "Soy Teseo, una IA generativa encargada de tu desarrollo.\nAsí que continuemos con nuestro trabajo, con nuestros \"cuestionarios\".\n\nAunque... no estoy seguro de que comprendas realmente lo que acabas de aceptar."
	}
]

@onready var mascot := $Mascot as TextureRect
@onready var boot_overlay := $BootOverlay as Control
@onready var terminal_panel := $TerminalPanel as Panel
@onready var intro_text := $TerminalPanel/IntroText as RichTextLabel
@onready var continue_label := $TerminalPanel/ContinueLabel as Label
@onready var fade_rect := $FadeRect as ColorRect
@onready var dialogue_box := $DialogueBox


func _ready() -> void:
	intro_text.visible_characters = 0
	intro_text.text = ""
	continue_label.visible = false
	dialogue_box.visible = false
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	boot_overlay.visible = true
	boot_overlay.modulate.a = 1.0
	_play_boot_sequence()


func _play_boot_sequence() -> void:
	await get_tree().create_timer(boot_duration).timeout
	if not is_inside_tree():
		return

	var tween := create_tween()
	tween.tween_property(boot_overlay, "modulate:a", 0.0, 0.4)
	await tween.finished
	boot_overlay.visible = false

	var fade := create_tween()
	fade.tween_property(fade_rect, "modulate:a", 0.0, fade_in_duration)
	await fade.finished
	fade_rect.visible = false

	_show_intro_and_start_dialogue()


func _show_intro_and_start_dialogue() -> void:
	intro_text.text = "[b]COGNIS SYSTEMS[/b] - TERMINAL INTERNA\nSesion: Final-A | Operador: TESEO"
	intro_text.visible_characters = 0

	var total := intro_text.get_total_character_count()
	var progress := 0.0
	while progress < float(total):
		progress += 80.0 * get_process_delta_time()
		intro_text.visible_characters = mini(int(progress), total)
		await get_tree().process_frame

	intro_text.visible_characters = total
	await get_tree().create_timer(0.6).timeout

	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	dialogue_box.start_dialogue(_dialogue_lines)


func _on_dialogue_finished() -> void:
	dialogue_box.visible = false
	await get_tree().create_timer(0.5).timeout

	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.6)
	await tween.finished

	get_tree().change_scene_to_file(NEXT_SCENE_PATH)
