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
		obs.append(int(state["active"]))
		obs.append(state["edge_distance"])
		temp = state["relative_position"]
		obs.append_array([temp.x, temp.y, temp.z])
		temp = state["relative_rotation"]
		obs.append_array([temp.x, temp.y, temp.z])
		obs.append(state["engine_force"])
		obs.append(state["steering"])
		temp = state["linear_velocity"]
		obs.append_array([temp.x, temp.y, temp.z])
		temp = state["angular_velocity"]
		obs.append_array([temp.x, temp.y, temp.z])
	
	return {"obs":obs}

func get_reward() -> float:
	return reward

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
	
	feedback = StateFeedback.get_feedback()
	calculate_rewards()

## Adds / Substracts from [member reward] based on current feedback.
func calculate_rewards():
	# Don't calculate rewards after round ends
	if done or needs_reset:
		return
	
	# Positively rewards agent for being in advantageous position and vice versa
	# Reward magnitude increases the closer the agent is to the edge itself
	reward += (feedback[1]["edge_distance"] - feedback[2]["edge_distance"]) \
			* (1 - feedback[1]["edge_distance"]) * 0.1
	
	# Positively rewards if agent if blocking enemy's path to center and vice versa
	if feedback[1]["edge_distance"] > feedback[2]["edge_distance"] and StateFeedback.agent_blocking():
		reward += 0.2
	elif feedback[1]["edge_distance"] < feedback[2]["edge_distance"] and StateFeedback.agent_blocked():
		reward -= 0.2

func get_obs_space() -> Dictionary:
	return {
		"obs": {
			"size": [38],
			"space": "box"
		},
	}
