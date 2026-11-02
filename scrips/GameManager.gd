extends Node

var difficulty := "normal"

func set_easy():
	difficulty = "easy"
	print("Dificultad elegida: FÁCIL")

func set_hard():
	difficulty = "hard"
	print("Dificultad elegida: DIFÍCIL")

func load_next_scenario():
	if difficulty == "easy":
		get_tree().change_scene_to_file("res://zonas/scenario_easy.tscn")
	elif difficulty == "hard":
		get_tree().change_scene_to_file("res://zonas/scenario_hard.tscn")
