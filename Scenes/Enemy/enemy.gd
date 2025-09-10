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
@onready var confused_timer = $ConfusedTimer
@onready var confusion_icon: Label = $ConfusionIcon

var target: Node2D
var is_dead = false
var spawn_position: Vector2
var returning_to_spawn := false
var stealth_timer = 0.0
var close_detection_radius := 24.0
var is_chasing = false
var look_direction: Vector2 = Vector2.RIGHT
var is_searching = false
var search_timer = 0.0
var last_known_player_position: Vector2
var is_wandering = true
var is_confused = false


func _ready() -> void:
	add_to_group("Enemies")
	spawn_position = global_position
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0

	if confusion_icon == null:
		push_error("ConfusionIcon missing in " + str(self.name))
	else:
		confusion_icon.visible = false
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
	if target.is_stealthed_from_smoke:
		if is_chasing:
			print("Smoke bomb confusion")
			last_known_player_position = target.global_position
			enter_confused()
		return
	elif target.is_stealthed_from_grass:
		if is_chasing:
			stealth_timer += delta
			print("Stealth timer engaged", stealth_timer)
			if stealth_timer >= 2.0:
				print("Grass stealthed triggered")
				last_known_player_position = target.global_position
				enter_confused()
		return
	else:
		stealth_timer = 0.0

func enter_confused():
	print("entered confused")
	is_wandering = false
	is_chasing = false
	is_searching = true
	velocity = Vector2.ZERO
	if confusion_icon:
		confusion_icon.visible = true
	else:
		print("No confusion Icon on:", name)
	start_confused_wandering()
	confused_timer.start(2.0)
	
func update_searching(delta):
	pass

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
	is_chasing = false
	is_searching = false
	returning_to_spawn = true
	$RandomMovementTimer.stop()

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
	
func start_confused_wandering():
	if is_dead or is_searching or returning_to_spawn:
		return
	is_confused = true
	var random_dir = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()
	velocity = random_dir * speed * 0.3
	
	
func end_search():
	print("Search ended")
	is_searching = false
	is_wandering = false
	is_confused = false
	return_to_spawn()
	
func _on_random_movement_timer_timeout() -> void:
	start_wandering()


func _on_confused_timer_timeout() -> void:
	confusion_icon.visible = false
	is_searching = true
	is_wandering = false
	$SearchTimer.start(randf_range(3.0, 5.0))
	print("Confused timer start")

func _on_search_timer_timeout() -> void:
	end_search()
	print("Timer timed out")
