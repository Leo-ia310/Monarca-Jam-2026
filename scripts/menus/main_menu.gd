extends Control

const HEADPHONES_NOTICE_PATH := "res://scenes/menus/headphones_notice.tscn"
const OPTIONS_MENU_PATH := "res://scenes/menus/options_menu.tscn"
const CREDITS_MENU_PATH := "res://scenes/menus/credits_menu.tscn"
const BACKGROUND_FRAME_1 := preload("res://assets/ui/main_menu_background_1.png")
const BACKGROUND_FRAME_2 := preload("res://assets/ui/main_menu_background_2.png")

const BASE_LABELS := ["JUGAR", "OPCIONES", "CRÉDITOS", "SALIR"]
const EXIT_LABELS := ["SÍ", "NO"]
const SELECTED_COLOR := Color(0.72, 0.9, 1.0, 1.0)
const IDLE_COLOR := Color(0.42, 0.56, 0.64, 1.0)
const DISABLED_COLOR := Color(0.25, 0.32, 0.38, 1.0)
const GLITCH_CHARS := "#%&/[]{}01X_"
const GLITCH_COLORS := [
	Color(1.0, 0.18, 0.82, 1.0),
	Color(0.72, 0.22, 1.0, 1.0),
	Color(0.98, 0.45, 0.9, 1.0)
]
const BACKGROUND_FRAME_DURATION := 0.55

@onready var background := $Background as TextureRect
@onready var play_button := $MenuStack/PlayButton as Button
@onready var options_button := $MenuStack/OptionsButton as Button
@onready var credits_button := $MenuStack/CreditsButton as Button
@onready var exit_button := $MenuStack/ExitButton as Button
@onready var exit_confirm := $ExitConfirm as Control
@onready var yes_button := $ExitConfirm/ConfirmStack/YesButton as Button
@onready var no_button := $ExitConfirm/ConfirmStack/NoButton as Button
@onready var title_label := $TitleLabel as Label
@onready var subtitle_label := $SubtitleLabel as Label

var _buttons: Array[Button] = []
var _exit_buttons: Array[Button] = []
var _selected_index := 0
var _exit_selected_index := 1
var _input_locked := false
var _confirming_exit := false
var _rng := RandomNumberGenerator.new()
var _glitching := false
var _background_frame := 0


func _ready() -> void:
	MenuMusicManager.play_menu_music()

	_buttons = [play_button, options_button, credits_button, exit_button]
	_exit_buttons = [yes_button, no_button]

	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	yes_button.pressed.connect(_on_exit_yes_pressed)
	no_button.pressed.connect(_cancel_exit_confirmation)

	_prepare_buttons(_buttons)
	_prepare_buttons(_exit_buttons)
	_connect_hover_focus(_buttons, false)
	_connect_hover_focus(_exit_buttons, true)
	exit_confirm.visible = false
	exit_confirm.modulate.a = 0.0
	_select_main(0, true)
	_start_background_loop()
	_play_entry_animation()
	_start_menu_glitch_loop()


func _start_background_loop() -> void:
	background.texture = BACKGROUND_FRAME_1
	_background_loop()


func _background_loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(BACKGROUND_FRAME_DURATION).timeout
		if not is_inside_tree():
			return
		_background_frame = 1 - _background_frame
		background.texture = BACKGROUND_FRAME_1 if _background_frame == 0 else BACKGROUND_FRAME_2


func _input(event: InputEvent) -> void:
	if _input_locked:
		return

	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return

	var keycode := key_event.keycode
	var physical_keycode := key_event.physical_keycode

	if _confirming_exit:
		match keycode:
			KEY_ESCAPE:
				_cancel_exit_confirmation()
				get_viewport().set_input_as_handled()
			KEY_UP:
				_select_exit(_exit_selected_index - 1, false, true)
				get_viewport().set_input_as_handled()
			KEY_DOWN:
				_select_exit(_exit_selected_index + 1, false, true)
				get_viewport().set_input_as_handled()
			KEY_ENTER, KEY_KP_ENTER:
				_confirm_exit_choice()
				get_viewport().set_input_as_handled()
		if keycode == KEY_W or physical_keycode == KEY_W:
			_select_exit(_exit_selected_index - 1, false, true)
			get_viewport().set_input_as_handled()
		elif keycode == KEY_S or physical_keycode == KEY_S:
			_select_exit(_exit_selected_index + 1, false, true)
			get_viewport().set_input_as_handled()
		return

	match keycode:
		KEY_UP:
			_select_main(_selected_index - 1, false, true)
			get_viewport().set_input_as_handled()
		KEY_DOWN:
			_select_main(_selected_index + 1, false, true)
			get_viewport().set_input_as_handled()
		KEY_ENTER, KEY_KP_ENTER:
			_confirm_main_choice()
			get_viewport().set_input_as_handled()
	if keycode == KEY_W or physical_keycode == KEY_W:
		_select_main(_selected_index - 1, false, true)
		get_viewport().set_input_as_handled()
	elif keycode == KEY_S or physical_keycode == KEY_S:
		_select_main(_selected_index + 1, false, true)
		get_viewport().set_input_as_handled()


