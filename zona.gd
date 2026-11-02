extends Node2D

var enemies_alive: int = 0

@onready var enemies_container = $Enemies
@onready var exit_blocker = $ExitBlocker
@export var next_zone: Node2D

func _ready() -> void:
	
	for enemy in enemies_container.get_children():
		register_enemy(enemy)



	if enemies_alive == 0:
		unlock_exit()
		


func activate_zone() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	set_physics_process(true)
	set_process(true)

func register_enemy(enemy: Node) -> void:
	enemies_alive += 1

	enemy.died.connect(_on_enemy_died)
	

func _on_enemy_died() -> void:
	enemies_alive -= 1
	print("enemies_alive") 
	if enemies_alive <= 0:
		print("todos los enemigos estan muertos")
		unlock_exit()


func unlock_exit() -> void:
	exit_blocker.get_node("CollisionShape2D").set_deferred("disabled", true)




func _on_exit_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if next_zone == null:
			push_warning("Esta zona no tiene una siguiente zona asignada.")
			return

		next_zone.activate_zone()

		var spawn = next_zone.get_node("PlayerSpawn")
		body.global_position = spawn.global_position
