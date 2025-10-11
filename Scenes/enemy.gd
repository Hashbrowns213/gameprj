extends CharacterBody2D

@export var SPEED := 100.0
@export var GRAVITY := 600.0
@export var DETECTION_RANGE := 150.0
@export var ATTACK_RANGE := 40.0
@export var TURN_COOLDOWN := 0.4  # delay before turning again

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var wall_check: RayCast2D = $Wall
@onready var floor_check: RayCast2D = $Floor

var player: CharacterBody2D = null
var direction := -1  # start moving left
var is_attacking := false
var turn_timer := 0.0

func _ready() -> void:
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	if not anim.animation_finished.is_connected(_on_animation_finished):
		anim.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Handle turn cooldown
	if turn_timer > 0:
		turn_timer -= delta

	# Attack lock
	if is_attacking:
		velocity.x = 0
		move_and_slide()
		return

	if player:
		# Player detected - chase or attack
		var distance = global_position.distance_to(player.global_position)
		direction = sign(player.global_position.x - global_position.x)
		anim.flip_h = direction < 0

		if distance > ATTACK_RANGE:
			velocity.x = direction * SPEED
			anim.play("move")
		else:
			velocity.x = 0
			anim.play("light")
			is_attacking = true
	else:
		# PATROLLING BEHAVIOR
		anim.play("move")
		velocity.x = direction * SPEED

		# Flip direction if about to walk off a ledge or hit a wall
		if turn_timer <= 0 and (wall_check.is_colliding() or not floor_check.is_colliding()):
			_flip_direction()

	move_and_slide()

func _flip_direction() -> void:
	direction *= -1
	anim.flip_h = direction < 0
	turn_timer = TURN_COOLDOWN  # prevent instant re-flip

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player = body
		print("Player detected")

func _on_body_exited(body: Node) -> void:
	if body == player:
		player = null
		print("Player lost")

func _on_animation_finished() -> void:
	if anim.animation == "light":
		is_attacking = false
