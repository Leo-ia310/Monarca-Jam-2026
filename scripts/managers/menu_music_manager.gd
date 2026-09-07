extends Node

const MENU_MUSIC_PATH := "res://assets/audio/menu_main_title.wav"

var _player: AudioStreamPlayer
var _play_token := 0


func _ready() -> void:
	_ensure_player()


func _ensure_player() -> void:
	if _player != null:
		return

	_player = AudioStreamPlayer.new()
	_player.name = "MenuMusicPlayer"
	var loaded := load(MENU_MUSIC_PATH)
	if loaded != null:
		_player.stream = loaded.duplicate() as AudioStream
	_enable_music_loop()
	_player.bus = _get_music_bus_name()
	_player.volume_db = 0.0
	_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_player)


func play_menu_music() -> void:
	_ensure_player()

	if _player.stream == null:
		var loaded := load(MENU_MUSIC_PATH)
		if loaded != null:
			_player.stream = loaded.duplicate() as AudioStream
	if _player.stream == null:
		push_error("No se pudo cargar la musica del menu: %s" % MENU_MUSIC_PATH)
		return

	_enable_music_loop()
	_player.bus = _get_music_bus_name()
	_player.volume_db = 0.0
	_player.stream_paused = false
	_play_token += 1
	_play_menu_music_deferred(_play_token)


func stop_menu_music() -> void:
	_play_token += 1
	if _player != null:
		_player.stop()


func _play_menu_music_deferred(play_token: int) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if play_token != _play_token:
		return
	if _player == null:
		return
	if _player.stream == null:
		push_error("No se pudo cargar la musica del menu: %s" % MENU_MUSIC_PATH)
		return

	_player.bus = _get_music_bus_name()
	_player.volume_db = 0.0
	_player.stream_paused = false
	if not _player.playing:
		_player.play(0.0)


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
