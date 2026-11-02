

extends CharacterBody2D

@export var speed := 220.0
@export var acceleration := 900.0
@export var friction := 1000.0

@export var jump_force := -420.0
@export var gravity := 950.0
@export var fall_gravity := 1300.0
@export var max_jumps := 2

var jumps_left := 2

# --------------------
# VIDA
# --------------------
@export var hp := 5
var invulnerable := false
var facing := 1
var dead := false

# --------------------
# DASH
# --------------------
@export var dash_speed := 550.0
@export var dash_duration := 0.18

var is_dashing := false
var dash_timer := 0.0
var can_dash := true
var dash_direction := 1

# --------------------
# ATAQUE
# --------------------
@export var attack_time := 0.22
var is_attacking := false
var attack_timer := 0.0

# --------------------
# DAÑO RECIBIDO
# --------------------
var is_hurt := false

# --------------------
# NODOS
# --------------------
@onready var animated_sprite = $AnimatedSprite2D
@onready var attack_area = $AttackArea
@onready var stomp_area = $StompArea
@onready var hurt_timer = $HurtTimer

@export var attack_offset := 22.0

func _ready():
	add_to_group("player")
	animated_sprite.animation_finished.connect(_on_animation_finished)

	attack_area.monitoring = false
	stomp_area.monitoring = true

	
	# El área no necesita reflejarse.
	attack_area.scale = Vector2.ONE
	
	update_attack_direction()
# ==================================================
# PHYSICS
# ==================================================
func _physics_process(delta):

	if dead:
		return

	# ===============================
	# GOLPEADO
	# ===============================
	if is_hurt:

		if !is_on_floor():
			velocity.y += gravity * delta

		move_and_slide()
		update_animation()
		return

	# ===============================
	# ATAQUE
	# ===============================
	if is_attacking:

		attack_timer -= delta
		velocity.x = 0

		if !is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0

		if attack_timer <= 0:
			is_attacking = false
			attack_area.monitoring = false

		move_and_slide()
		update_animation()
		return

	# ===============================
	# DASH
	# ===============================
	if is_dashing:

		dash_timer -= delta
		velocity.x = dash_direction * dash_speed
		velocity.y = 0

		if dash_timer <= 0:
			is_dashing = false

		move_and_slide()
		update_animation()
		return

	# ===============================
	# GRAVEDAD
	# ===============================
	if !is_on_floor():

		if velocity.y < 0:
			velocity.y += gravity * delta
		else:
			velocity.y += fall_gravity * delta
	else:
		jumps_left = max_jumps
		can_dash = true

	# ===============================
	# MOVIMIENTO
	# ===============================
	var direction = Input.get_axis("Movimiento_Izquierda", "Movimiento_derecha")

	if direction != 0:

		velocity.x = move_toward(
			velocity.x,
			direction * speed,
			acceleration * delta
		)

		facing = int(sign(direction))
		dash_direction = facing

		animated_sprite.flip_h = facing < 0

		update_attack_direction()

	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	# ===============================
	# SALTO
	# ===============================
	if Input.is_action_just_pressed("Salto"):

		if is_on_floor():
			velocity.y = jump_force

		elif jumps_left > 1:
			velocity.y = jump_force
			jumps_left -= 1

	# ===============================
	# DASH
	# ===============================
	if Input.is_action_just_pressed("Dash") and can_dash:
		start_dash()

	# ===============================
	# ATAQUE
	# ===============================
	if Input.is_action_just_pressed("Ataque"):
		start_attack()

	move_and_slide()
	update_animation()

# ==================================================
# ATAQUE
# ==================================================
func update_attack_direction():

	attack_area.scale = Vector2.ONE
	attack_area.position.x = attack_offset * facing

func start_attack():

	if is_attacking or is_dashing or is_hurt or dead:
		return

	is_attacking = true
	attack_timer = attack_time

	attack_area.monitoring = true

	animated_sprite.play("Atack")

# ==================================================
# DASH
# ==================================================
func start_dash():

	if is_attacking or is_hurt or dead:
		return

	is_dashing = true
	can_dash = false
	dash_timer = dash_duration

# ==================================================
# HACER DAÑO
# ==================================================
func _on_attack_area_body_entered(body):

	if body.has_method("take_damage"):
		body.take_damage(1, global_position)

# ==================================================
# STUN AL CAER ENCIMA
# ==================================================
func _on_stomp_area_body_entered(body):

	if body.has_method("apply_stun"):

		if velocity.y > 0:
			body.apply_stun()
			velocity.y = jump_force * 0.8

# ==================================================
# RECIBIR DAÑO
# ==================================================
func take_damage(amount, enemy_pos):

	if invulnerable or dead:
		return

	hp -= amount
	print("Vida:", hp)

	if hp <= 0:
		die()
		return
	
	invulnerable = true
	is_hurt = true

	is_attacking = false
	is_dashing = false

	attack_area.monitoring = false

	var dir = sign(global_position.x - enemy_pos.x)

	velocity.x = dir * 160
	velocity.y = -220

	hurt_timer.start()

# ==================================================
# MORIR
# ==================================================
func die():

	if dead:
		return

	dead = true
	invulnerable = true
	is_hurt = false
	is_attacking = false
	is_dashing = false

	velocity = Vector2.ZERO

	attack_area.monitoring = false
	stomp_area.monitoring = false

	animated_sprite.play("Dead")

	await animated_sprite.animation_finished

	get_tree().reload_current_scene()

# ==================================================
# TIMER FIN GOLPE
# ==================================================
func _on_hurt_timer_timeout():

	if dead:
		return

	invulnerable = false
	is_hurt = false

# ==================================================
# ANIMACIONES
# ==================================================
func update_animation():

	if dead:
		return

	if is_hurt:
		animated_sprite.play("Damage")
		return

	if is_attacking:
		if animated_sprite.animation != "Atack":
			animated_sprite.play("Atack")
		return

	if is_dashing:
		if animated_sprite.animation != "Dash":
			animated_sprite.play("Dash")
		return

	if !is_on_floor():
		if velocity.y < 0:
			animated_sprite.play("Jump")
		else:
			animated_sprite.play("Caida")
		return

	if abs(velocity.x) > 5:
		animated_sprite.play("Run")
	else:
		animated_sprite.play("Idle")

# ==================================================
# FIN ANIMACIÓN
# ==================================================
func _on_animation_finished():

	if animated_sprite.animation == "Atack":
		is_attacking = false
		attack_area.monitoring = false