func _prepare_buttons(buttons: Array[Button]) -> void:
	for button in buttons:
		button.focus_mode = Control.FOCUS_ALL
		button.flat = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_color_override("font_color", IDLE_COLOR)
		button.add_theme_color_override("font_hover_color", SELECTED_COLOR)
		button.add_theme_color_override("font_focus_color", SELECTED_COLOR)
		button.add_theme_color_override("font_pressed_color", SELECTED_COLOR)
		button.add_theme_color_override("font_disabled_color", DISABLED_COLOR)


func _connect_hover_focus(buttons: Array[Button], is_exit_group: bool) -> void:
	for index in range(buttons.size()):
		var button := buttons[index]
		if is_exit_group:
			button.mouse_entered.connect(_on_exit_button_hovered.bind(index))
			button.focus_entered.connect(_on_exit_button_hovered.bind(index))
		else:
			button.mouse_entered.connect(_on_main_button_hovered.bind(index))
			button.focus_entered.connect(_on_main_button_hovered.bind(index))


func _on_main_button_hovered(index: int) -> void:
	if _input_locked:
		return
	_select_main(index)


func _on_exit_button_hovered(index: int) -> void:
	if _input_locked:
		return
	_select_exit(index)


func _play_entry_animation() -> void:
	for index in range(_buttons.size()):
		var button := _buttons[index]
		button.modulate.a = 0.0
		button.scale = Vector2(0.98, 0.98)
		var tween := create_tween()
		tween.tween_interval(index * 0.06)
		tween.set_parallel(true)
		tween.tween_property(button, "modulate:a", 1.0, 0.14)
		tween.tween_property(button, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _start_menu_glitch_loop() -> void:
	_rng.randomize()
	_glitch_loop()


func _glitch_loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(_rng.randf_range(1.2, 2.8)).timeout
		if is_inside_tree() and not _input_locked:
			await _play_short_text_glitch()


func _play_short_text_glitch() -> void:
	if _glitching:
		return

	_glitching = true
	var visible_buttons := _buttons if not _confirming_exit else _exit_buttons
	var target_count := visible_buttons.size() + 2
	var selected_targets: Array[int] = []
	var selected_count := _rng.randi_range(1, mini(3, target_count))
	while selected_targets.size() < selected_count:
		var target_index := _rng.randi_range(0, target_count - 1)
		if not selected_targets.has(target_index):
			selected_targets.append(target_index)

	var glitch_targets: Array[Dictionary] = []
	var button_labels := BASE_LABELS if not _confirming_exit else EXIT_LABELS
	for target_index in selected_targets:
		if target_index == 0:
			glitch_targets.append({
				"node": title_label,
				"text": title_label.text,
				"modulate": title_label.modulate,
				"label": title_label.text,
				"is_button": false
			})
		elif target_index == 1:
			glitch_targets.append({
				"node": subtitle_label,
				"text": subtitle_label.text,
				"modulate": subtitle_label.modulate,
				"label": subtitle_label.text,
				"is_button": false
			})
		else:
			var button_index := target_index - 2
			var button := visible_buttons[button_index]
			glitch_targets.append({
				"node": button,
				"text": button.text,
				"modulate": button.modulate,
				"label": button_labels[button_index],
				"selected": button_index == (_exit_selected_index if _confirming_exit else _selected_index),
				"is_button": true
			})

	for flicker_index in range(_rng.randi_range(2, 4)):
		if not is_inside_tree():
			break

		for target in glitch_targets:
			var target_node := target["node"] as Control
			var glitch_color: Color = GLITCH_COLORS[_rng.randi_range(0, GLITCH_COLORS.size() - 1)]
			if target["is_button"]:
				var prefix := "> " if target["selected"] else "  "
				(target_node as Button).text = prefix + _glitched_text(target["label"], 2)
			else:
				(target_node as Label).text = _glitched_text(target["label"], 3)
			target_node.modulate = glitch_color

		await get_tree().create_timer(0.035).timeout

	for target in glitch_targets:
		var target_node := target["node"] as Control
		target_node.modulate = target["modulate"]
		if target["is_button"]:
			(target_node as Button).text = target["text"]
		else:
			(target_node as Label).text = target["text"]

	if _confirming_exit:
		_select_exit(_exit_selected_index, true)
	else:
		_select_main(_selected_index, true)
	_glitching = false


func _glitched_text(source_text: String, amount: int) -> String:
	var result := source_text
	var changes := mini(amount, result.length())
	for change_index in range(changes):
		var char_index := _rng.randi_range(0, result.length() - 1)
		if result.substr(char_index, 1) == " ":
			continue
		var glitch_char := GLITCH_CHARS.substr(_rng.randi_range(0, GLITCH_CHARS.length() - 1), 1)
		result = result.substr(0, char_index) + glitch_char + result.substr(char_index + 1)
	return result


func _select_main(index: int, instant: bool = false, play_sound: bool = false) -> void:
	var previous_index := _selected_index
	_selected_index = wrapi(index, 0, _buttons.size())
	for button_index in range(_buttons.size()):
		_apply_button_state(_buttons[button_index], BASE_LABELS[button_index], button_index == _selected_index, instant)
	_buttons[_selected_index].grab_focus()
	if play_sound and previous_index != _selected_index:
		UISoundManager.play_hover()


func _select_exit(index: int, instant: bool = false, play_sound: bool = false) -> void:
	var previous_index := _exit_selected_index
	_exit_selected_index = wrapi(index, 0, _exit_buttons.size())
	for button_index in range(_exit_buttons.size()):
		_apply_button_state(_exit_buttons[button_index], EXIT_LABELS[button_index], button_index == _exit_selected_index, instant)
	_exit_buttons[_exit_selected_index].grab_focus()
	if play_sound and previous_index != _exit_selected_index:
		UISoundManager.play_hover()


func _apply_button_state(button: Button, label: String, selected: bool, instant: bool = false) -> void:
	button.text = ("> " if selected else "  ") + label
	var target_color := SELECTED_COLOR if selected else IDLE_COLOR
	var target_scale := Vector2(1.025, 1.025) if selected else Vector2.ONE
	if instant:
		button.modulate = target_color
		button.scale = target_scale
		return

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "modulate", target_color, 0.12)
	tween.tween_property(button, "scale", target_scale, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _confirm_main_choice() -> void:
	_buttons[_selected_index].pressed.emit()


func _confirm_exit_choice() -> void:
	if _exit_selected_index == 0:
		_on_exit_yes_pressed()
	else:
		_cancel_exit_confirmation()


func _confirm_and_change_scene(path: String) -> void:
	if _input_locked:
		return

	_input_locked = true
	var button := _buttons[_selected_index]
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(0.98, 0.98), 0.08)
	tween.tween_property(button, "scale", Vector2.ONE, 0.08)
	await tween.finished
	get_tree().change_scene_to_file(path)


