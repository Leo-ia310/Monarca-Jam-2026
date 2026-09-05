extends Control

const COGNIS_WELCOME_PATH := "res://scenes/story/cognis_welcome.tscn"
const OPTIONS_MENU_PATH := "res://scenes/menus/options_menu.tscn"
const CREDITS_MENU_PATH := "res://scenes/menus/credits_menu.tscn"

@onready var play_button := get_node("PageMargin/Center/MenuStack/PlayButton") as Button
@onready var options_button := get_node("PageMargin/Center/MenuStack/OptionsButton") as Button
@onready var credits_button := get_node("PageMargin/Center/MenuStack/CreditsButton") as Button
@onready var exit_button := get_node("PageMargin/Center/MenuStack/ExitButton") as Button


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	_configure_focus_chain([play_button, options_button, credits_button, exit_button])
	play_button.grab_focus()


func _configure_focus_chain(controls: Array[Control]) -> void:
	for index in range(controls.size()):
		var control := controls[index]
		var previous_control := controls[(index - 1 + controls.size()) % controls.size()]
		var next_control := controls[(index + 1) % controls.size()]

		control.focus_mode = Control.FOCUS_ALL
		control.focus_neighbor_top = control.get_path_to(previous_control)
		control.focus_neighbor_bottom = control.get_path_to(next_control)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(COGNIS_WELCOME_PATH)


func _on_options_pressed() -> void:
	get_tree().change_scene_to_file(OPTIONS_MENU_PATH)


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file(CREDITS_MENU_PATH)


func _on_exit_pressed() -> void:
	get_tree().quit()
