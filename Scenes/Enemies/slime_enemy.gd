extends CharacterBody2D

@export var speed: float = 30
@export var acceleration: float = 5
@export var HP: int = 2
var target: Node2D
var is_dead = false

func _physics_process(delta: float) -> void:
	chase_target()
	animate_enemy()
	move_and_slide()

	
	
		
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
	$AnimatedSprite2D.play("death")
	$AnimationPlayer.play("death")
	await $AnimatedSprite2D.animation_finished
	queue_free()
	

func _on_player_detect_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		target = body