func _show_exit_confirmation() -> void:
	if _input_locked:
		return

	_confirming_exit = true
	exit_confirm.visible = true
	exit_confirm.modulate.a = 0.0
	_select_exit(1, true)
	var tween := create_tween()
	tween.tween_property(exit_confirm, "modulate:a", 1.0, 0.12)


func _cancel_exit_confirmation() -> void:
	_confirming_exit = false
	var tween := create_tween()
	tween.tween_property(exit_confirm, "modulate:a", 0.0, 0.12)
	await tween.finished
	exit_confirm.visible = false
	_select_main(_selected_index, true)


func _on_play_pressed() -> void:
	_confirm_and_change_scene(HEADPHONES_NOTICE_PATH)


func _on_options_pressed() -> void:
	_confirm_and_change_scene(OPTIONS_MENU_PATH)


func _on_credits_pressed() -> void:
	_confirm_and_change_scene(CREDITS_MENU_PATH)


func _on_exit_pressed() -> void:
	_show_exit_confirmation()


func _on_exit_yes_pressed() -> void:
	if _input_locked:
		return

	_input_locked = true
	var tween := create_tween()
	tween.tween_property(yes_button, "scale", Vector2(0.98, 0.98), 0.08)
	tween.tween_property(yes_button, "scale", Vector2.ONE, 0.08)
	await tween.finished
	get_tree().quit()
