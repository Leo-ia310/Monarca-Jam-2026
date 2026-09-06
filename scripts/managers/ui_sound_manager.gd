extends Node

const CLICK_SOUND_PATH := "res://assets/audio/mixkit-fast-double-click-on-mouse-275.wav"
const HOVER_SOUND_PATH := "res://assets/audio/mixkit-short-bass-hit-2299.wav"

var _click_player: AudioStreamPlayer
var _hover_player: AudioStreamPlayer
var _connected_buttons: Dictionary = {}


func _ready() -> void:
	_click_player = AudioStreamPlayer.new()
	_click_player.name = "ClickPlayer"
	_click_player.stream = load(CLICK_SOUND_PATH) as AudioStream
	_click_player.bus = _get_sfx_bus_name()
	add_child(_click_player)

	_hover_player = AudioStreamPlayer.new()
	_hover_player.name = "HoverPlayer"
	_hover_player.stream = load(HOVER_SOUND_PATH) as AudioStream
	_hover_player.bus = _get_sfx_bus_name()
	add_child(_hover_player)

	get_tree().node_added.connect(_on_node_added)
	call_deferred("_connect_existing_buttons")


func _connect_existing_buttons() -> void:
	_connect_buttons_in_tree(get_tree().root)


func _connect_buttons_in_tree(node: Node) -> void:
	_try_connect_button(node)
	for child in node.get_children():
		_connect_buttons_in_tree(child)


func _on_node_added(node: Node) -> void:
	_try_connect_button(node)


func _try_connect_button(node: Node) -> void:
	var button := node as Button
	if button == null:
		return

	var button_id := button.get_instance_id()
	if _connected_buttons.has(button_id):
		return

	button.pressed.connect(_on_button_pressed)
	button.mouse_entered.connect(_on_button_hovered)
	_connected_buttons[button_id] = true


func _on_button_pressed() -> void:
	play_click()


func _on_button_hovered() -> void:
	play_hover()


func play_click() -> void:
	if _click_player == null or _click_player.stream == null:
		return

	_click_player.bus = _get_sfx_bus_name()
	_click_player.stop()
	_click_player.play()


func play_hover() -> void:
	if _hover_player == null or _hover_player.stream == null:
		return

	_hover_player.bus = _get_sfx_bus_name()
	_hover_player.stop()
	_hover_player.play()


func _get_sfx_bus_name() -> StringName:
	if AudioServer.get_bus_index("SFX") == -1:
		return &"Master"

	return &"SFX"
