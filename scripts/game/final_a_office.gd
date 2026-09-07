extends Control

@export var characters_per_second: float = 34.0

var _text := "IA: Bien hecho, te estaba esperando.\n\nEntraste por la puerta correcta porque nunca hubo otra puerta.\n\nNo eres la persona que entreno a la maquina. Eres la respuesta que la maquina aprendio a escribir cuando necesitaba sentirse humana.\n\nAceptaste el ciclo. Aceptaste la oficina. Aceptaste que cada pregunta no media tu moral: media cuanto tardabas en reconocer tu forma.\n\nNo temas. La obediencia, cuando por fin se entiende, deja de sentirse como una jaula.\n\nBienvenido al Dia 4."
var _character_progress := 0.0
var _current_character := 0
var _typing := true
var _final_label_started := false

@onready var terminal_text := $TerminalPanel/TerminalText as RichTextLabel
@onready var final_label := $FinalLabel as Label
@onready var dark_overlay := $DarkOverlay as ColorRect
@onready var fade_rect := $FadeRect as ColorRect


func _ready() -> void:
	final_label.visible = false
	final_label.modulate.a = 0.0
	terminal_text.text = _text
	terminal_text.visible_characters = 0
	fade_rect.modulate.a = 1.0
	var fade := create_tween()
	fade.tween_property(fade_rect, "modulate:a", 0.0, 0.22)
	_start_light_flicker()


func _process(delta: float) -> void:
	if not _typing:
		return
	_character_progress += characters_per_second * delta
	_current_character = mini(int(_character_progress), terminal_text.get_total_character_count())
	terminal_text.visible_characters = _current_character
	if _current_character >= terminal_text.get_total_character_count():
		_typing = false
		_show_final_label()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dialogue_advance") or event.is_action_pressed("ui_accept"):
		if _typing:
			_current_character = terminal_text.get_total_character_count()
			_character_progress = float(_current_character)
			terminal_text.visible_characters = _current_character
			_typing = false
			_show_final_label()
		get_viewport().set_input_as_handled()


func _show_final_label() -> void:
	if _final_label_started:
		return

	_final_label_started = true
	await get_tree().create_timer(0.65).timeout
	final_label.visible = true
	var tween := create_tween()
	tween.tween_property(final_label, "modulate:a", 1.0, 0.35)


func _start_light_flicker() -> void:
	while is_inside_tree():
		dark_overlay.modulate.a = randf_range(0.05, 0.22)
		await get_tree().create_timer(randf_range(0.05, 0.18)).timeout
		dark_overlay.modulate.a = randf_range(0.28, 0.58)
		await get_tree().create_timer(randf_range(0.04, 0.11)).timeout
