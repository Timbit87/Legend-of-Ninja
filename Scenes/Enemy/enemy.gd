extends CharacterBody2D


@export var HP: int = 4
@export var damage: int = 1
@export var speed: float = 30
@export var acceleration: float = 5
@export var return_speed := 60.0
@export var death_particles: PackedScene
@export var step_sounds: Array[AudioStream] = []

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var step_player: AudioStreamPlayer2D = $StepPlayer2D
@onready var particles = $BloodParticles
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var target: Node2D
var is_dead = false
var spawn_position: Vector2
var returning_to_spawn := false
var stealth_timer = 0.0
var close_detection_radius = 32.0
var is_chasing = false


func _ready() -> void:
	spawn_position = global_position
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0
	
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
	if target and not returning_to_spawn:
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
	
func get_direction_to_target():
	if target:
		return(target.global_position - global_position).normalized()
	return Vector2.ZERO
		
func _physics_process(delta):
	if is_dead:
		return
		
	if returning_to_spawn:
		if nav_agent.is_navigation_finished():
			returning_to_spawn = false
			velocity = Vector2.ZERO
		else:
			nav_agent.set_target_position(nav_agent.target_position)
			var next_position = nav_agent.get_next_path_position()
			var direction = (next_position - global_position).normalized()
			velocity = direction * return_speed
	else:
		update_detection(delta)
		chase_target()
	move_and_slide()
	animate_enemy()
	
		
func animate_enemy():
	var normal_velocity: Vector2 = velocity.normalized()
	if normal_velocity.x > 0.707:
		$AnimatedSprite2D.play("move_right")
		play_step_sounds()
	elif normal_velocity.x < -0.707:
		$AnimatedSprite2D.play("move_left")
		play_step_sounds()
	elif normal_velocity.y > 0.707:
		$AnimatedSprite2D.play("move_down")
		play_step_sounds()
	elif normal_velocity.y < -0.707:
		$AnimatedSprite2D.play("move_up")
		play_step_sounds()
		

func emit_blood_splatter():
	var particles = $BloodParticles
	if !particles:
		return
	if particles.process_material == null:
		particles.process_material = ParticleProcessMaterial.new()

	var material = particles.process_material as ParticleProcessMaterial
	if material != null:
		var angle = deg_to_rad(randf_range(0, 360))
		material.direction = Vector3(cos(angle), sin(angle), 0)
	particles.restart()

func play_step_sounds():
	if step_sounds.size() == 0:
		return
	if not step_player.playing:
		var random_step_sound = step_sounds[randi() % step_sounds.size()]
		step_player.stream = random_step_sound
		step_player.pitch_scale = randf_range(0.9, 1.2)
		step_player.play()

func get_move_velocity() -> Vector2:
	var next_path_position = nav_agent.get_next_path_position()
	var direction = (next_path_position - global_position).normalized()
	return direction * return_speed
	
func update_detection(delta):
	if not target:
		return
		
	var distance_to_player = global_position.distance_to(target.global_position)
	
	if target.is_stealthed:
		stealth_timer = 0.0
		if distance_to_player < close_detection_radius:
			detect_player()
		else:
			if is_chasing:
				stealth_timer += delta
				if stealth_timer >= 2:
					lose_player()
			return
	else:
		stealth_timer = 0.0
		


func detect_player():
	if target:
		is_chasing = true
		return
	var player = get_tree().get_first_node_in_group("player")
	if player:
		target = player
		is_chasing = true
		
func lose_player():
	is_chasing = false
	target = null
	returning_to_spawn = true
	nav_agent.set_target_position(spawn_position)
