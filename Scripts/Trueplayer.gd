extends CharacterBody2D

const SPEED := 200.0
const JUMP_VELOCITY := -320.0
const IFRAME_DURATION := 1.0
const RESPAWN_DELAY := 3.0   # Seconds before scene reload

var is_attacking := false
var attack_index := 0
var is_hit := false
var is_dead := false
var i_frame_timer := 0.0

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var Hitbox: Area2D = $Hitbox
@onready var hitboxbox: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var Hurtbox: Area2D = $Hurtbox
@onready var death_timer: Timer = Timer.new()

func _ready() -> void:
	# Make sure the player is in the "player" group so enemies can detect it
	add_to_group("player")

	# Connect animation signals
	anim.animation_finished.connect(_on_animation_finished)
	Hurtbox.area_entered.connect(_on_hurtbox_area_entered)

	# Setup death timer for respawn
	death_timer.wait_time = RESPAWN_DELAY
	death_timer.one_shot = true
	death_timer.timeout.connect(_reload_scene)
	add_child(death_timer)

	
	Stats.player_stats["health"] = Stats.player_stats["max_health"]
	print("Player health reset to:", Stats.player_stats["health"])

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if i_frame_timer > 0.0:
		i_frame_timer -= delta

	if is_hit:
		velocity.x = 0
		move_and_slide()
		return

	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("Jump") and is_on_floor() and not is_attacking:
		velocity.y = JUMP_VELOCITY

	# Horizontal movement
	var direction := Input.get_axis("Run_Left", "Run_Right")
	if not is_attacking:
		hitboxbox.disabled = true
		if direction != 0:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	# Flip sprite
	if direction != 0:
		sprite.flip_h = direction < 0

	_update_hit_and_hurtbox_flip()
	move_and_slide()

	# Movement animations
	if not is_attacking and not is_hit:
		if not is_on_floor():
			anim.play("Jump" if velocity.y < 0 else "Fall")
		else:
			anim.play("Idle" if direction == 0 else "Running")

func _process(_delta: float) -> void:
	if is_hit or is_dead:
		return

	if Input.is_action_just_pressed("attack"):
		if not is_attacking:
			is_attacking = true
			attack_index = 1
			velocity.x = 0
			anim.play("Attack1")
		elif attack_index == 1:
			attack_index = 2

func _on_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"Attack1":
			if attack_index == 2:
				anim.play("Attack2")
			else:
				is_attacking = false
				attack_index = 0
		"Attack2":
			is_attacking = false
			attack_index = 0
		"Hit":
			is_hit = false
		"Death":
			# Start respawn timer after death animation
			death_timer.start()

func _update_hit_and_hurtbox_flip() -> void:
	if sprite.flip_h:
		Hitbox.position.x = -38
		Hurtbox.position.x = -8
	else:
		Hitbox.position.x = 8
		Hurtbox.position.x = 8

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hitbox") and i_frame_timer <= 0.0 and not is_dead:
		# Reduce health
		Stats.player_stats["health"] -= Stats.enemy_stats["attack"]
		print("Player HP:", Stats.player_stats["health"])

		# Trigger hit state
		is_hit = true
		is_attacking = false
		anim.play("Hit")
		i_frame_timer = IFRAME_DURATION

		# Player death
		if Stats.player_stats["health"] <= 0:
			is_dead = true
			is_hit = true

			# Disable hitboxes and interactions
			Hitbox.monitoring = false
			Hurtbox.monitoring = false

			# Stop enemies from targeting player
			remove_from_group("player")

			# Play death animation
			anim.play("Death")

func _reload_scene() -> void:
	# Reset health before reloading scene
	Stats.player_stats["health"] = Stats.player_stats["max_health"]
	get_tree().reload_current_scene()
