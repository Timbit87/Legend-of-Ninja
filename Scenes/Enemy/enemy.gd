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
@onready var confusion_icon = $ConfusionIcon

var target: Node2D
var is_dead = false
var spawn_position: Vector2
var returning_to_spawn := false
var stealth_timer = 0.0
var close_detection_radius := 24.0
var is_chasing = false
var look_direction: Vector2 = Vector2.RIGHT
var is_searching = false
var confused_timer = 0.0
var search_timer = 0.0
var last_known_player_position: Vector2
var is_wandering = true


func _ready() -> void:
	spawn_position = global_position
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0
	start_wandering()
	
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
		var direction = (spawn_position - global_position).normalized()
		velocity = direction * return_speed
		
		if global_position.distance_to(spawn_position) < 4:
			returning_to_spawn = false
			velocity = Vector2.ZERO
	elif is_searching:
		update_searching(delta)
		
	else:
		update_detection(delta)
		if is_chasing:
			chase_target()
		elif is_wandering:
			pass
		else:
			velocity = Vector2.ZERO
	move_and_slide()
	animate_enemy()
	
		
func animate_enemy():
	var normal_velocity: Vector2 = velocity.normalized()
	if normal_velocity == Vector2.ZERO:
		return
	if normal_velocity.x > 0.707:
		$AnimatedSprite2D.play("move_right")
		set_look_direction(Vector2.RIGHT)
		play_step_sounds()
	elif normal_velocity.x < -0.707:
		$AnimatedSprite2D.play("move_left")
		set_look_direction(Vector2.LEFT)
		play_step_sounds()
	elif normal_velocity.y > 0.707:
		$AnimatedSprite2D.play("move_down")
		set_look_direction(Vector2.DOWN)
		play_step_sounds()
	elif normal_velocity.y < -0.707:
		$AnimatedSprite2D.play("move_up")
		set_look_direction(Vector2.UP)
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
		if distance_to_player < close_detection_radius:
			detect_player()
		else:
			if is_chasing:
				stealth_timer += delta
				if stealth_timer >= 2:
					last_known_player_position = target.global_position
					enter_confused()
			return
	else:
		stealth_timer = 0.0	
		
func enter_confused():
	confusion_icon.visible = true
	is_wandering = false
	is_chasing = false
	confused_timer = 2.0
	is_searching = true
	search_timer = 0.0
	velocity = Vector2.ZERO
	$RandomMovementTimer.start(randf_range(2.0, 5.0))
	
func update_searching(delta):
	if confused_timer > 0:
		confused_timer -= delta
		velocity = Vector2.ZERO
		if confused_timer <= 0:
			search_timer = randf_range(3.0,5.0)
			confusion_icon = false
		return
		
	if search_timer > 0:
		search_timer -= delta
		
		if not nav_agent.is_navigation_finished() and velocity != Vector2.ZERO:
			velocity = get_move_velocity()
		else:
			var random_offset = Vector2(randf_range(-64, 64), randf_range(-64, 64))
			nav_agent.set_target_position(last_known_player_position + random_offset)
			velocity = get_move_velocity()
			
		if search_timer <= 0:
			is_searching = false
			return_to_spawn()
	else:
		is_searching = false
		return_to_spawn()

func detect_player():
	if target:
		is_wandering = false
		is_chasing = true
		return
	var player = get_tree().get_first_node_in_group("player")
	if player:
		target = player
		is_chasing = true
		
func lose_player():
	is_chasing = false
	target = null

func return_to_spawn():
	is_wandering = false
	returning_to_spawn = true

func _on_player_detect_area_2d_body_entered(body: Node2D) -> void:
	if body is Player and not is_dead:
		if body.is_stealthed:
			var distance_to_player = global_position.distance_to(body.global_position)
			if distance_to_player < close_detection_radius:
				detect_player()
		else:
			detect_player()
			
func set_look_direction(dir: Vector2):
	if dir != Vector2.ZERO:
		look_direction = dir.normalized()
		
func get_facing_direction() -> Vector2:
	return look_direction

func start_wandering():
	if is_dead or is_searching or returning_to_spawn:
		return
	is_wandering = true
	var random_dir = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()
	velocity = random_dir * speed * 0.5
	$RandomMovementTimer.wait_time = randf_range(2.0, 5.0)
	$RandomMovementTimer.start()

func end_search():
	is_searching = false
	returning_to_spawn = true
	return_to_spawn()
	
func _on_random_movement_timer_timeout() -> void:
	start_wandering()
