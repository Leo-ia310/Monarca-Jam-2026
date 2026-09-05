extends Control

signal advance_requested

@export var character_name: String = ""
@export_multiline var dialogue_text: String = ""

@onready var character_name_label: Label = %CharacterNameLabel
@onready var dialogue_text_label: RichTextLabel = %DialogueTextLabel
@onready var continue_indicator: Label = %ContinueIndicator


func _ready() -> void:
	set_dialogue(character_name, dialogue_text)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_accept"):
		advance_requested.emit()


func set_dialogue(new_character_name: String, new_dialogue_text: String) -> void:
	character_name = new_character_name
	dialogue_text = new_dialogue_text

	if not is_node_ready():
		return

	character_name_label.text = character_name
	dialogue_text_label.text = dialogue_text


func set_continue_visible(is_visible: bool) -> void:
	if is_node_ready():
		continue_indicator.visible = is_visible
