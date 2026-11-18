extends Area3D

@export var robots: Array[Robot]
@export var win_text: Label
var robots_chassis: Array[RigidBody3D]

signal round_over()

func _ready() -> void:
	for robot: Robot in robots:
		robots_chassis.append(robot.chassis)

func _on_body_exited(body: Node3D) -> void:
	if body is RigidBody3D:
		robots_chassis.erase(body)
		StateFeedback.robot_lost(body.get_parent())
		
		if robots.size() <= 1:
			round_over.emit()
			print("done")
