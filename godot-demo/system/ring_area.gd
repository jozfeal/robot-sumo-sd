extends Area3D

@export var robots: Array[Robot]
@export var win_text: Label

func _on_body_exited(body: Node3D) -> void:
	if body is Robot:
		robots.erase(body)
		
		if robots.size() == 1:
			win_text.label_settings.font_color = robots[0].color
			win_text.text = "%s wins!\n Press 'R' to restart." % robots[0].robot_name
			win_text.show()
