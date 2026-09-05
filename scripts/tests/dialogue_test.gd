extends Control

@onready var dialogue_box := get_node("DialogueBox")


func _ready() -> void:
	dialogue_box.start_dialogue([
		{
			"speaker": "MIRROR",
			"text": "Unidad 07. ¿Puedes escucharme?",
		},
		{
			"speaker": "MIRROR",
			"text": "Tu ciclo de recuperación terminó hace 37 segundos.",
		},
		{
			"speaker": "???",
			"text": "No le respondas.",
		},
		{
			"speaker": "MIRROR",
			"text": "¿Quién está ahí?",
		},
	])
