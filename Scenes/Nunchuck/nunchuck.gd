class_name Nunchuck
extends Node2D

@export var damage := 2
@export var knockback_force := 150
@export var backstab_damage := 200
var already_hit_enemies := {}
var thrower: Node2D

func _ready():
	%NunchuckArea2D.connect("body_entered", Callable(self, "on_hitbox_body_entered"))
	
func on_hitbox_body_entered(body: Node2D) -> void:
	if body in already_hit_enemies:
		return
		
	if "velocity" in body:
		var distance_to_enemy: Vector2 = body.global_position - global_position
		var knockback_direction: Vector2 = distance_to_enemy.normalized()
		body.velocity += knockback_direction * knockback_force		
	
	if "take_damage" in body:
		if thrower and is_backstab(thrower.global_position, body):
			body.take_damage(backstab_damage, thrower)
		else:
			body.take_damage(damage, thrower)
			already_hit_enemies[body] = true
			if thrower and thrower.has_method("set_stealth_mode"):
				thrower.set_stealth_mode(false)

func play_spin_animation(direction: Vector2):
	if direction == Vector2.RIGHT:
		$AnimationPlayer.play("attack_right")
	elif direction == Vector2.LEFT:
		$AnimationPlayer.play("attack_left")
	elif direction == Vector2.UP:
		$AnimationPlayer.play("attack_up")
	elif direction == Vector2.DOWN:
		$AnimationPlayer.play("attack_down")
	$AnimationPlayer.connect("animation_finished", Callable(self, "_on_spin_finished"))

func _on_spin_finished(anim_name: String) -> void:
	queue_free()
	
func is_backstab(attacker_position: Vector2, enemy) -> bool:
	if not enemy.has_method("get_facing_direction"):
		return false
		
	var to_attacker = (attacker_position - enemy.global_position).normalized()
	var enemy_facing = enemy.get_facing_direction()
	var dot = enemy_facing.dot(to_attacker)
	print("Facing:", enemy_facing, "To attacker:", to_attacker)
	print("Dot:", dot)
	return dot > 0.5
