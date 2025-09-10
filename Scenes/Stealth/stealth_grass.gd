extends Area2D

@onready var grass_timer: Timer = $GrassTimer


func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	
func _on_body_entered(body):
	if body.is_in_group("player"):
		body.is_stealthed_from_grass = true
		grass_timer.start()
		body.stealth_counter += 1
		body.set_stealth_mode(true)
		
func _on_body_exited(body):
	grass_timer.stop()
	if body.is_in_group("player"):
		body.is_stealthed_from_grass = false
		body.stealth_counter = max(0, body.stealth_counter - 1)
		if body.stealth_counter == 0:
			body.set_stealth_mode(false)


func _on_grass_timer_timeout() -> void:
	var enemies = get_tree().get_nodes_in_group("Enemies")
	for enemy in enemies:
		if enemy.is_chasing:
			enemy.lose_player()
