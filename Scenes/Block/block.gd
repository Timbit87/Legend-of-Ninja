extends RigidBody2D

@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
var can_play_sound := true

func play_scrape_sound():
	if not can_play_sound:
		return
	can_play_sound = false
	audio_player.pitch_scale = randf_range(0.9, 1.1)
	audio_player.play()
	await get_tree().create_timer(1).timeout
	can_play_sound = true
