extends Area2D
@onready var sprite = $AnimatedSprite2D
@export var speed := 240.0

func _ready():
	sprite.play("default")
	await get_tree().create_timer(5.0).timeout
	queue_free()
	
func _physics_process(delta):
	position.y += speed * delta

func _on_body_entered(body):

	if body.has_method("take_damage"):
		body.take_damage(1, global_position)

	queue_free()
