extends Marker2D

signal puzzle_solved
signal puzzle_failed
@export var target_score: int = 2
var score: int = 0

func increase_score():
	score += 1
	print(score)
	if score >= target_score:
		puzzle_solved.emit()
	
func decrease_score():
	score -= 1
	print(score)
	if score < target_score:
		puzzle_failed.emit()
