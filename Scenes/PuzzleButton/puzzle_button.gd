extends Area2D

@export var is_single_use: bool = false
var bodies_on_top: int = 0
signal pressed
signal unpressed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	bodies_on_top += 1
	if body.is_in_group("Pushable") or body is Player:
		if bodies_on_top == 1:
			$AudioStreamPlayer2D.pitch_scale = 1.0
			$AudioStreamPlayer2D.play()
			pressed.emit()
			print("I have been pushed")
			$AnimatedSprite2D.play("pressed")


func _on_body_exited(body: Node2D) -> void:
	if is_single_use:
		return
		
	bodies_on_top -= 1
	if body.is_in_group("Pushable") or body is Player:
		if bodies_on_top == 0:
			$AudioStreamPlayer2D.pitch_scale = 0.8
			$AudioStreamPlayer2D.play()
			unpressed.emit()
			print("I have been unpushed")
			$AnimatedSprite2D.play("unpressed")
