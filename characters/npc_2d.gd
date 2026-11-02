extends Node2D

@export var dialogue_resource: DialogueResource

func _ready() -> void:
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func start_dialogue() -> void:
	DialogueManager.show_dialogue_balloon(dialogue_resource, "start")

func _on_dialogue_ended(resource: DialogueResource) -> void:
	if resource != dialogue_resource:
		return
	
	GameManager.load_next_scenario()
