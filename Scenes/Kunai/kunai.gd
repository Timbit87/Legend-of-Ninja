class_name Kunai
extends Area2D

var throw_direction = Vector2.RIGHT
var throw_speed = 100
@export var damage := 1
@export var knockback_force := 10
var thrower: Node2D

func _ready() -> void:
	$Sprite2D.rotation = throw_direction.angle()
	$AudioStreamPlayer2D.play()
	$KunaiTimeoutTimer.start() # Make sure it starts moving immediately!

func _physics_process(delta):
	# Move every frame normally
	position += throw_direction.normalized() * throw_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and "velocity" in body:
		var distance_to_enemy: Vector2 = body.global_position - global_position
		var knockback_direction: Vector2 = distance_to_enemy.normalized()
		var knockback_strength: float = 75
		
		body.velocity += knockback_direction * knockback_strength
		body.take_damage(damage, thrower)
	elif body.has_method("hit_by_kunai"):
		body.hit_by_kunai()
	$Sprite2D.visible = false
	$CollisionShape2D.set_deferred("disabled", true)
	$GPUParticles2D.emitting = true
	$KunaiDestructionPlayer.play()
	await get_tree().create_timer(1.0).timeout
	queue_free() # Destroy self immediately on *any* hit

func _on_kunai_timeout_timer_timeout() -> void:
	queue_free() # Self-destruct after timer ends
