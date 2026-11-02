

extends Area2D
@onready var sprite = $AnimatedSprite2D
@export var speed := 150.0
@export var damage := 1

var direction := 1

func _ready():
	sprite.play("default")
	# Autodestruir en 5 segundos
	await get_tree().create_timer(5.0).timeout

	if is_inside_tree():
		queue_free()

func _physics_process(delta):

	position.x += direction * speed * delta

# ==================================================
# GOLPEA CUERPOS
# ==================================================
func _on_body_entered(body):

	if body.has_method("take_damage"):
		body.take_damage(damage, global_position)

	queue_free()

# ==================================================
# SI HAY OTRA AREA CONECTADA
# ==================================================
func _on_area_2d_body_entered(body: Node2D) -> void:

	if body.has_method("take_damage"):
		body.take_damage(damage, global_position)

	queue_free()
