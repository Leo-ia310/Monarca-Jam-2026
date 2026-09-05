extends Control

const MAIN_MENU_PATH := "res://scenes/menus/main_menu.tscn"

@onready var volume_slider := get_node("PageMargin/Center/MenuStack/VolumeRow/VolumeSlider") as HSlider
@onready var fullscreen_check := get_node("PageMargin/Center/MenuStack/FullscreenCheck") as CheckButton
@onready var back_button := get_node("PageMargin/Center/MenuStack/BackButton") as Button


func _ready() -> void:
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	back_button.pressed.connect(_go_back)

	volume_slider.value = _get_master_volume_percent()
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

	_configure_focus_chain([volume_slider, fullscreen_check, back_button])
	volume_slider.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()


func _configure_focus_chain(controls: Array[Control]) -> void:
	for index in range(controls.size()):
		var control := controls[index]
		var previous_control := controls[(index - 1 + controls.size()) % controls.size()]
		var next_control := controls[(index + 1) % controls.size()]

		control.focus_mode = Control.FOCUS_ALL
		control.focus_neighbor_top = control.get_path_to(previous_control)
		control.focus_neighbor_bottom = control.get_path_to(next_control)


func _get_master_volume_percent() -> float:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus == -1:
		return 100.0

	var linear_volume := db_to_linear(AudioServer.get_bus_volume_db(master_bus))
	return clampf(linear_volume * 100.0, 0.0, 100.0)


func _on_volume_changed(value: float) -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus == -1:
		return

	if value <= 0.0:
		AudioServer.set_bus_volume_db(master_bus, -80.0)
	else:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(value / 100.0))


func _on_fullscreen_toggled(enabled: bool) -> void:
	var target_mode := DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(target_mode)


func _go_back() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
