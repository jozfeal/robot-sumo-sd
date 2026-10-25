extends Area3D

@export var robots: Array[Robot]
@export var win_text: Label

var winner: Robot


func _on_body_exited(body: Node3D) -> void:
	# other bodies can leave this area too, especially during a scene reload
	if not body is Robot or body not in robots:
		return
	robots.erase(body)
	# keep the first result if the other robot leaves after the match ends
	if winner != null or robots.size() != 1:
		return

	winner = robots[0]
	win_text.label_settings.font_color = winner.color
	win_text.text = "%s wins!\n Press 'R' to restart." % winner.robot_name
	win_text.show()
