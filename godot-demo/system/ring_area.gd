extends Area3D

@export var robots: Array[Robot]

func _on_body_exited(body: Node3D) -> void:
	if body is Robot:
		robots.erase(body)
		
		if robots.size() == 1:
			print("%s wins!" % robots[0].robot_name)
