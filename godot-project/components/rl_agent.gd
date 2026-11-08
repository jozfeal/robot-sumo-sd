class_name RLAgent
extends AIController3D

@export_group("Nodes")
## [RobotController] that this agent is sending input to.
@export var controller: RobotController
@export_group("")

## The robot's input values with x for throttle and y for steering.
## Sould as a parameter to [method RobotController.receive_input].
var input_value: Vector2

## Feedback from last frame.
var feedback: Array

# Used for reward calculation
var previous_enemy_distance: float

func get_obs() -> Dictionary:
	var obs: Array = []
	for i in range(1, feedback.size()):
		var state: Dictionary = feedback[i]
		var temp
		
		# Include agent's position and rotation values
		if i == 1:
			temp = state["position"]
			obs.append_array([temp.x, temp.y, temp.z])
			temp = state["rotation"]
			obs.append_array([temp.x, temp.y, temp.z])
		
		# Add all other robot state values to observations
		obs.append(state["edge_distance"])
		temp = state["relative_position"]
		obs.append_array([temp.x, temp.y, temp.z])
		obs.append(state["engine_force"])
		obs.append(state["steering"])
	
	return {"obs":obs}

func get_reward() -> float:
	return reward

func get_action_space() -> Dictionary:
	return {
		# Discrete action space of 3 for backward, forward, or none
		"throttle" : {
			"size": 3,
			"action_type": "discrete"
		},
		# Discrete action space of 3 for left, right, or none
		"steering" : {
			"size": 3,
			"action_type": "discrete"
		}
	}

func set_action(action) -> void:
	# Converts the actions into a choice of [-1, 0, 1] for throttle and steer
	input_value.x = int(action["throttle"]) - 1
	input_value.y = int(action["steering"]) - 1

func _physics_process(_delta):
	controller.receive_input(input_value)
	
	feedback = StateFeedback.get_feedback()
	calculate_rewards()

## Adds / Substracts from [member reward] based on current feedback.
func calculate_rewards():
	# Don't calculate rewards after round ends
	if done or needs_reset:
		return
	
	# Positively rewards the agent for making progress moving towards the enemy
	var current_enemy_distance: float = (feedback[2]["relative_position"] as Vector3).length_squared()
	reward += (previous_enemy_distance - current_enemy_distance) * 0.2
	previous_enemy_distance = current_enemy_distance

func get_obs_space() -> Dictionary:
	return {
		"obs": {
			"size": [18],
			"space": "box"
		},
	}
