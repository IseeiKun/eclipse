

extends CharacterBody2D
signal died
@export var speed := 180.0
@export var jump_force := -280.0
@export var gravity := 900.0
@export var hp := 4

var player = null
var state = "idle"

var invulnerable = false
var can_be_stunned = true
var dead = false

var attacking_jump := false
var saw_player := false

@onready var sprite = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var hitbox = $Hitbox

@onready var timer_attack = $TimerAttack
@onready var timer_invuln = $TimerInvuln
@onready var timer_stun = $TimerStun
@onready var timer_stuncd = $TimerStunCD

func _ready():

	timer_attack.timeout.connect(_on_attack_timer)
	timer_invuln.timeout.connect(_on_invuln_end)
	timer_stun.timeout.connect(_on_stun_end)
	timer_stuncd.timeout.connect(_on_stuncd_end)

	sprite.animation_finished.connect(_on_animation_finished)

# =================================================
# PHYSICS
# =================================================
func _physics_process(delta):

	if dead:
		return

	velocity.y += gravity * delta

	# Si aterrizó luego de atacar
	if attacking_jump and is_on_floor() and velocity.y >= 0:
		attacking_jump = false
		velocity.x = 0
		state = "idle"

	match state:

		"idle":
			velocity.x = 0

			if sprite.animation != "idle":
				sprite.play("idle")

		"alert":
			velocity.x = 0

			if sprite.animation != "alert":
				sprite.play("alert")

		"attack":

			if !is_on_floor():

				if velocity.y < 0:
					if sprite.animation != "attack":
						sprite.play("attack")
				else:
					if sprite.animation != "caida":
						sprite.play("caida")

		"damage":

			if sprite.animation != "damage":
				sprite.play("damage")

		"stun":

			velocity.x = 0

			if sprite.animation != "stun":
				sprite.play("stun")

	move_and_slide()

# =================================================
# DETECTAR JUGADOR
# =================================================
func _on_detection_area_body_entered(body):

	if body.name == "Player":

		player = body

		if !saw_player:
			saw_player = true
			state = "alert"
			sprite.play("alert")
		else:
			timer_attack.start()

func _on_detection_area_body_exited(body):

	if body == player:
		player = null
		state = "idle"

# =================================================
# ATAQUE
# =================================================
func _on_attack_timer():

	if dead:
		return

	if player != null and state != "damage" and state != "stun":

		state = "attack"
		attacking_jump = true

		var diff = player.global_position.x - global_position.x
		var dir = sign(diff)

		# Si están muy pegados, usa dirección visual actual
		if dir == 0:
			dir = -1 if sprite.flip_h else 1

		velocity.x = dir * speed
		velocity.y = jump_force

		sprite.flip_h = dir < 0

	timer_attack.start()

# =================================================
# HACER DAÑO AL JUGADOR
# =================================================
func _on_hitbox_body_entered(body):

	if dead:
		return

	if body.has_method("take_damage"):
		body.take_damage(1, global_position)

# =================================================
# RECIBIR DAÑO
# =================================================
func take_damage(amount, attacker_pos):

	if dead or invulnerable:
		return

	hp -= amount

	if hp <= 0:
		die()
		return

	state = "damage"
	invulnerable = true

	var dir = sign(global_position.x - attacker_pos.x)

	velocity.x = dir * 180
	velocity.y = -120

	timer_invuln.start()

# =================================================
# STUN
# =================================================
func apply_stun():

	if dead:
		return

	if !can_be_stunned:
		return

	state = "stun"

	can_be_stunned = false
	velocity.x = 0

	timer_stun.start()
	timer_stuncd.start()


# =================================================
# MUERTE
# =================================================
func die():

	if dead:
		return
	dead = true
	state = "dead"

	velocity = Vector2.ZERO
	died.emit()

	sprite.play("dead")

# =================================================
# FIN ANIMACIONES
# =================================================

func _on_animation_finished():

	if sprite.animation == "dead":
		queue_free()

	if sprite.animation == "alert":
		state = "idle"
		timer_attack.start()

# =================================================
# TIMERS
# =================================================
func _on_invuln_end():

	invulnerable = false

	if state == "damage":
		state = "idle"

func _on_stun_end():

	if state == "stun":
		state = "idle"

func _on_stuncd_end():

	can_be_stunned = true
