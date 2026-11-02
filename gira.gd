

extends CharacterBody2D

@export var hp := 3
@export var projectile_scene : PackedScene

var player = null
var state := "idle"

var dead := false
var invulnerable := false
var can_be_stunned := true

# --------------------------------------------------
# NODOS
# --------------------------------------------------
@onready var sprite = $AnimatedSprite2D

@onready var shoot_left = $ShootPointLeft
@onready var shoot_right = $ShootPointRight

@onready var explosion = $ExplosionArea
@onready var detection_area = $DetectionArea

@onready var timer_attack = $TimerAttack
@onready var timer_invuln = $TimerInvuln
@onready var timer_stun = $TimerStun
@onready var timer_stuncd = $TimerStunCD

func _ready():

	sprite.animation_finished.connect(_on_animation_finished)

	timer_attack.timeout.connect(_on_attack_timer)
	timer_invuln.timeout.connect(_on_invuln_end)
	timer_stun.timeout.connect(_on_stun_end)
	timer_stuncd.timeout.connect(_on_stuncd_end)

	explosion.monitoring = false

# ==================================================
# PHYSICS
# ==================================================
func _physics_process(_delta):

	if dead:
		return

	match state:

		"idle":
			if sprite.animation != "idle":
				sprite.play("idle")

		"attack":
			if sprite.animation != "attack":
				sprite.play("attack")

		"damage":
			if sprite.animation != "damage":
				sprite.play("damage")

		"stun":
			if sprite.animation != "stun":
				sprite.play("stun")

# ==================================================
# DETECTAR JUGADOR
# ==================================================
func _on_detection_area_body_entered(body):

	if body.name == "Player":

		player = body

		if timer_attack.is_stopped():
			timer_attack.start()

func _on_detection_area_body_exited(body):

	if body == player:

		player = null
		timer_attack.stop()
		state = "idle"

# ==================================================
# DISPARO
# ==================================================
func _on_attack_timer():

	if dead:
		return

	if player == null:
		return

	if state == "stun":
		return

	state = "attack"

	if projectile_scene == null:
		return

	var bullet = projectile_scene.instantiate()
	get_parent().add_child(bullet)

	var dir = sign(player.global_position.x - global_position.x)

	if dir == 0:
		dir = 1

	if dir < 0:
		bullet.global_position = shoot_left.global_position
	else:
		bullet.global_position = shoot_right.global_position

	bullet.direction = dir

	sprite.flip_h = dir < 0

# ==================================================
# RECIBIR DAÑO
# ==================================================
func take_damage(amount, _attacker_pos):

	if dead or invulnerable:
		return

	hp -= amount

	if hp <= 0:
		die()
		return

	state = "damage"
	invulnerable = true

	timer_invuln.start()

# ==================================================
# STUN
# ==================================================
func apply_stun():

	if dead:
		return

	if !can_be_stunned:
		return

	state = "stun"
	can_be_stunned = false

	timer_stun.start()
	timer_stuncd.start()

# ==================================================
# MORIR
# ==================================================
func die():

	dead = true
	state = "dead"

	timer_attack.stop()

	sprite.play("dead")

	explosion.monitoring = true

# ==================================================
# EXPLOSIÓN FINAL
# ==================================================
func _on_explosion_area_body_entered(body):

	if dead:

		if body.has_method("take_damage"):
			body.take_damage(1, global_position)

# ==================================================
# FIN ANIMACIONES
# ==================================================
func _on_animation_finished():

	if sprite.animation == "dead":
		queue_free()

	if sprite.animation == "attack":
		state = "idle"

# ==================================================
# TIMERS
# ==================================================
func _on_invuln_end():

	invulnerable = false

	if state == "damage":
		state = "idle"

func _on_stun_end():

	if state == "stun":
		state = "idle"

func _on_stuncd_end():

	can_be_stunned = true

func _on_timer_attack_timeout() -> void:
	pass

func _on_timer_invuln_timeout() -> void:
	pass

func _on_timer_stun_timeout() -> void:
	pass

func _on_timer_stun_cd_timeout() -> void:
	pass
