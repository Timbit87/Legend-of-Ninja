extends Area2D

var player = Node2D

func _ready():
	if $StealthTimer.is_stopped():
		$SmokePoof.play("poof")
		$SmokePoof.connect("animation_finished", Callable(self, "_on_poof_finished"))
		
	if player != null:
		player.is_stealthed_from_smoke = true
		player.set_stealth_mode(true)
		$StealthTimer.start()
		print("Stealth Timer started")
		SceneManager.stop_all_enemy_chase()
		
		var enemies = get_tree().get_nodes_in_group("Enemies")
		for enemy in enemies:
			enemy.last_known_player_position = player.global_position
			if enemy.has_method("enter_confused"):
				enemy.enter_confused()
	await $SmokePoof.animation_finished




func _on_stealth_timer_timeout() -> void:
	print("Stealth timer ended")
	if player != null:
		player.is_stealthed_from_smoke = false
		player.set_stealth_mode(false)
	queue_free()
