extends Area2D


func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	
func _on_body_entered(body):
	print("Something entered grass")
	if body.is_in_group("player"):
		body.stealth_counter += 1
		print("Player entered grass")
		body.set_stealth_mode(true)
		
func _on_body_exited(body):
	if body.is_in_group("player"):
		body.stealth_counter = max(0, body.stealth_counter - 1)
		if body.stealth_counter == 0:
			print("Player left grass")
			body.set_stealth_mode(false)
