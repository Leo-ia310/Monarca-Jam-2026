extends "res://scripts/game/final_a_loop.gd"

const B_OFFICE_SCENE_PATH := "res://scenes/game/final_b_office.tscn"

var _returning_to_office := false

const B_ROUTINE_STEPS := [
	{
		"backgrounds": ["res://assets/ui/bedroom_background.png", "res://assets/ui/bedroom_ciclo2_background.png", "res://assets/ui/bedroom_ciclo3_background.png"],
		"sound": "alarm",
		"speaker": "???",
		"emotion": "scared",
		"text": "¡Tengo que levantarme!, no puedo estar aquí o allá o donde sea que estoy, el mundo el entorno, lo que sea"
	},
	{
		"backgrounds": ["res://assets/ui/bedroom_background.png", "res://assets/ui/bedroom_ciclo2_background.png", "res://assets/ui/bedroom_ciclo3_background.png"],
		"speaker": "Narrador",
		"text": "La habitación no parece ser lo que es o lo que dejó de ser."
	},
	{
		"backgrounds": ["res://assets/ui/bathroom_background.png"],
		"foregrounds": ["res://assets/ui/bathroom_character.png", "res://assets/ui/bathroom_character_fragment.png", "res://assets/ui/bathroom_character_ciclo3_fragment.png"],
		"sound": "water",
		"speaker": "???",
		"emotion": "scared",
		"text": "Yo, soy… no pero es que no tiene sentido, piensa\nyo soy… ¿cuál era mi nombre?, vamos no puedes olvidar algo tan básico …\nNO, no puede ser, yo soy, yo soy … por favor tienes que recordar algo."
	},
	{
		"backgrounds": ["res://assets/ui/bathroom_background.png"],
		"foregrounds": ["res://assets/ui/bathroom_character.png", "res://assets/ui/bathroom_character_fragment.png", "res://assets/ui/bathroom_character_ciclo3_fragment.png"],
		"speaker": "Narrador",
		"text": "No queda ninguna gota de lo que es o de lo que dejo de ser o quizas nunca lo fue."
	},
	{
		"backgrounds": ["res://assets/ui/breakfast_background.png", "res://assets/ui/desayuno_ciclo2_heart_1.png", "res://assets/ui/desayuno_ciclo3_background.png"],
		"sound": "coffee",
		"speaker": "???",
		"emotion": "scared",
		"text": "Pero… yo… soy ¿que se supone que soy? Que se supone que hago …, yo tan siquiera debería existir"
	},
	{
		"backgrounds": ["res://assets/ui/breakfast_background.png", "res://assets/ui/desayuno_ciclo2_heart_1.png", "res://assets/ui/desayuno_ciclo3_background.png"],
		"speaker": "Narrador",
		"text": "El es, Ella es, nosotros somos …"
	},
	{
		"backgrounds": ["res://assets/ui/exit_background.png", "res://assets/ui/exit_ciclo2_door_open.png", "res://assets/ui/exit_ciclo3_door_open.png"],
		"sound": "door",
		"speaker": "???",
		"emotion": "sad",
		"text": "… no se a donde tengo que ir, ¿tengo que ir algun lugar?"
	},
	{
		"backgrounds": ["res://assets/ui/exit_background.png", "res://assets/ui/exit_ciclo2_door_open.png", "res://assets/ui/exit_ciclo3_door_open.png"],
		"speaker": "Narrador",
		"text": "Se fue"
	}
]


func _get_routine_steps() -> Array:
	return B_ROUTINE_STEPS


func _get_office_scene_path() -> String:
	return B_OFFICE_SCENE_PATH


func _get_return_dialogue() -> Array:
	return [{
		"speaker": "???",
		"emotion": "scared",
		"text": "Vamos tienes que buscar algo completamente tuyo, debe de existir algo tuyo. recuerda, recuerda, recuerda, recuerda, recuerda, recuerda, recuerda."
	}]


func _get_return_visual_step() -> Dictionary:
	return {
		"backgrounds": ["res://assets/ui/bedroom_background.png", "res://assets/ui/bedroom_ciclo2_background.png", "res://assets/ui/bedroom_ciclo3_background.png"]
	}


func _get_return_office_path() -> String:
	return B_OFFICE_SCENE_PATH


func _confirm_yes() -> void:
	if _glitch_running:
		return
	_no_attempts += 1
	_play_no_glitch_audio()
	await _play_no_glitch_burst()
	if not is_inside_tree() or _state != FlowState.CHOICE:
		return
	choice_panel.visible = true
	_update_choice_view()


func _play_no_glitch() -> void:
	if _glitch_running:
		return
	# NO cancela la salida y deja al jugador en la cama de la escena 1.
	_dialogue_visual_token += 1
	_state = FlowState.ROUTINE_DIALOGUE
	choice_panel.visible = false
	dialogue_box.visible = false
	_apply_visual_step({"background": "res://assets/ui/bedroom_background.png"})


func _on_dialogue_line_started() -> void:
	if _returning_to_office:
		_dialogue_visual_token += 1
		var return_visual_step := _get_return_visual_step()
		_apply_visual_step(return_visual_step)
		_start_dialogue_visual_cycle(return_visual_step)
		return
	super._on_dialogue_line_started()


func _show_office_prompt() -> void:
	if _returning_to_office:
		_returning_to_office = false
		_dialogue_visual_token += 1
		fade_rect.visible = true
		fade_rect.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(fade_rect, "modulate:a", 1.0, 0.55)
		await tween.finished
		get_tree().change_scene_to_file(_get_return_office_path())
		return
	super._show_office_prompt()
