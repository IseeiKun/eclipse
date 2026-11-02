extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("dead"):
		body.die()
	elif body.has_method("take_damage"):
		body.take_damage(999, global_position)
	else:
		body.queue_free()
