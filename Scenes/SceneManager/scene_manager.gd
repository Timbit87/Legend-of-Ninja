extends Node2D
	
var player_spawn_position: Vector2
var player_hp: int = 3
var opened_chests: Array[String] = []
var state = {
	"door_open_overworld": false,
	"block_on_button_overworld": false,
	"button_pressed_overworld": false,
}
