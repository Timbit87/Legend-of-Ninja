extends Area2D

var throw_direction = Vector2.RIGHT
var throw_speed = 200

func _physics_process(delta):
	position += throw_direction.normalized() * throw_speed * delta
	$AudioStreamPlayer2D.play()


func _on_body_entered(body: Node2D) -> void:
	queue_free()
