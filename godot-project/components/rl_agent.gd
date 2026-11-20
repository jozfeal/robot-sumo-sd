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

## Distance to opponent in the last step.
var last_distance_squared: float = 0

func get_obs() -> Dictionary:
	var obs: Array = []
	
	# Make the agent's own status first in the array
	for i in range(1, feedback.size()):
		var state: Dictionary = feedback[i]
		var temp
		
		# Include agent's position and rotation values, along with its own movement
		if state["robot"] == controller.robot:
			temp = state["position"]
			obs.append_array([temp.x, temp.y, temp.z])
			temp = state["rotation"]
			obs.append_array([temp.x, temp.y, temp.z])
			obs.append(state["left_wheel_speed"])
			obs.append(state["right_wheel_speed"])
		
			# Add all other robot state values to observations
			#obs.append(state["edge_distance"])
			temp = state["relative_position"]
			obs.append_array([temp.x, temp.y, temp.z])
			break
	
	# Add all other robots after
	for i in range(1, feedback.size()):
		var state: Dictionary = feedback[i]
		var temp
		if state["robot"] == controller.robot:
			continue
		# Add all other robot state values to observations
		obs.append(state["edge_distance"])
		temp = state["relative_position"]
		obs.append_array([temp.x, temp.y, temp.z])
	
	return {"obs":obs}

func get_reward() -> float:
	# Rewards agent positively for being closer to the center than their opponent and vice versa
	#var factor: float = 1.0
	#if get_agent_state()["edge_distance"] < get_enemy_state()["edge_distance"]:
		#factor = -1.0
	#reward += factor * (1 - get_agent_state()["edge_distance"]) * 0.01
	
	if last_distance_squared == 0:
		last_distance_squared = get_enemy_state()["relative_position"].length_squared()
	else:
		var distance_sqaured = get_enemy_state()["relative_position"].length_squared()
		reward += last_distance_squared - distance_sqaured * 0.01
		last_distance_squared = distance_sqaured
	
	return reward

func get_action_space() -> Dictionary:
	return {
		# Discrete action space of 3 for backward, forward, or none
		"left_wheel" : {
			"size": 3,
			"action_type": "discrete"
		},
		# Discrete action space of 3 for backward, forward or none
		"right_wheel" : {
			"size": 3,
			"action_type": "discrete"
		}
	}

func set_action(action) -> void:
	# Converts the actions into a choice of [-1, 0, 1] for throttle and steer
	input_value.x = int(action["left_wheel"]) - 1
	input_value.y = int(action["right_wheel"]) - 1

func _physics_process(_delta):
	controller.receive_input(input_value)
	
	feedback = StateFeedback.get_feedback(controller.robot)
	calculate_rewards()

## Adds / Substracts from [member reward] based on current feedback.
func calculate_rewards():
	# Don't calculate rewards after round ends
	if done or needs_reset:
		return

func get_obs_space() -> Dictionary:
	return {
		"obs": {
			"size": [16],
			"space": "box"
		},
	}

## Returns the opposing robot state in a 2 robot simulation.
func get_enemy_state() -> Dictionary:
	for i in range(1, feedback.size()):
		var state: Dictionary = feedback[i]
		if state["robot"] != controller.robot:
			return state
	return { }

## Returns the agent robot state in a 2 robot simulation.
func get_agent_state() -> Dictionary:
	for i in range(1, feedback.size()):
		var state: Dictionary = feedback[i]
		if state["robot"] == controller.robot:
			return state
	return { }
