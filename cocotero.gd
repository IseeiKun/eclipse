extends Node2D

@export var speed := 90.0
@export var left_distance := 120.0
@export var right_distance := 120.0

@export var projectile_scene : PackedScene

var start_x := 0.0
var dir := 1

@onready var sprite = $AnimatedSprite2D
@onready var timer_attack = $TimerAttack
@onready var shoot_point = $ShootPoint

func _ready():

	start_x = global_position.x

	sprite.play("default")

	timer_attack.timeout.connect(_on_timer_attack_timeout)

func _process(delta):

	position.x += dir * speed * delta

	if position.x >= start_x + right_distance:
		dir = -1
		sprite.flip_h = true

	elif position.x <= start_x - left_distance:
		dir = 1
		sprite.flip_h = false

func _on_timer_attack_timeout():

	if projectile_scene == null:
		return

	var bullet = projectile_scene.instantiate()
	get_parent().add_child(bullet)

	bullet.global_position = shoot_point.global_position
