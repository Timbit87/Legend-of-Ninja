extends CharacterBody2D
class_name Player

@export var move_speed: float = 150
@export var push_strength: float = 150
@export var acceleration: float = 10

var original_colour: Color = Color(1,1,1)
var is_attacking: bool = false
var can_interact: bool = false
var last_move_direction: Vector2 = Vector2.RIGHT


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_trasure_label()
	update_hp_bar()
	if SceneManager.player_spawn_position != Vector2(0,0):
		position = SceneManager.player_spawn_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if SceneManager.player_hp <=0:
		return
	if not is_attacking:
		move_player()
	push_blocks()
	move_and_slide()
	update_trasure_label()
	if Input.is_action_just_pressed("Interact") and not can_interact:
		attack()
	if Input.is_action_just_pressed("Throw") and not can_interact:
		throw_kunai()
	
func move_player():
	var move_vector: Vector2 = Input.get_vector("move_left", "move_right","move_up","move_down")
	if move_vector != Vector2.ZERO:
		last_move_direction = move_vector.normalized()
	velocity = velocity.move_toward(move_vector * move_speed, acceleration)
	if velocity.x > 0:
		$AnimatedSprite2D.play("move_right")
		$InteractArea2D.position = Vector2(5,2)
	elif velocity.x < 0:
		$AnimatedSprite2D.play("move_left")		
		$InteractArea2D.position = Vector2(-5,2)
	elif velocity.y < 0:
		$AnimatedSprite2D.play("move_up")		
		$InteractArea2D.position = Vector2(0,-4)
	elif velocity.y > 0:
		$AnimatedSprite2D.play("move_down")		
		$InteractArea2D.position = Vector2(0,8)
	else:
		$AnimatedSprite2D.stop()
		
func push_blocks():
	var collision: KinematicCollision2D = get_last_slide_collision()
	if collision:		
		var collider_node = collision.get_collider()
		if collider_node.is_in_group("Pushable"):
			var collision_normal: Vector2 = collision.get_normal()
			collider_node.apply_central_force(-collision_normal * push_strength )
			if "play_scrape_sound" in collider_node:
				collider_node.play_scrape_sound()
				


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Interactable"):
		can_interact = true
		body.can_interact = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Interactable"):
		can_interact = false
		body.can_interact = false

func update_trasure_label():
	var treasure_amount: int = SceneManager.opened_chests.size()
	%TreasureLabel.text = str(treasure_amount)


func _on_hit_box_area_2d_body_entered(body):
	if body is CharacterBody2D and "is_dead" in body and body.is_dead:
		return

	take_damage(1)

	var distance_to_player: Vector2 = global_position - body.global_position
	var knockback_direction: Vector2 = distance_to_player.normalized()
	var knockback_strength: float = 200
	
	velocity += knockback_direction * knockback_strength
	
func take_damage(amount: int) -> void:
	if SceneManager.player_hp <= 0:
		return
	
	$PlayerDamageAudioStreamPlayer2D.play()
	SceneManager.player_hp -= amount
	update_hp_bar()
	
	if SceneManager.player_hp <= 0:
		$PlayerDeathAudioStreamLayer2D.play()
		die()
	
	var flash_white_colour: Color = Color(50, 50, 50)
	for i in range(2):
		modulate = flash_white_colour	
		await get_tree().create_timer(0.05).timeout	
		modulate = original_colour
		await get_tree().create_timer(0.05).timeout
	
func die():
	if $DeathTimer.is_stopped():
		$DeathTimer.start()
	$AnimatedSprite2D.play("death")

func _on_death_timer_timeout() -> void:
	SceneManager.player_hp = 3
	get_tree().call_deferred("reload_current_scene")
	
func update_hp_bar():
	if SceneManager.player_hp >= 3:
		%HPBar.play("3_hp")
	elif SceneManager.player_hp == 2:
		%HPBar.play("2_hp")
	elif SceneManager.player_hp == 1:
		%HPBar.play("1_hp")
	else:
		%HPBar.play("0_hp")

func attack():
	if not $AttackDurationTimer.is_stopped():
		return
	is_attacking = true
	velocity = Vector2.ZERO
	$AttackDurationTimer.start()
	
		
	var nunchuck = preload("res://Scenes/Nunchuck/nunchuck.tscn").instantiate()
	nunchuck.thrower = self
	var direction = last_move_direction
	match $AnimatedSprite2D.animation:
		"move_right", "attack_right":
			direction = Vector2.RIGHT
			$AnimatedSprite2D.play("attack_right")
		"move_left", "attack_left":
			direction = Vector2.LEFT
			$AnimatedSprite2D.play("attack_left")
		"move_down", "attack_down":
			direction = Vector2.DOWN
			$AnimatedSprite2D.play("attack_down")
		"move_up", "attack_up":
			direction = Vector2.UP
			$AnimatedSprite2D.play("attack_up")
	nunchuck.play_spin_animation(direction)
	var offset = 2
	nunchuck.global_position = global_position + direction * offset
	get_tree().current_scene.add_child(nunchuck)

func _on_ninjaku_area_2d_body_entered(body: Node2D) -> void:
	pass


func _on_attack_duration_timer_timeout() -> void:
	is_attacking = false
	var player_animation: String = $AnimatedSprite2D.animation
	if player_animation == "attack_right":
		$AnimatedSprite2D.play("move_right")
	elif player_animation == "attack_left":
		$AnimatedSprite2D.play("move_left")
	elif player_animation == "attack_down":
		$AnimatedSprite2D.play("move_down")
	elif player_animation == "attack_up":
		$AnimatedSprite2D.play("move_up")
		
func throw_kunai():
	
	if not $ThrowKunaiTimer.is_stopped() or is_attacking:
		return
	is_attacking = true
	velocity = Vector2.ZERO
	var kunai_instance = preload("res://Scenes/Kunai/Kunai.tscn").instantiate()
	kunai_instance.global_position = self.global_position
	kunai_instance.thrower = self
	var player_anim = $AnimatedSprite2D.animation
	match player_anim:
		"move_right", "attack_right":
			kunai_instance.throw_direction = Vector2.RIGHT
			$AnimatedSprite2D.play("attack_right")
			await get_tree().create_timer(0.2).timeout
			$AnimatedSprite2D.play("move_right")
		"move_left", "attack_left":
			kunai_instance.throw_direction = Vector2.LEFT
			$AnimatedSprite2D.play("attack_left")
			await get_tree().create_timer(0.2).timeout
			$AnimatedSprite2D.play("move_left")
		"move_up", "attack_up":
			kunai_instance.throw_direction = Vector2.UP
			$AnimatedSprite2D.play("attack_up")
			await get_tree().create_timer(0.2).timeout
			$AnimatedSprite2D.play("move_up")
		"move_down", "attack_down":
			kunai_instance.throw_direction = Vector2.DOWN
			$AnimatedSprite2D.play("attack_down")
			await get_tree().create_timer(0.2).timeout
			$AnimatedSprite2D.play("move_down")
		_:
			kunai_instance.throw_direction = Vector2.RIGHT
			$AnimatedSprite2D.play("attack_right")
			await get_tree().create_timer(0.2).timeout
			$AnimatedSprite2D.play("move_right")
	var kunai_offset = 8
	kunai_instance.global_position = self.global_position + kunai_instance.throw_direction * kunai_offset
	get_parent().add_child(kunai_instance)
	$ThrowKunaiTimer.start()
	is_attacking = false
