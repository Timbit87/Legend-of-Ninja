extends "res://Scenes/Enemy/enemy.gd"

enum State {
	IDLE,
	CHASING,
	AVOIDING,
	WINDUP,
	FIRING,
	DEAD
}

@export var step_duration := 0.2
@export var step_distance := 10

var is_timer_playing := false
var is_idling = true
var is_chasing = false
var random_movement_direction = Vector2.ZERO
var steps_remaining = 0
var player_in_avoidance_zone := false
var player = Node2D
var current_state = State.IDLE
var state_timer = 0.0

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
	match current_state:
		State.IDLE:
			handle_idle_state(delta)
		State.CHASING:
			handle_chasing_state(delta)
		State.AVOIDING:
			handle_avoiding_state(delta)
		State.WINDUP:
			handle_windup_state(delta)
		State.FIRING:
			handle_firing_state(delta)
		State.DEAD:
			pass
	super._physics_process(delta)
	animate_enemy()

	# footstep logic
	if velocity.length() > 2:
		if not is_timer_playing:
			$StepPlayer2D.play()
			is_timer_playing = true
	elif is_timer_playing:
		$StepPlayer2D.stop()
		is_timer_playing = false

func handle_idle_state(delta):
	if is_dead:
		return
	if velocity == Vector2.ZERO and not $RandomMovementTimer.is_stopped():
		start_random_movement()

func handle_chasing_state(delta):
	chase_target()

func chase_target():
	if returning_to_spawn:
		return

	if is_chasing and target:
		is_idling = false
		var dir = get_direction_to_target()
		velocity = velocity.move_toward(dir * speed, acceleration)
	else:
		is_idling = true

func animate_enemy():
	super.animate_enemy()	
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
	$SnakeDeathPlayer.play()
	$StepTimer.stop()
	
	await get_tree().create_timer(1.0).timeout
	queue_free()
	
func take_damage(amount: int = 1, attacker: Node2D = null):
	if attacker == null:
		print("No attacker passed!")
		return

	print("Attacker name: ", attacker.name)
	print("Attacker class: ", attacker.get_class())
	print("Attacker script: ", attacker.get_script())
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
		target = body
		is_chasing = true
		is_idling = false
		$StepTimer.stop()

func _on_chase_zone_area_2d_body_exited(body: Node2D) -> void:
	if body is Player and not is_dead:
		if is_chasing:
			is_chasing = false
			target = null
			returning_to_spawn = true
			nav_agent.target_position = spawn_position
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
