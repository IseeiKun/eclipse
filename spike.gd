

extends CharacterBody2D
signal died
@export var max_hp := 20
@export var speed := 70.0
@export var attack_range := 60.0

var hp := 20
var player = null

var dead := false
var invulnerable := false
var can_move := true

var phase := 1
var state := "idle"

var facing := 1
var music_started := false
var attack_offset := 28.0
@export var reward_npc: Node2D
@onready var sprite = $AnimatedSprite2D
@onready var hitbox = $AttackArea
@onready var detect = $DetectionArea
@onready var timer_attack = $TimerAttack
@onready var timer_invuln = $TimerInvuln
@onready var timer_stun = $TimerStun
@onready var timer_stuncd = $TimerStunCD
@onready var music = $AudioStreamPlayer
@onready var hp_text = $LifeText

func _ready():
	if reward_npc:
		reward_npc.visible = false
	hp = max_hp

	hitbox.monitoring = false
	hitbox.scale.x = 1
	attack_offset = abs(hitbox.position.x)

	detect.monitoring = true
	detect.monitorable = true

	timer_attack.timeout.connect(_on_attack_timer)
	timer_invuln.timeout.connect(_on_invuln_end)
	timer_stun.timeout.connect(_on_stun_end)
	timer_stuncd.timeout.connect(_on_stuncd_end)

	sprite.animation_finished.connect(_on_animation_finished)

	update_hp_text()
	hp_text.visible = true

func _physics_process(_delta):

	if dead:
		return

	if hp <= max_hp / 2.0:
		phase = 2

	if state == "stun":
		sprite.play("stun")
		move_and_slide()
		return

	if state == "attack":
		move_and_slide()
		return

	if player == null:
		sprite.play("idle")
		velocity.x = 0
		move_and_slide()
		return

	if can_move:

		var dir = sign(player.global_position.x - global_position.x)

		if dir != 0:
			facing = dir

		sprite.flip_h = facing > 0
		hitbox.position.x = attack_offset * facing

		var dist = abs(player.global_position.x - global_position.x)

		if dist > attack_range:
			velocity.x = facing * speed
			sprite.play("idle")
		else:
			velocity.x = 0

	move_and_slide()

# ==================================================
# DETECCIÓN
# ==================================================
func _on_detection_area_body_entered(body):

	if body.name == "Player":

		player = body
		timer_attack.start()

		if !music_started:
			music_started = true

			if music:
				music.play()

func _on_detection_area_body_exited(body):

	if body == player:
		player = null
		timer_attack.stop()

# ==================================================
# ATAQUE
# ==================================================
func _on_attack_timer():

	if dead or player == null:
		return

	if state == "stun":
		return

	var dist = abs(player.global_position.x - global_position.x)

	if dist > attack_range:
		return

	state = "attack"
	can_move = false
	velocity.x = 0

	if phase == 1:
		sprite.play("jab")
	else:
		if randi() % 2 == 0:
			sprite.play("jab")
		else:
			sprite.play("combo")

	enable_hitbox()

	await get_tree().create_timer(0.45).timeout

	disable_hitbox()

func enable_hitbox():
	hitbox.monitoring = true

func disable_hitbox():
	hitbox.monitoring = false

func _on_attack_area_body_entered(body):

	if dead:
		return

	if body == self:
		return

	if body.has_method("take_damage"):
		body.take_damage(1, global_position)

# ==================================================
# DAÑO
# ==================================================
func take_damage(amount, _attacker_pos):

	if dead or invulnerable:
		return

	hp -= amount
	update_hp_text()

	if hp <= 0:
		die()
		return

	state = "damage"
	invulnerable = true
	can_move = false

	sprite.play("damage")

	timer_invuln.start()

func apply_stun():

	if dead:
		return

	state = "stun"
	can_move = false
	velocity.x = 0
	sprite.play("stun")

	timer_stun.start()
	timer_stuncd.start()

# ==================================================
# MUERTE + VOLVER AL MENU
# ==================================================
func die():

	if dead:
		return

	dead = true
	velocity = Vector2.ZERO
	hitbox.monitoring = false
	timer_attack.stop()

	died.emit()

	sprite.play("dead")

	if hp_text:
		hp_text.text = "YOU WIN!"
# ==================================================
# ANIMACIONES
# ==================================================
func _on_animation_finished():

	if sprite.animation == "jab":
		state = "idle"
		can_move = true
		disable_hitbox()

	if sprite.animation == "combo":
		state = "idle"
		can_move = true
		disable_hitbox()

	if sprite.animation == "damage":
		state = "idle"
		can_move = true

	if sprite.animation == "dead":
		await get_tree().create_timer(2.0).timeout
	
		if reward_npc:
			reward_npc.visible = true
			reward_npc.start_dialogue()

func _on_invuln_end():
	invulnerable = false

func _on_stun_end():
	state = "idle"

func _on_stuncd_end():
	can_move = true

# ==================================================
# TEXTO VIDA
# ==================================================
func update_hp_text():

	if hp_text:
		hp_text.text = "Spike HP: " + str(hp)

func _on_timer_attack_timeout(): pass
func _on_timer_invuln_timeout(): pass
func _on_timer_stun_timeout(): pass
func _on_timer_stun_cd_timeout(): pass
func _on_animated_sprite_2d_animation_finished(): pass
