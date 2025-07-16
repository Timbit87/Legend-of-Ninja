extends "res://Scenes/Enemy/enemy.gd"


@export var step_duration := 0.2
@export var step_distance := 10
@export var lizard_sounds: Array = []
@export var charge_speed := 400.0
@export var charge_duration := 0.4
@export var charge_cooldown := 1.0
@export var windup_time := 0.5
@export var stun_duration := 1.5


const MIN_CHARGE_DISTANCE := 100.0

var is_charging := false
var is_winding_up := false
var last_known_player_position := Vector2.ZERO
var is_timer_playing := false
var is_ideling = true
var random_movement_direction = Vector2.ZERO
var steps_remaining = 0

@onready var charge_timer := Timer.new()
@onready var stun_timer := Timer.new()
@onready var detection_area: Area2D = $PlayerDetectArea2D
@onready var chase_zone_area: Area2D = $ChaseZoneArea2D


func _ready():
	super._ready()
	randomize()
	$StepTimer.timeout.connect(_on_step_timer_timeout)
	$RandomMovementTimer.timeout.connect(_on_random_movement_timer_timeout)
	detection_area.monitoring = true
	detection_area.connect("body_entered", Callable(self, "_on_player_detect_area_2d_body_entered"))
	chase_zone_area.connect("body_exited", Callable(self, "_on_chase_zone_area_2d_body_exited"))
	chase_zone_area.connect("body_entered", Callable(self, "_on_chase_zone_area_2d_body_entered"))
	
	#charge logic
	charge_timer.one_shot = true
	add_child(charge_timer)
	charge_timer.timeout.connect(_on_charge_timer_timeout)
	charge_timer.start(randf_range(2.0, 5.0))  # Random first charge time

	stun_timer.one_shot = true
	add_child(stun_timer)
	stun_timer.timeout.connect(_on_stun_timer_timeout)
	
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_dead or is_winding_up:
		return
	if is_charging:
		var direction = (last_known_player_position - global_position).normalized()
		velocity = direction * charge_speed
		#regular attack at close range
		if global_position.distance_to(last_known_player_position) < 5:
			stop_charging()
		return

	if velocity.length() > 2:
		if not is_timer_playing:
			$RandomStepTimer.start()
			is_timer_playing = true
	elif is_timer_playing:
		$RandomStepTimer.stop()
		is_timer_playing = false
	animate_enemy()

func chase_target():
	if returning_to_spawn:
		return

	if is_chasing and target:
		is_ideling = false
		var dir = get_direction_to_target()
		velocity = velocity.move_toward(dir * speed, acceleration)
		$AttackNoisePlayer
	else:
		is_ideling = true

func animate_enemy():
	super.animate_enemy()	
	play_step_sounds()		
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
		is_ideling = false
	play_damage_sfx()

func play_damage_sfx():
	$DamageSFX.play()	
	
	
func _on_player_detect_area_2d_body_entered(body: Node2D) -> void:
	super._on_player_detect_area_2d_body_entered(body)
	is_ideling = false
	$StepTimer.stop()

func _on_chase_zone_area_2d_body_exited(body: Node2D) -> void:
	if body is Player and not is_dead and not is_charging:
		if is_chasing:
			lose_player()
	start_random_movement()


func _on_lizard_step_timer_timeout() -> void:
	if is_dead == true:	
		$StepPlayer2D.stop()
	else:
		if !$StepPlayer2D.playing:
			$StepPlayer2D.pitch_scale = randf_range(0.8, 1.2)
			$StepPlayer2D.play()

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
	is_ideling = true
	steps_remaining = randi() % 4 + 1
	random_movement_direction = Vector2(
		[-1, 0, 1].pick_random(),
		[-1, 0, 1].pick_random()
	).normalized()
	$StepTimer.start(step_duration)
	$RandomMovementTimer.wait_time = randf_range(1.0, 5.0)
	$RandomMovementTimer.start()
	
func _on_charge_timer_timeout():
	if not is_chasing or is_charging:
		charge_timer.start(randf_range(2.0, 5.0))
		return

	is_winding_up = true
	last_known_player_position = get_adjusted_charge_position(target.global_position)
	velocity = Vector2.ZERO

	await flash_before_charge(windup_time)

	await get_tree().create_timer(windup_time).timeout
	is_winding_up = false
	is_charging = true

	await get_tree().create_timer(charge_duration).timeout
	stop_charging()

func stop_charging():
	is_charging = false
	velocity = Vector2.ZERO
	charge_timer.start(randf_range(2.0, 5.0))
	
func _on_body_entered(body: Node2D):
	if is_charging and body.is_in_group("obstacles"):
		stun()
		
func stun():
	is_charging = false
	is_winding_up = false
	velocity = Vector2.ZERO
	stun_timer.start(stun_duration)
	
func _on_stun_timer_timeout():
	charge_timer.start(randf_range(2.0, 5.0))

func flash_before_charge(windup_time: float) -> void:
	var sprite := $AnimatedSprite2D
	var flash_colors = [Color.RED, Color.WHITE]
	var flash_count := 6 
	var time_per_flash := windup_time / float(flash_count * 2)

	for i in range(flash_count):
		var t = time_per_flash * (1.0 - float(i) / float(flash_count))  # Speed up
		sprite.modulate = flash_colors[0]
		await get_tree().create_timer(t).timeout
		sprite.modulate = flash_colors[1]
		await get_tree().create_timer(t).timeout

	sprite.modulate = Color.WHITE  # Reset

func get_adjusted_charge_position(target_position: Vector2) -> Vector2:
	var to_target := target_position - global_position
	var distance := to_target.length()
	
	if distance < MIN_CHARGE_DISTANCE:
		return global_position + to_target.normalized() * MIN_CHARGE_DISTANCE
	
	return target_position
	
