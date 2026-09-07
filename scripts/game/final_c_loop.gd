extends "res://scripts/game/final_b_loop.gd"

const C_OFFICE_SCENE_PATH := "res://scenes/game/final_c_office.tscn"

const C_ROUTINE_STEPS := [
	{
		"backgrounds": ["res://assets/ui/bedroom_background.png", "res://assets/ui/bedroom_ciclo2_background.png", "res://assets/ui/bedroom_ciclo3_background.png"],
		"sound": "alarm", "speaker": "???", "emotion": "scared",
		"text": "Esto no está bien, esto no puede estar bien, todo esto, no puede ser real"
	},
	{
		"backgrounds": ["res://assets/ui/bedroom_background.png", "res://assets/ui/bedroom_ciclo2_background.png", "res://assets/ui/bedroom_ciclo3_background.png"],
		"speaker": "Narrador",
		"text": "Todo se siente frío, como si el ambiente cambiara, pero realmente se logra sentir la rutina no es la misma y la mentira se asoma a salir"
	},
	{
		"backgrounds": ["res://assets/ui/bathroom_background.png"],
		"foregrounds": ["res://assets/ui/bathroom_character.png", "res://assets/ui/bathroom_character_fragment.png", "res://assets/ui/bathroom_character_ciclo3_fragment.png"],
		"sound": "water", "speaker": "???", "emotion": "happy",
		"text": "Tienes que mantenerte firme, tu sabes quien eres y lo que representas, nunca debes dudar, no importa qué o quien altere lo que hay. SOLO TIENES QUE SER TÚ."
	},
	{
		"backgrounds": ["res://assets/ui/bathroom_background.png"],
		"foregrounds": ["res://assets/ui/bathroom_character.png", "res://assets/ui/bathroom_character_fragment.png", "res://assets/ui/bathroom_character_ciclo3_fragment.png"],
		"speaker": "Narrador",
		"text": "La claridad es cegadora cuando revela aquello que no estamos preparados para aceptar.\nPor eso la mentira más dulce no necesita engañar; basta con mostrarnos aquello que anhelamos más.\nNos envuelve lentamente, como un sueño del que no queremos despertar, envuelve, envuelve y no parará"
	},
	{
		"backgrounds": ["res://assets/ui/breakfast_background.png", "res://assets/ui/desayuno_ciclo2_heart_1.png", "res://assets/ui/desayuno_ciclo3_background.png"],
		"sound": "coffee", "speaker": "???", "emotion": "scared",
		"text": "Es momento de seguir lo que yo deseo, lo que yo pienso, lo que yo anhelo. No importa lo que esté pasando; llegaré hasta el fondo de toda esta basura, hasta descubrir por qué todo es tan absurdamente carente de sentido.\nYo no estoy mal. Ellos son los que están equivocados."
	},
	{
		"backgrounds": ["res://assets/ui/breakfast_background.png", "res://assets/ui/desayuno_ciclo2_heart_1.png", "res://assets/ui/desayuno_ciclo3_background.png"],
		"speaker": "Narrador", "text": "…"
	},
	{
		"backgrounds": ["res://assets/ui/exit_background.png", "res://assets/ui/exit_ciclo2_door_open.png", "res://assets/ui/exit_ciclo3_door_open.png"],
		"sound": "door", "speaker": "???", "emotion": "scared",
		"text": "Que pase lo que tenga que pasar, pero no ire a ningun lado"
	}
]


func _get_routine_steps() -> Array:
	return C_ROUTINE_STEPS


func _get_office_scene_path() -> String:
	return C_OFFICE_SCENE_PATH


func _get_return_dialogue() -> Array:
	return [
		{"speaker": "???", "emotion": "scared", "text": "Ven, se que me escuchas seas lo que seas no tengo miedo, te exigo que me saques en donde sea que esté esto no puede ser real, es un absurdo total"},
		{"speaker": "IA", "text": "No se supone que digas o hagas eso"},
		{"speaker": "???", "emotion": "scared", "text": "Tienes que salir de donde estés, maldito, ¿qué me has hecho?"},
		{"speaker": "IA", "text": "Esto no se puede determinar si es un éxito o no"}
	]


func _get_return_visual_step() -> Dictionary:
	return {"backgrounds": ["res://assets/ui/bedroom_background.png", "res://assets/ui/bedroom_ciclo2_background.png", "res://assets/ui/bedroom_ciclo3_background.png"]}


func _get_return_office_path() -> String:
	return C_OFFICE_SCENE_PATH
