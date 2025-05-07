extends CharacterBody2D


@export var HP: int = 4
@export var damage: int = 1
@export var speed: float = 30
@export var acceleration: float = 5
@export var return_speed := 60.0
@export var death_particles: PackedScene
@export var sounds: Array[AudioStream] = []

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var step_sound_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var particles = $BloodParticles

var target: Node2D
var is_dead = false
var spawn_position: Vector2
var returning_to_spawn := false


func _ready() -> void:
	spawn_position = global_position
	
	
func return_to_spawn(delta) -> void:
	if returning_to_spawn:
		var distance_to_spawn = spawn_position - global_position
		if distance_to_spawn.length() < 4:
			global_position = spawn_position
			velocity = Vector2.ZERO
			returning_to_spawn = false
		else:
			var direction = distance_to_spawn.normalized()
			velocity = direction * return_speed
	
	
	
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
	if returning_to_spawn:
		return_to_spawn(delta)
	if not is_dead:
		chase_target()
		animate_enemy()
	move_and_slide()
		
func animate_enemy():
	var normal_velocity: Vector2 = velocity.normalized()
	if normal_velocity.x > 0.707:
		$AnimatedSprite2D.play("move_right")
	elif normal_velocity.x < -0.707:
		$AnimatedSprite2D.play("move_left")
	elif normal_velocity.y > 0.707:
		$AnimatedSprite2D.play("move_down")
	elif normal_velocity.y < -0.707:
		$AnimatedSprite2D.play("move_up")

func emit_blood_splatter():
	var particles = $BloodParticles
	if !particles:
		return
	if particles.process_material == null:
		particles.process_material = ParticleProcessMaterial.new()

	var material = particles.process_material as ParticleProcessMaterial
	if material != null:
		material.direction = randf_range(-45, 45)
	particles.restart()
