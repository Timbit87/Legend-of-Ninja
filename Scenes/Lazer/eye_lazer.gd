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

func _ready() -> void:
	raycast.force_raycast_update()
	
	beam_sprite.play("beam_loop")
	zap_sound.play()
	
	if raycast.is_colliding():
		var hit_position = raycast.get_collision_point()
		var hit_object = raycast.get_collider()
		
		explosion_sprite.global_position = hit_position
		explosion_area.global_position = hit_position
		explosion_sound.global_position = hit_position
		
		explosion_sprite.show
		explosion_sprite.play("explode")
		explosion_area.monitoring = true
		explosion_sound.play()
		
		
