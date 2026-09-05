extends Control

const GAME_PLACEHOLDER_PATH := "res://scenes/game/game_placeholder.tscn"
const OPTIONS_MENU_PATH := "res://scenes/menus/options_menu.tscn"
const CREDITS_MENU_PATH := "res://scenes/menus/credits_menu.tscn"

@onready var play_button := get_node("PageMargin/Center/MenuStack/PlayButton") as Button
@onready var options_button := get_node("PageMargin/Center/MenuStack/OptionsButton") as Button
@onready var credits_button := get_node("PageMargin/Center/MenuStack/CreditsButton") as Button
@onready var exit_button := get_node("PageMargin/Center/MenuStack/ExitButton") as Button


func _ready() -> void:
	print("MAIN MENU SCRIPT CARGADO")
	print("PlayButton:", play_button)
	print("OptionsButton:", options_button)
	print("CreditsButton:", credits_button)
	print("ExitButton:", exit_button)
	print("Existe game_placeholder:", ResourceLoader.exists(GAME_PLACEHOLDER_PATH))
	print("Existe options_menu:", ResourceLoader.exists(OPTIONS_MENU_PATH))
	print("Existe credits_menu:", ResourceLoader.exists(CREDITS_MENU_PATH))
	_print_mouse_filter_diagnostics()

	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	play_button.mouse_entered.connect(func(): print("MOUSE SOBRE JUGAR"))
	options_button.mouse_entered.connect(func(): print("MOUSE SOBRE OPCIONES"))
	credits_button.mouse_entered.connect(func(): print("MOUSE SOBRE CREDITOS"))
	exit_button.mouse_entered.connect(func(): print("MOUSE SOBRE SALIR"))

	play_button.button_down.connect(func(): print("BUTTON DOWN JUGAR"))
	options_button.button_down.connect(func(): print("BUTTON DOWN OPCIONES"))
	credits_button.button_down.connect(func(): print("BUTTON DOWN CREDITOS"))
	exit_button.button_down.connect(func(): print("BUTTON DOWN SALIR"))

	_print_button_diagnostics("PlayButton", play_button)
	_print_button_diagnostics("OptionsButton", options_button)
	_print_button_diagnostics("CreditsButton", credits_button)
	_print_button_diagnostics("ExitButton", exit_button)

	_configure_focus_chain([play_button, options_button, credits_button, exit_button])
	play_button.grab_focus()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("CLICK RECIBIDO POR MAIN MENU EN:", event.position)


func _configure_focus_chain(controls: Array[Control]) -> void:
	for index in range(controls.size()):
		var control := controls[index]
		var previous_control := controls[(index - 1 + controls.size()) % controls.size()]
		var next_control := controls[(index + 1) % controls.size()]

		control.focus_mode = Control.FOCUS_ALL
		control.focus_neighbor_top = control.get_path_to(previous_control)
		control.focus_neighbor_bottom = control.get_path_to(next_control)


func _print_mouse_filter_diagnostics() -> void:
	var controls := [
		self,
		get_node("Background") as Control,
		get_node("PageMargin") as Control,
		get_node("PageMargin/Center") as Control,
		get_node("PageMargin/Center/MenuStack") as Control,
		get_node("PageMargin/Center/MenuStack/TitleLabel") as Control,
		get_node("PageMargin/Center/MenuStack/SubtitleLabel") as Control,
		get_node("PageMargin/Center/MenuStack/ButtonSpacer") as Control,
		play_button,
		options_button,
		credits_button,
		exit_button,
	]

	for control in controls:
		print(
			"CONTROL INPUT ",
			control.name,
			" rect=", control.get_global_rect(),
			" mouse_filter=", control.mouse_filter,
			" visible=", control.visible,
			" z_index=", control.z_index,
			" process_mode=", control.process_mode
		)


func _print_button_diagnostics(button_name: String, button: Button) -> void:
	print(
		button_name,
		" disabled=", button.disabled,
		" visible=", button.visible,
		" mouse_filter=", button.mouse_filter,
		" process_mode=", button.process_mode,
		" pressed_connections=", button.pressed.get_connections().size()
	)


func _on_play_pressed() -> void:
	print("JUGAR PRESIONADO")
	var error := get_tree().change_scene_to_file(GAME_PLACEHOLDER_PATH)
	print("Resultado cambio a juego:", error)


func _on_options_pressed() -> void:
	print("OPCIONES PRESIONADO")
	var error := get_tree().change_scene_to_file(OPTIONS_MENU_PATH)
	print("Resultado cambio a opciones:", error)


func _on_credits_pressed() -> void:
	print("CREDITOS PRESIONADO")
	var error := get_tree().change_scene_to_file(CREDITS_MENU_PATH)
	print("Resultado cambio a créditos:", error)


func _on_exit_pressed() -> void:
	print("SALIR PRESIONADO")
	get_tree().quit()
