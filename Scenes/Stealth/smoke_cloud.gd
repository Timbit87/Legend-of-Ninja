extends Area2D

var player = Node2D

func _ready():
	if $StealthTimer.is_stopped():
		$SmokePoof.play("poof")
		$SmokePoof.connect("animation_finished", Callable(self, "_on_poof_finished"))
		$StealthTimer.start()
		if is_instance_valid(player):
			$RefreshTimer.start()
		if is_instance_valid(player):
			player.activate_smoke_stealth($StealthTimer)		

func _on_refresh_timer_timeout() -> void:
	pass # Replace with function body.
	
func _on_poof_finished(anim_name):
	if anim_name == "poof":
		queue_free()

func _on_stealth_timer_timeout() -> void:
	$RefreshTimer.start()
