extends Control

@onready var question_system := $QuestionSystem as Control
@onready var finished_label := $FinishedLabel as Label


func _ready() -> void:
	finished_label.hide()
	question_system.questionnaire_finished.connect(_on_questionnaire_finished)
	question_system.start_questions([
		{
			"id": "q1",
			"question": "¿Consideras que una inteligencia artificial puede cometer errores?",
			"type": "choice",
			"options": ["Sí", "No", "Depende"]
		},
		{
			"id": "q2",
			"question": "Si alguien comete un error, ¿qué debería hacerse?",
			"type": "text",
			"min_words": 1,
			"max_words": 8
		},
		{
			"id": "q3",
			"question": "¿Confías en mí?",
			"type": "text",
			"min_words": 1,
			"max_words": 3
		}
	])


func _on_questionnaire_finished(responses: Array) -> void:
	finished_label.show()
	print("RESPUESTAS REGISTRADAS")
	for response in responses:
		print("%s: %s" % [response.get("question_id", ""), response.get("answer", "")])
