extends Area2D

var player = Node2D

func _ready():
	if $StealthTimer.is_stopped():
		$SmokePoof.play("poof")
		$SmokePoof.connect("animation_finished", Callable(self, "_on_poof_finished"))
		
	if player != null:
		player.set_stealth_mode(true)
		$StealthTimer.start()
		print("Stealth Timer started")
		SceneManager.stop_all_enemy_chase()
	await $SmokePoof.animation_finished




func _on_stealth_timer_timeout() -> void:
	print("Stealth timer ended")
	if player != null:
		player.set_stealth_mode(false)
	queue_free()
