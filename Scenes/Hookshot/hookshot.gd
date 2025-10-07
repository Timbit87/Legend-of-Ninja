extends Area2D

@export var speed: float = 400.0
@export var max_distance: float = 200.0
@export var rope_width: float = 2.0

var direction: Vector2
var player: Node = null
var is_retracting: bool = false
var hit_point: Vector2

func _ready():
	connect("area_entered", Callable(self, "on_area_entered"))
	$Line2D.width = rope_width
	$Line2D.default_color = Color(0.3, 0.2, 0.1)
	$Line2D.position = Vector2.ZERO
	
func _physics_process(delta: float) -> void:
	if not is_retracting:
		global_position += direction * speed * delta
		if player.global_position.distance_to(global_position) > max_distance:
			start_retract()
	else:
		if player:
			global_position = global_position.move_toward(player.global_position, speed * delta)
			if global_position.distance_to(player.global_position) < 5.0:
				queue_free()
	if player:
		var player_local: Vector2 = to_local(player.global_position)
		$Line2D.points = [player_local, Vector2.ZERO]

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("HookshotTargets"):
		hit_point = area.global_position
		start_pull_player()
		
func start_pull_player():
	set_physics_process(false)
	player.start_hook_pull(hit_point)
	queue_free()
	
func start_retract():
	is_retracting = true
