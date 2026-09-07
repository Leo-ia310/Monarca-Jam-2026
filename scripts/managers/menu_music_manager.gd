extends Node

const MENU_MUSIC_PATH := "res://assets/audio/menu_main_title.wav"

var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "MenuMusicPlayer"
	_player.stream = load(MENU_MUSIC_PATH) as AudioStream
	_enable_music_loop()
	_player.bus = _get_music_bus_name()
	add_child(_player)


func play_menu_music() -> void:
	if _player == null:
		return

	if _player.stream == null:
		_player.stream = load(MENU_MUSIC_PATH) as AudioStream
	_enable_music_loop()
	_player.bus = _get_music_bus_name()
	if not _player.playing:
		_player.play()


func stop_menu_music() -> void:
	if _player != null:
		_player.stop()


func _get_music_bus_name() -> StringName:
	if AudioServer.get_bus_index("Music") != -1:
		return &"Music"
	if AudioServer.get_bus_index("MUSIC") != -1:
		return &"MUSIC"
	return &"Master"


func _enable_music_loop() -> void:
	if _player == null or _player.stream == null:
		return

	if _player.stream is AudioStreamWAV:
		(_player.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
