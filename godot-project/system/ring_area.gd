extends Area3D

@export var robots: Array[Robot]
@export var win_text: Label

func _on_body_exited(body: Node3D) -> void:
	# Only count robots that are still in the match
	if body is Robot and body in robots:
		robots.erase(body)
		var winner: Robot = StateFeedback.robot_lost(body)
		
		# Use the winner from feedback for the label
		if winner != null:
			win_text.label_settings.font_color = winner.color
			win_text.text = "%s wins!\n Press 'R' to restart." % winner.robot_name
			win_text.show()
