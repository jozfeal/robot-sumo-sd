extends Area3D

@export var robots: Array[Robot]
@export var win_text: Label

signal round_over()

func _on_body_exited(body: Node3D) -> void:
	if body is Robot:
		robots.erase(body)
		StateFeedback.robot_lost(body)
		
		if robots.size() <= 1:
			round_over.emit()
