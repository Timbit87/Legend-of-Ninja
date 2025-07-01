extends Area2D

@onready var raycast = $RayCast2D
@onready var beam_sprite = $AnimatedBeam
@onready var explosion_sprite = $AnimatedExplosion
@onready var explosion_area = $ExplosionArea
@onready var zap_sound = $ZapSound
@onready var explosion_sound = $ExplosionSound
@onready var timer = $Timer

var damage = 10
var lifespan = 0.3
var target_position: Vector2

func _ready() -> void:
	print("Beam getting ready")
	var dir = (target_position - global_position).normalized()
	raycast.target_position = dir * 500
	raycast.force_raycast_update()
	
	beam_sprite.play("beam_loop")
	zap_sound.play()
	
	if raycast.is_colliding():
		var hit_position = raycast.get_collision_point()
		print("hit position", hit_position)
		var hit_object = raycast.get_collider()
		print("hit object", hit_object)
		
		explosion_sprite.global_position = hit_position
		explosion_area.global_position = hit_position
		explosion_sound.global_position = hit_position
		print("Explosion point set to: ", hit_position)
		explosion_sprite.show
		explosion_sprite.play("explode")
		explosion_area.monitoring = true
		explosion_sound.play()
		print("Explosion hit location: ", hit_position)
		
		if hit_object:
			print("Hit object: ", hit_object.name)
			if hit_object and hit_object.has_method("take_damage"):
				hit_object.take_damage(damage)
				print("damage applied to: ", hit_object.name)
			else:
				print("Hit object does not take damage")
		else:
			print("Raycast didnt hit an object")
		
		update_beam_visual(hit_position)
	else:
		print("No collision")
		update_beam_visual(global_position + raycast.target_position)
	
	timer.start(lifespan)
	
func update_beam_visual(hit_pos: Vector2):
	print("FIring beam visual")
	var length = global_position.distance_to(hit_pos)
	var tex = beam_sprite.sprite_frames.get_frame_texture("beam_loop", 0)
	if tex:
		beam_sprite.scale.x = length / tex.get_width()
	else:
		print("No texture found in beam sprite")


func _on_timer_timeout() -> void:
	queue_free()


func _on_explosion_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
