extends CharacterBody2D


@export var HP: int = 4
@export var damage: int = 1
@export var speed: float = 30
@export var acceleration: float = 5
@export var death_particles: PackedScene
@export var sounds: Array[AudioStream] = []

var target: Node2D
var is_dead = false

func take_damage(amount: int = 1, attacker: Node2D = null):
	if is_dead:
		return
	HP -= amount
	if HP <= 0:
		death()
	var flash_red_colour: Color = Color(50, .1, .1)
	var original_colour: Color = Color(1, 1, 1)
	
	for i in range(2):
		modulate = flash_red_colour
		await get_tree().create_timer(0.05).timeout	
		modulate = original_colour
		await get_tree().create_timer(0.05).timeout	

func death():
	is_dead = true
	velocity = Vector2.ZERO
	if death_particles:
		var particles = death_particles.instantiate()
		particles.global_position = global_position
		get_tree().current_scene.add_child(particles)
	queue_free()

func chase_target():
	if target and not is_dead:
		var dir = (target.global_position - global_position).normalized()
		velocity = velocity.move_toward(dir * speed, acceleration)
		
func _physics_process(delta):
	if not is_dead:
		chase_target()
		move_and_slide()
		
func animate_enemy():
	var normal_velocity: Vector2 = velocity.normalized()
	if normal_velocity.x > 0.707:
		$AnimatedSprite2D.play("move_right")
		$SlimeStepPlayer.pitch_scale = 1.5
		$PlayerDetectArea2D.rotation = deg_to_rad(-90)
	elif normal_velocity.x < -0.707:
		$AnimatedSprite2D.play("move_left")
		$SlimeStepPlayer.pitch_scale = 1.5
		$PlayerDetectArea2D.rotation = deg_to_rad(90)
	elif normal_velocity.y > 0.707:
		$AnimatedSprite2D.play("move_down")
		$SlimeStepPlayer.pitch_scale = 1.5
		$PlayerDetectArea2D.rotation = deg_to_rad(0)
	elif normal_velocity.y < -0.707:
		$AnimatedSprite2D.play("move_up")
		$SlimeStepPlayer.pitch_scale = 1.5
		$PlayerDetectArea2D.rotation = deg_to_rad(180)
		
