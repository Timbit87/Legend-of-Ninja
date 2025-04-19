extends Node2D


func _ready():
	if SceneManager.state.get("button_pressed_overworld", false):
		$PuzzleButton.get_node("AnimatedSprite2D").play("pressed")
		$LockedDoor.buttons_pressed = $LockedDoor.buttons_needed
		$PuzzleButton/CollisionShape2D.disabled = true
	if SceneManager.state.get("door_open_overworld", false):
		$LockedDoor.visible = false
		$LockedDoor.get_node("CollisionShape2D").set_deferred("disabled", true)
