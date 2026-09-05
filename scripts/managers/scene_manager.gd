extends Node

const MAIN_MENU_PATH := "res://scenes/menus/main_menu.tscn"

var current_scene_path := ""
var previous_scene_path := ""


func _ready() -> void:
	var current_scene := get_tree().current_scene
	if current_scene != null:
		current_scene_path = current_scene.scene_file_path


func change_scene(scene_path: String) -> void:
	if scene_path.is_empty():
		push_warning("SceneManager.change_scene received an empty path.")
		return

	var current_scene := get_tree().current_scene
	if current_scene != null:
		previous_scene_path = current_scene.scene_file_path

	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Could not change scene to %s: %s" % [scene_path, error_string(error)])
		return

	current_scene_path = scene_path


func return_to_main_menu() -> void:
	change_scene(MAIN_MENU_PATH)


func quit_game() -> void:
	get_tree().quit()
