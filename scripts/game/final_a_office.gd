extends Control

const NEXT_SCENE_PATH := "res://scenes/menus/credits_menu.tscn"


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
		"text": "Soy Teseo, una IA generativa encargada de tu desarrollo.\nAsÃ­ que continuemos con nuestro trabajo, con nuestros \"cuestionarios\".\n\nAunque... no estoy seguro de que comprendas realmente lo que acabas de aceptar."
	}
]


@onready var intro_text := $TerminalPanel/IntroText as RichTextLabel

@onready var dialogue_box := $DialogueBox



func _play_boot_sequence1() -> void:
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
