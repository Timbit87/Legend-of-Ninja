extends CharacterBody2D

@export var speed: float = 30
@export var acceleration: float = 5
@export var HP: int = 2
var target: Node2D
var is_dead = false
var detection_area: Area2D

func _ready():
	# Get the detection area node if not already assigned
	detection_area = $PlayerDetectArea2D  # Make sure to set this to the correct Area2D node
	# Initially, make sure it's monitoring the player.
	detection_area.monitoring = true
	
func _physics_process(delta: float) -> void:
	if is_dead:
		return
	chase_target()
	animate_enemy()
	move_and_slide()

	if velocity.length() > 2:
		if $SlimeStepTimer.is_stopped():
			$SlimeStepTimer.start()
	else:
		$SlimeStepTimer.stop()
	
	
		
func chase_target():
	if not is_dead:
		if target:
			var distance_to_payer: Vector2
			distance_to_payer = target.global_position - global_position
		
			var direction_normal: Vector2 = distance_to_payer.normalized()
		
			velocity = velocity.move_toward(direction_normal * speed, acceleration)

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
		
func death():
	is_dead = true
	velocity = Vector2.ZERO
	detection_area.monitoring = false 
	$CollisionShape2D.disabled = true
	$AnimatedSprite2D.play("death")
	$AnimationPlayer.play("death")
	await $AnimatedSprite2D.animation_finished
	queue_free()
	

func _on_player_detect_area_2d_body_entered(body: Node2D) -> void:
	if body is Player and not is_dead:
		target = body


func _on_slime_step_timer_timeout() -> void:
	pass # Replace with function body.
