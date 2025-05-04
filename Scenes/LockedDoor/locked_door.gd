extends StaticBody2D

@export var buttons_needed: int = 1

var buttons_pressed: int = 0
signal opened_door

func _on_puzzle_button_pressed() -> void:
	buttons_pressed += 1
	print(buttons_pressed)
	if buttons_pressed >= buttons_needed:
		visible = false
		$CollisionShape2D.set_deferred("disabled", true)
		SceneManager.state["door_open_overworld"] = true
		SceneManager.state["button_pressed_overworld"] = true
		opened_door.emit()


func _on_puzzle_button_unpressed() -> void:
	buttons_pressed -= 1
	
	if buttons_pressed < buttons_needed:
		visible = true
		$CollisionShape2D.set_deferred("disabled", false)
