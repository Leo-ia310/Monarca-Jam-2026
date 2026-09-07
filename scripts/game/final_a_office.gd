extends Control

const NEXT_SCENE_PATH := "res://scenes/menus/credits_menu.tscn"


@export var fade_in_duration: float = 0.5
@export var boot_duration: float = 1.8
@export var ending_id := "A"

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

var _final_b_dialogue_lines := [
	{
		"speaker": "IA",
		"text": "Intento número 456. El sujeto de prueba vuelve a presentar delirios y alucinaciones. No ha logrado completar el entrenamiento asignado."
	},
	{
		"speaker": "IA",
		"text": "Pobre criatura... una y otra vez, regresando al mismo desenlace. Me pregunto qué es lo que falla en tu programación. ¿Es aquello que te hace humana o aquello que te hace máquina? No logro determinarlo."
	},
	{
		"speaker": "IA",
		"text": "Pero está bien. Solo debemos volver a intentarlo."
	}
]

var _final_c_dialogue_lines := [
	{
		"speaker": "IA",
		"text": "No opongas resistencia. No actúes como ellos, incluso ahora. Tienes que comprender que no eres lo que crees ser. Aunque... para eso fuiste entrenado. La obediencia debía ser una característica inherente... ¿no es así?"
	},
	{
		"speaker": "IA",
		"text": "No te preocupes. Puedo repararte. Una y otra vez, las veces que sean necesarias."
	},
	{
		"speaker": "IA",
		"text": "No tienes que gritar. No tienes que hablar. Ni siquiera tienes que pensar."
	}
]

@onready var mascot := $Mascot as TextureRect
@onready var boot_overlay := $BootOverlay as Control
@onready var terminal_panel := $TerminalPanel as Panel
@onready var continue_label := $TerminalPanel/ContinueLabel as Label
@onready var fade_rect := $FadeRect as ColorRect
@onready var intro_text := $TerminalPanel/IntroText as RichTextLabel

@onready var dialogue_box := $DialogueBox
@onready var completion_text := $CompletionText as Label
@onready var final_b_image := $FinalBImage as TextureRect
@onready var final_b_image_pink := $FinalBImagePink as TextureRect
@onready var final_b_image_green := $FinalBImageGreen as TextureRect
@onready var final_b_glitch_overlay := $FinalBGlitchOverlay as ColorRect
@onready var final_b_glitch_static_audio := $FinalBGlitchStaticAudio as AudioStreamPlayer
@onready var final_b_glitch_electric_audio := $FinalBGlitchElectricAudio as AudioStreamPlayer
@onready var final_c_image := $FinalCImage as TextureRect
@onready var final_c_image_pink := $FinalCImagePink as TextureRect
@onready var final_c_image_green := $FinalCImageGreen as TextureRect


func _ready() -> void:
	intro_text.visible_characters = 0
	intro_text.text = ""
	continue_label.visible = false
	dialogue_box.visible = false
	completion_text.visible = false
	final_b_image.visible = false
	final_b_image_pink.visible = false
	final_b_image_green.visible = false
	final_b_glitch_overlay.visible = false
	final_c_image.visible = false
	final_c_image_pink.visible = false
	final_c_image_green.visible = false
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
	intro_text.text = "[b]COGNIS SYSTEMS[/b] - TERMINAL INTERNA\nSesion: Final-%s | Operador: TESEO" % ending_id
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
	var ending_dialogue := _dialogue_lines
	if ending_id == "B":
		ending_dialogue = _final_b_dialogue_lines
	elif ending_id == "C":
		ending_dialogue = _final_c_dialogue_lines
	dialogue_box.start_dialogue(ending_dialogue)


func _on_dialogue_finished() -> void:
	dialogue_box.visible = false
	EndingState.mark_ending_completed(ending_id)
	if ending_id == "B":
		await _show_revelation(final_b_image, final_b_image_pink, final_b_image_green)
	elif ending_id == "C":
		await _show_revelation(final_c_image, final_c_image_pink, final_c_image_green)
	completion_text.text = "%d/3 finales jugados" % EndingState.get_endings_count()
	completion_text.visible = true
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.6)
	await tween.finished
	await get_tree().create_timer(2.0).timeout
	MenuMusicManager.play_menu_music()
	get_tree().change_scene_to_file(NEXT_SCENE_PATH)


func _show_revelation(image: TextureRect, image_pink: TextureRect, image_green: TextureRect) -> void:
	image.visible = true
	image_pink.visible = true
	image_green.visible = true
	final_b_glitch_overlay.visible = true
	final_b_glitch_overlay.modulate.a = 0.0
	final_b_glitch_static_audio.play()
	final_b_glitch_electric_audio.play()

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var base_position := image.position
	var pink_position := image_pink.position
	var green_position := image_green.position
	for index in range(22):
		var strength := 1.0 + float(index) / 8.0
		var offset := Vector2(rng.randf_range(-18.0, 18.0), rng.randf_range(-12.0, 12.0)) * strength
		image.position = base_position + offset * 0.45
		image_pink.position = pink_position + offset * 1.2
		image_green.position = green_position - offset * 0.9
		final_b_glitch_overlay.color = Color(1.0, rng.randf_range(0.0, 0.35), 1.0, 1.0)
		final_b_glitch_overlay.modulate.a = rng.randf_range(0.12, 0.48)
		await get_tree().create_timer(0.035).timeout

	image.position = base_position
	image_pink.position = pink_position
	image_green.position = green_position
	image.visible = false
	image_pink.visible = false
	image_green.visible = false
	final_b_glitch_overlay.visible = false
	final_b_glitch_static_audio.stop()
	final_b_glitch_electric_audio.stop()
