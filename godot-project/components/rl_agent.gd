class_name RLAgent
extends AIController3D

@export_group("Nodes")
## [RobotController] that this agent is sending input to.
@export var controller: RobotController
@export_group("")

## The robot's input values with x for throttle and y for steering.
## Sould as a parameter to [method RobotController.receive_input].
var input_value: Vector2

func get_obs() -> Dictionary:
	return {"obs":[]}

func get_reward() -> float:
	return 0.0

func get_action_space() -> Dictionary:
	return {
		"input" : {
			"size": 2,
			"action_type": "continuous"
		}
	}

func set_action(action) -> void:
	input_value.x = action["input"][0]
	input_value.y = action["input"][1]

func _physics_process(_delta):
	controller.receive_input(input_value)

#-- Methods that can be overridden if needed --#

#func get_obs_space() -> Dictionary:
# May need overriding if the obs space is complex
#	var obs = get_obs()
#	return {
#		"obs": {
#			"size": [len(obs["obs"])],
#			"space": "box"
#		},
#	}
