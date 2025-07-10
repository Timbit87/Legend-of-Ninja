extends "res://Scenes/Enemy/enemy.gd"

enum State {
	IDLE,
	CHASING,
	AVOIDING,
	STRAFING,
	WINDUP,
	FIRING,
	DEAD
}

@export var step_duration := 0.2
@export var step_distance := 10

var laser_scene = preload("res://Scenes/Lazer/eye_lazer.tscn")


var is_timer_playing := false
var is_idling = true
var is_chasing = false
var random_movement_direction = Vector2.ZERO
var steps_remaining = 0
var player_in_avoidance_zone := false
var player = Node2D
var current_state = State.IDLE
var state_timer = 0.0
var fire_cooldown = 0.0
var target_position = Vector2.ZERO
var current_strafe_direction: Vector2 = Vector2.ZERO
var strafe_flip_timer: float = 0.0
var locked_target_position: Vector2 = global_position

@onready var detection_area: Area2D = $PlayerDetectArea2D
@onready var chase_zone_area: Area2D = $ChaseZoneArea2D
@onready var eye_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var avoidance_area: Area2D = $AvoidPlayerArea

func _ready():
	super._ready()
	randomize()
	$StepTimer.timeout.connect(_on_step_timer_timeout)
	$RandomMovementTimer.timeout.connect(_on_random_movement_timer_timeout)
	detection_area.monitoring = true
	detection_area.connect("body_entered", Callable(self, "_on_player_detect_area_2d_body_entered"))
	chase_zone_area.connect("body_exited", Callable(self, "_on_chase_zone_area_2d_body_exited"))
	chase_zone_area.connect("body_entered", Callable(self, "_on_chase_zone_area_2d_body_entered"))
	
func _physics_process(delta: float) -> void:
	if is_dead:
		return

	fire_cooldown = max(fire_cooldown - delta, 0.0)

	match current_state:
		State.IDLE:
			handle_idle_state(delta)
		State.CHASING:
			handle_chasing_state(delta)
		State.STRAFING:
			handle_strafing_state(delta)
		State.AVOIDING:
			handle_avoiding_state(delta)
		State.WINDUP:
			handle_windup_state(delta)
		State.FIRING:
			handle_firing_state(delta)
		State.DEAD:
			pass

	update_state_logic()
	animate_enemy()
	move_and_slide()

	# footstep logic
	if velocity.length() > 2:
		if not is_timer_playing:
			$StepPlayer2D.play()
			is_timer_playing = true
	elif is_timer_playing:
		$StepPlayer2D.stop()
		is_timer_playing = false
		
func update_state_logic():
	if target == null or is_dead:
		current_state = State.IDLE
		return

	if current_state in [State.WINDUP, State.FIRING, State.DEAD]:
		return  # Don't interrupt these states

	var distance = global_position.distance_to(target.global_position)
	var max_range = $MaxRangeArea.get_node("CollisionShape2D").shape.radius
	var avoid_range = $AvoidPlayerArea.get_node("CollisionShape2D").shape.radius

	if is_chasing:
		if player_in_avoidance_zone or distance < avoid_range:
			current_state = State.AVOIDING
		elif distance <= max_range:
			current_state = State.STRAFING
		else:
			current_state = State.CHASING
	else:
		current_state = State.IDLE
		
func handle_idle_state(delta):
	fire_cooldown -= delta
	
	if is_chasing and target != null:
		if player_in_avoidance_zone:
			current_state = State.AVOIDING
		elif fire_cooldown <= 0:
			locked_target_position = player.global_position
			state_timer = 0.0
			current_state = State.WINDUP
		else:
			current_state = State.STRAFING
	elif target != null and not is_chasing:
		current_state = State.CHASING
	else:
		if not $StepTimer.is_stopped():
			return
		start_random_movement()

func handle_chasing_state(delta):
	if target:
		var distance = global_position.distance_to(target.global_position)
		if player_in_avoidance_zone:
			current_state = State.AVOIDING
		elif distance > $MaxRangeArea/CollisionShape2D.shape.radius * 0.95:
			var dir = get_direction_to_target()
			velocity = velocity.move_toward(dir * speed, acceleration)
		else:
			current_state = State.STRAFING
	else:
		is_chasing = false
		current_state = State.IDLE
		
func handle_strafing_state(delta):
	if player_in_avoidance_zone:
		current_state = State.AVOIDING
	elif target == null:
		current_state = State.IDLE
	elif fire_cooldown <= 0:
		locked_target_position = player.global_position
		state_timer = 0.0
		current_state = State.WINDUP
	else:
		var to_player = target.global_position - global_position
		strafe_flip_timer -= delta

		if strafe_flip_timer <= 0 or current_strafe_direction == Vector2.ZERO:
			var perp = Vector2(-to_player.y, to_player.x).normalized()
			current_strafe_direction = perp if randi() % 2 == 0 else -perp
			strafe_flip_timer = randf_range(1.0, 2.0)

		velocity = velocity.move_toward(current_strafe_direction * speed, acceleration)
	
func handle_avoiding_state(delta):
	if target:
		var dir = -get_direction_to_target()
		velocity = velocity.move_toward(dir * speed, acceleration)
	if not player_in_avoidance_zone:
		if fire_cooldown <= 0:
			current_state = State.WINDUP
		else:
			current_state = State.STRAFING
		
