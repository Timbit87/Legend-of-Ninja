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

func _ready():
	# Get the detection area node if not already assigned
	# Initially, make sure it's monitoring the player.
	detection_area.monitoring = true
	
	detection_area.connect("body_entered", Callable(self, "_on_player_entered"))
	chase_zone_area.connect("body_exited", Callable(self, "_on_chase_zone_area_2d_body_exited"))
	chase_zone_area.connect("body_entered", Callable(self, "_on_chase_zone_area_2d_body_entered"))
	
func _physics_process(delta: float) -> void:
	if is_dead:
		return
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
		var distance_to_player = target.global_position - global_position
		var direction_normal = distance_to_player.normalized()
		velocity = velocity.move_toward(direction_normal * speed, acceleration)
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

func _on_chase_zone_area_2d_body_exited(body: Node2D) -> void:
	if body is Player and not is_dead:
		print("Player exited chase zone")
		is_chasing = false
		target = null



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
		print("Player entered chase zone")
