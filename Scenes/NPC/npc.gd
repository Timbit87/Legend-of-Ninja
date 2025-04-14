extends StaticBody2D

var can_interact: bool = false
@export var dialogue_lines: Array[String] = ["Hello", "there", "Anakin"]
@export var dialogue_index: int = 0

func _ready() -> void:
	print(dialogue_lines[0])
	print(dialogue_lines[2])
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Interact") and can_interact:
		$AudioStreamPlayer2D.play()
		if dialogue_index < dialogue_lines.size():
			$CanvasLayer.visible = true
			get_tree().paused = true
		
			$CanvasLayer/DialogueLabel.text = dialogue_lines[dialogue_index]
			dialogue_index += 1
		else:
			$CanvasLayer.visible = false
			dialogue_index = 0
			get_tree().paused = false
		
