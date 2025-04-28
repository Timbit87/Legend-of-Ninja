extends Area2D

var throw_direction = Vector2.RIGHT
var throw_speed = 100

func _ready() -> void:
	$Sprite2D.rotation = throw_direction.angle()

func _physics_process(delta):
	if not $KunaiTimeoutTimer.is_stopped():
		return
	position += throw_direction.normalized() * throw_speed * delta
	$AudioStreamPlayer2D.play()


func _on_body_entered(body: Node2D) -> void:
	queue_free()


func _on_kunai_timeout_timer_timeout() -> void:
	pass # Replace with function body.