func handle_windup_state(delta):
	if target != null:
		velocity = Vector2.ZERO
		state_timer += delta
		if state_timer == delta:
			if is_instance_valid(player):
				locked_target_position = player.global_position
			else:
				locked_target_position = global_position
		if int(state_timer * 10) % 2 == 0:
			eye_sprite.modulate = Color(1,0,0)
		else:
			eye_sprite.modulate = Color(1,1,1)
		if state_timer > 0.5:
			eye_sprite.modulate = Color (1, 1, 1)
			state_timer = 0.0
			current_state = State.FIRING
	else:
		current_state = State.IDLE
		return
		
func handle_firing_state(delta):
	if not is_chasing or target == null:
		return
	velocity = Vector2.ZERO
	fire_cooldown = randf_range(3.0, 5.0)
	state_timer = 0.0
	fire_laser_at(locked_target_position)

	if player_in_avoidance_zone:
		current_state = State.AVOIDING
	elif target and global_position.distance_to(target.global_position) > $MaxRangeArea/CollisionShape2D.shape.radius:
		current_state = State.CHASING
	else:
		current_state = State.STRAFING
	current_state = State.IDLE
		
func fire_laser_at(pos: Vector2):
	var laser = laser_scene.instantiate()
	laser.global_position = global_position
	if is_instance_valid(player):
		laser.look_at(pos)
	else:
		laser.look_at(locked_target_position)
	laser.target_position = locked_target_position
	
	get_tree().current_scene.add_child(laser)

func chase_target():
	if returning_to_spawn:
		return

	if is_chasing and target:
		is_idling = false
		var dir = get_direction_to_target()
		velocity = velocity.move_toward(dir * speed, acceleration)
	else:
		is_idling = true
		
func start_windup():
	locked_target_position = player.global_position


func animate_enemy():
	super.animate_enemy()
	if target and not is_dead:
		var to_target = target.global_position - global_position
		var angle = to_target.angle()
		$PlayerDetectArea2D.rotation = angle
		
	var normal_velocity: Vector2 = velocity.normalized()
	if normal_velocity.x > 0.707:
		$PlayerDetectArea2D.rotation = deg_to_rad(-90)
	elif normal_velocity.x < -0.707:
		$PlayerDetectArea2D.rotation = deg_to_rad(90)
	elif normal_velocity.y > 0.707:
		$PlayerDetectArea2D.rotation = deg_to_rad(0)
	elif normal_velocity.y < -0.707:
		$PlayerDetectArea2D.rotation = deg_to_rad(180)
	
func death():
	is_dead = true
	set_process(false)
	set_physics_process(false)
	
	detection_area.monitoring = false 
	$CollisionShape2D.disabled = true
	$PlayerDetectArea2D.monitoring = false
	$AnimatedSprite2D.visible = false
	
	$StepPlayer2D.stop()
	$StepTimer.stop()
	
	await get_tree().create_timer(1.0).timeout
	queue_free()
	
func take_damage(amount: int = 1, attacker: Node2D = null):
	if attacker == null:
		print("No attacker passed!")
		return
	super.take_damage(amount, attacker)
	emit_blood_splatter()
		
	if not (attacker is Player):
		return
	if attacker != null:
		target = attacker
		is_chasing = true
		is_idling = false
	play_damage_sfx()

func play_damage_sfx():
	$DamageSFX.play()	
	
	
func _on_player_detect_area_2d_body_entered(body: Node2D) -> void:
	if body is Player and not is_dead:
		detect_player()
		is_idling = false
		$StepTimer.stop()

func _on_chase_zone_area_2d_body_exited(body: Node2D) -> void:
	if body is Player and not is_dead:
		if is_chasing:
			lose_player()
	start_random_movement()


func _on_random_step_timer_timeout() -> void:
	if is_dead:	
		return
	else:
		if velocity.length() > 2:
			play_step_sounds()

func _on_random_movement_timer_timeout() -> void:
	var min_time = 1.0
	var max_time = 5.0
	if not is_chasing:
		start_random_movement()

func _on_step_timer_timeout() -> void:
	if steps_remaining > 0 and not is_chasing:
		velocity = random_movement_direction * step_distance
		steps_remaining -= 1
		$StepTimer.start(step_duration) 
	else:
		velocity = Vector2.ZERO
		
func start_random_movement():
	is_idling = true
	steps_remaining = randi() % 4 + 1
	random_movement_direction = Vector2(
		[-1, 0, 1].pick_random(),
		[-1, 0, 1].pick_random()
	).normalized()
	$StepTimer.start(step_duration)
	$RandomMovementTimer.wait_time = randf_range(1.0, 5.0)
	$RandomMovementTimer.start()
	
func _on_avoid_player_area_body_entered(body: Node2D) -> void:
	if body is Player and not is_dead:
		player_in_avoidance_zone = true
		player = body


func _on_avoid_player_area_body_exited(body: Node2D) -> void:
	if body is Player and not is_dead:
		player_in_avoidance_zone = false


func _on_max_range_area_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_max_range_area_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
