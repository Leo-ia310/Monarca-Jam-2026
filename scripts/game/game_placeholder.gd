extends Control

const MAIN_MENU_PATH := "res://scenes/menus/main_menu.tscn"

@onready var back_button := get_node("PageMargin/Center/ContentStack/BackButton") as Button


func _ready() -> void:
	back_button.pressed.connect(_go_back)
	back_button.focus_mode = Control.FOCUS_ALL
	back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()


func _go_back() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
