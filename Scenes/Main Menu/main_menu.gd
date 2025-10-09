extends Control

func _ready():
	$VBoxContainer/NewGameLabel.pressed.connect(_on_start_pressed)
	$VBoxContainer/LoadGameLabel.pressed.connect(_on_load_pressed)
	$VBoxContainer/QuitLabel.pressed.connect(_on_quit_pressed)
	
func _on_start_pressed():
	get_tree().change_scene_to_file("res://Scenes/GameScene/game_scene.tscn")
	
func _on_load_pressed():
	print("Load game not implemented")
	
func _on_quit_pressed():
	get_tree().quit()
