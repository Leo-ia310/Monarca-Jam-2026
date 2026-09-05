extends Control

const MAIN_MENU_PATH := "res://scenes/menus/main_menu.tscn"

var _syncing_ui := false
var _settings_manager: Node

@onready var master_volume_slider := get_node("PageMargin/Center/MenuStack/MasterVolumeRow/MasterVolumeSlider") as HSlider
@onready var music_volume_slider := get_node("PageMargin/Center/MenuStack/MusicVolumeRow/MusicVolumeSlider") as HSlider
@onready var sfx_volume_slider := get_node("PageMargin/Center/MenuStack/SfxVolumeRow/SfxVolumeSlider") as HSlider
@onready var resolution_option := get_node("PageMargin/Center/MenuStack/ResolutionRow/ResolutionOption") as OptionButton
@onready var fullscreen_check := get_node("PageMargin/Center/MenuStack/FullscreenCheck") as CheckButton
@onready var vsync_check := get_node("PageMargin/Center/MenuStack/VsyncCheck") as CheckButton
@onready var back_button := get_node("PageMargin/Center/MenuStack/BackButton") as Button


func _ready() -> void:
	_settings_manager = get_node("/root/SettingsManager")

	_populate_resolution_options()
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	resolution_option.item_selected.connect(_on_resolution_selected)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	back_button.pressed.connect(_go_back)

	_sync_ui_with_settings()

	_configure_focus_chain([
		master_volume_slider,
		music_volume_slider,
		sfx_volume_slider,
		resolution_option,
		fullscreen_check,
		vsync_check,
		back_button,
	])
	master_volume_slider.grab_focus()


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


func _populate_resolution_options() -> void:
	resolution_option.clear()
	for resolution in _settings_manager.get_available_resolutions():
		resolution_option.add_item("%dx%d" % [resolution.x, resolution.y])
		resolution_option.set_item_metadata(resolution_option.item_count - 1, resolution)


func _sync_ui_with_settings() -> void:
	_syncing_ui = true

	master_volume_slider.value = _settings_manager.get_master_volume()
	music_volume_slider.value = _settings_manager.get_music_volume()
	sfx_volume_slider.value = _settings_manager.get_sfx_volume()
	fullscreen_check.button_pressed = _settings_manager.get_fullscreen()
	vsync_check.button_pressed = _settings_manager.get_vsync()
	_select_resolution(_settings_manager.get_resolution())

	_syncing_ui = false


func _select_resolution(target_resolution: Vector2i) -> void:
	for index in range(resolution_option.item_count):
		var item_resolution := resolution_option.get_item_metadata(index) as Vector2i
		if item_resolution == target_resolution:
			resolution_option.select(index)
			return

	resolution_option.select(2)


func _on_master_volume_changed(value: float) -> void:
	if not _syncing_ui:
		_settings_manager.set_master_volume(value)


func _on_music_volume_changed(value: float) -> void:
	if not _syncing_ui:
		_settings_manager.set_music_volume(value)


func _on_sfx_volume_changed(value: float) -> void:
	if not _syncing_ui:
		_settings_manager.set_sfx_volume(value)


func _on_resolution_selected(index: int) -> void:
	if _syncing_ui:
		return

	var selected_resolution := resolution_option.get_item_metadata(index) as Vector2i
	_settings_manager.set_resolution(selected_resolution)


func _on_fullscreen_toggled(enabled: bool) -> void:
	if not _syncing_ui:
		_settings_manager.set_fullscreen(enabled)


func _on_vsync_toggled(enabled: bool) -> void:
	if not _syncing_ui:
		_settings_manager.set_vsync(enabled)


func _go_back() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
