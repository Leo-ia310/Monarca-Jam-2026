extends Node

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_MASTER_VOLUME := 100.0
const DEFAULT_MUSIC_VOLUME := 80.0
const DEFAULT_SFX_VOLUME := 80.0
const DEFAULT_FULLSCREEN := false
const DEFAULT_RESOLUTION := Vector2i(1280, 720)
const DEFAULT_VSYNC := true
const MIN_VOLUME_DB := -80.0

const AVAILABLE_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(854, 480),
	Vector2i(960, 540),
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]

var master_volume := DEFAULT_MASTER_VOLUME
var music_volume := DEFAULT_MUSIC_VOLUME
var sfx_volume := DEFAULT_SFX_VOLUME
var fullscreen := DEFAULT_FULLSCREEN
var resolution := DEFAULT_RESOLUTION
var vsync := DEFAULT_VSYNC


func _ready() -> void:
	_ensure_audio_buses()
	load_settings()
	apply_settings()
	save_settings()


func load_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(SETTINGS_PATH)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		push_warning("Could not load settings.cfg. Defaults will be used.")

	master_volume = _sanitize_volume(float(config.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME)))
	music_volume = _sanitize_volume(float(config.get_value("audio", "music_volume", DEFAULT_MUSIC_VOLUME)))
	sfx_volume = _sanitize_volume(float(config.get_value("audio", "sfx_volume", DEFAULT_SFX_VOLUME)))
	fullscreen = bool(config.get_value("display", "fullscreen", DEFAULT_FULLSCREEN))
	vsync = bool(config.get_value("display", "vsync", DEFAULT_VSYNC))

	var width := int(config.get_value("display", "resolution_width", DEFAULT_RESOLUTION.x))
	var height := int(config.get_value("display", "resolution_height", DEFAULT_RESOLUTION.y))
	resolution = _sanitize_resolution(Vector2i(width, height))


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "resolution_width", resolution.x)
	config.set_value("display", "resolution_height", resolution.y)
	config.set_value("display", "vsync", vsync)

	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_error("Could not save settings.cfg: %s" % error_string(error))


func apply_settings() -> void:
	_ensure_audio_buses()
	_apply_bus_volume("Master", master_volume)
	_apply_bus_volume("Music", music_volume)
	_apply_bus_volume("SFX", sfx_volume)
	_apply_display_settings()


func set_master_volume(value: float) -> void:
	master_volume = _sanitize_volume(value)
	_apply_bus_volume("Master", master_volume)
	save_settings()


func set_music_volume(value: float) -> void:
	music_volume = _sanitize_volume(value)
	_apply_bus_volume("Music", music_volume)
	save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = _sanitize_volume(value)
	_apply_bus_volume("SFX", sfx_volume)
	save_settings()


func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	_apply_display_settings()
	save_settings()


func set_resolution(value: Vector2i) -> void:
	resolution = _sanitize_resolution(value)
	_apply_display_settings()
	save_settings()


func set_vsync(enabled: bool) -> void:
	vsync = enabled
	_apply_vsync()
	save_settings()


func get_master_volume() -> float:
	return master_volume


func get_music_volume() -> float:
	return music_volume


func get_sfx_volume() -> float:
	return sfx_volume


func get_fullscreen() -> bool:
	return fullscreen


func get_resolution() -> Vector2i:
	return resolution


func get_vsync() -> bool:
	return vsync


func get_available_resolutions() -> Array[Vector2i]:
	return AVAILABLE_RESOLUTIONS.duplicate()


func _ensure_audio_buses() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return

	AudioServer.add_bus(AudioServer.bus_count)
	var bus_index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, "Master")


func _apply_bus_volume(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("Audio bus not found: %s" % bus_name)
		return

	var sanitized_value := _sanitize_volume(value)
	if sanitized_value <= 0.0:
		AudioServer.set_bus_mute(bus_index, true)
		AudioServer.set_bus_volume_db(bus_index, MIN_VOLUME_DB)
		return

	AudioServer.set_bus_mute(bus_index, false)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(sanitized_value / 100.0))


func _apply_display_settings() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolution)

	_apply_vsync()


func _apply_vsync() -> void:
	var mode := DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(mode)


func _sanitize_volume(value: float) -> float:
	return clampf(value, 0.0, 100.0)


func _sanitize_resolution(value: Vector2i) -> Vector2i:
	if AVAILABLE_RESOLUTIONS.has(value):
		return value

	return DEFAULT_RESOLUTION
