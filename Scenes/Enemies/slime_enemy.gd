extends "res://Scenes/Enemy/enemy.gd"


@export var step_duration := 0.2
@export var step_distance := 10
@export var slime_sounds: Array = []

var is_timer_playing := false
var is_ideling = true
var random_movement_direction = Vector2.ZERO
var steps_remaining = 0

@onready var detection_area: Area2D = $PlayerDetectArea2D
@onready var chase_zone_area: Area2D = $ChaseZoneArea2D
@onready var slime_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var slime_step_player: AudioStreamPlayer2D = $SlimeStepPlayer


func _ready():
	super._ready()
	randomize()
	$StepTimer.timeout.connect(_on_step_timer_timeout)
	detection_area.monitoring = true
	detection_area.connect("body_entered", Callable(self, "_on_player_detect_area_2d_body_entered"))
	chase_zone_area.connect("body_exited", Callable(self, "_on_chase_zone_area_2d_body_exited"))
	chase_zone_area.connect("body_entered", Callable(self, "_on_chase_zone_area_2d_body_entered"))
	
func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	# Slime-specific footstep logic
	if velocity.length() > 2:
		if not is_timer_playing:
			$SlimeStepTimer.start()
			is_timer_playing = true
	elif is_timer_playing:
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
	super.animate_enemy()
	var normal_velocity: Vector2 = velocity.normalized()
	if normal_velocity.x > 0.707:
		$PlayerDetectArea2D.rotation = deg_to_rad(-90)
	elif normal_velocity.x < -0.707:
		$PlayerDetectArea2D.rotation = deg_to_rad(90)
	elif normal_velocity.y > 0.707:
		$PlayerDetectArea2D.rotation = deg_to_rad(0)
	elif normal_velocity.y < -0.707:
		$PlayerDetectArea2D.rotation = deg_to_rad(180)
	
	$SlimeStepPlayer.pitch_scale = 1.5
	
func death():
	is_dead = true
	set_process(false)
	set_physics_process(false)
	
	detection_area.monitoring = false 
	$CollisionShape2D.disabled = true
	$GPUParticles2D.emitting = true
	$PlayerDetectArea2D.monitoring = false
	$AnimatedSprite2D.visible = false
	
	$SlimeStepPlayer.stop()
	$SlimeDeathPlayer.play()
	$GPUParticles2D.emitting = true
	
	await get_tree().create_timer(1.0).timeout
	queue_free()
	
func take_damage(amount: int = 1, attacker: Node2D = null):
	emit_blood_splatter()
	super(amount, attacker)
	if attacker != null:
		target = attacker
		is_chasing = true
		is_ideling = false
	play_damage_sfx()

func play_damage_sfx():
	$DamageSFX.play()	
	
	
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
		returning_to_spawn = true
		start_random_movement()


func _on_slime_step_timer_timeout() -> void:
	if is_dead == true:	
		$SlimeStepPlayer.stop()
	else:
		if !$SlimeStepPlayer.playing:
			var random_sound = slime_sounds[randi() % slime_sounds.size()]
			$SlimeStepPlayer.stream = random_sound
			$SlimeStepPlayer.pitch_scale = randf_range(0.8, 1.2)
			$SlimeStepPlayer.play()

func _on_random_movement_timer_timeout() -> void:
	var min_time = 1.0
	var max_time = 5.0
	if not is_chasing:
		start_random_movement()

func _on_step_timer_timeout() -> void:
	if steps_remaining > 0 and not is_chasing:
		velocity = random_movement_direction * step_distance
		steps_remaining -= 1
		$StepTimer.start(step_duration) 
	else:
		velocity = Vector2.ZERO
		
func start_random_movement():
	is_ideling = true
	steps_remaining = randi() % 4 + 1
	random_movement_direction = Vector2(
		[-1, 0, 1].pick_random(),
		[-1, 0, 1].pick_random()
	).normalized()
	$StepTimer.start(step_duration)
	$RandomMovementTimer.wait_time = randf_range(1.0, 5.0)
	$RandomMovementTimer.start()
