extends Node2D

@export var damage := 2
@export var knockback_force := 150
@export var already_hit_enemies := {}

func _ready():
	$HitBox.connect("body_entered", Callable(self, "on_hitbox_body_entered"))
	
func on_hitbox_body_entered(body: Node2D) -> void:
	if body in already_hit_enemies:
		return
		
	if "velocity" in body:
		var distance_to_enemy: Vector2 = body.global_position - global_position
		var knockback_direction: Vector2 = distance_to_enemy.normalized()
		body.velocity += knockback_direction * knockback_force
	if "take_damage" in body:
		body.take_damage(damage, self)
		already_hit_enemies[body] = true
