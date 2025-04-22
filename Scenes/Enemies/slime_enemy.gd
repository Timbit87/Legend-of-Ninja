extends CharacterBody2D

@export var speed: float = 30
@export var acceleration: float = 5
@export var HP: int = 2
var target: Node2D
var is_dead = false
var is_timer_playing := false
var chase_zone: Area2D
var is_chasing = false
@export var slime_sounds: Array = []
@onready var detection_area: Area2D = $PlayerDetectArea2D
@onready var chase_zone_area: Area2D = $ChaseZoneArea2D
var random_movement
var random_movement_direction = 1
var is_ideling = true
var steps_remaining = 0
@export var step_duration := 0.2
@export var step_distance := 10

func _ready():
	randomize()
	$StepTimer.timeout.connect(_on_step_timer_timeout)
	detection_area.monitoring = true
	detection_area.connect("body_entered", Callable(self, "_on_player_entered"))
	chase_zone_area.connect("body_exited", Callable(self, "_on_chase_zone_area_2d_body_exited"))
	chase_zone_area.connect("body_entered", Callable(self, "_on_chase_zone_area_2d_body_entered"))

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_ideling:
		chase_target()
	animate_enemy()
	move_and_slide()

	if velocity.length() > 2:
		if not is_timer_playing:
			$SlimeStepTimer.start()
			is_timer_playing = true
	else:
		$SlimeStepTimer.stop()
		is_timer_playing = false
	
		
func chase_target():
	if is_chasing and target:
		is_ideling = false
		var distance_to_player = target.global_position - global_position
		var direction_normal = distance_to_player.normalized()
		velocity = velocity.move_toward(direction_normal * speed, acceleration)
	elif is_ideling:
		pass
	else:
		velocity = Vector2.ZERO

func animate_enemy():
	var normal_velocity: Vector2 = velocity.normalized()
	if normal_velocity.x > 0.707:
		$AnimatedSprite2D.play("move_right")
		$SlimeStepPlayer.pitch_scale = 1.5
	elif normal_velocity.x < -0.707:
		$AnimatedSprite2D.play("move_left")
		$SlimeStepPlayer.pitch_scale = 1.5
	elif normal_velocity.y > 0.707:
		$AnimatedSprite2D.play("move_down")
		$SlimeStepPlayer.pitch_scale = 1.5
	elif normal_velocity.y < -0.707:
		$AnimatedSprite2D.play("move_up")
		$SlimeStepPlayer.pitch_scale = 1.5
	else:
		$AnimatedSprite2D.play("idle")
		
func death():
	is_dead = true
	velocity = Vector2.ZERO
	detection_area.monitoring = false 
	$CollisionShape2D.disabled = true
	$GPUParticles2D.emitting = true
	$SlimeStepPlayer.stop()
	$SlimeDeathPlayer.play()
	$AnimatedSprite2D.visible = false
	
func take_damage():
	HP -= 1
	if HP <= 0:
		death()
	var flash_red_colour: Color = Color(50, .1, .1)
	var original_colour: Color = Color(1, 1, 1)
	
	for i in range(2):
		modulate = flash_red_colour
		await get_tree().create_timer(0.05).timeout	
		modulate = original_colour
		await get_tree().create_timer(0.05).timeout	
	
	

	play_damage_sfx()		
	
	
func _on_player_detect_area_2d_body_entered(body: Node2D) -> void:
	if body is Player and not is_dead:
		target = body
		is_chasing = true
		is_ideling = false
		$StepTimer.stop()
		velocity = Vector2.ZERO

func _on_chase_zone_area_2d_body_exited(body: Node2D) -> void:
	if body is Player and not is_dead:
		is_chasing = false
		target = null
		is_ideling = true
		steps_remaining = randi() % 3 + 1
		random_movement_direction = Vector2(
		[-1, 0, 1].pick_random(),
		[-1, 0, 1].pick_random()
		).normalized()
		$StepTimer.start(step_duration)
		$RandomMovementTimer.wait_time = randf_range(1.0, 5.0)
		$RandomMovementTimer.start()


func _on_slime_step_timer_timeout() -> void:
	if is_dead == true:	
		$SlimeStepPlayer.stop()
	else:
		if !$SlimeStepPlayer.playing:
			var random_sound = slime_sounds[randi() % slime_sounds.size()]
			$SlimeStepPlayer.stream = random_sound
			$SlimeStepPlayer.pitch_scale = randf_range(0.8, 1.2)
			$SlimeStepPlayer.play()

func play_damage_sfx():
	$DamageSFX.play()
	


func _on_chase_zone_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		pass

func _on_random_movement_timer_timeout() -> void:
	var min_time = 1.0
	var max_time = 5.0
	if not is_chasing:
		is_ideling = true
		steps_remaining = randi() % 4
		random_movement_direction = Vector2(
		[-1, 0, 1].pick_random(),
		[-1, 0, 1].pick_random()
		).normalized()
		$StepTimer.start(step_duration) 
	$RandomMovementTimer.wait_time = randf_range(min_time, max_time)
	$RandomMovementTimer.start()

func _on_step_timer_timeout() -> void:
	if steps_remaining > 0 and not is_chasing:
		velocity = random_movement_direction * step_distance
		move_and_slide()
		steps_remaining -= 1
		$StepTimer.start(step_duration) 
	else:
		velocity = Vector2.ZERO
