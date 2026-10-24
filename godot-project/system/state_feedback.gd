extends Node

var winner: Robot
# Stores the robots in the match as keys, and their match status as value.
# When a robot is eliminated from the match its value becomes false.
var _robot_status: Dictionary

## Stores an internal dictionary of robots and marks them all as active.
## [param agent] is the index of the agent's robot inside [param robots].
func assign_robots(robots: Array[Robot], agent_index: int) -> void:
	_robot_status.clear()
	# Make the agent the first entry of _robot_status
	robots.pop_at(agent_index)
	robots.push_front(agent_index)
	for r: Robot in robots:
		_robot_status[r] = true

## Returns a list containing all feedback.
func get_feedback() -> Array:
	# Makes feedback[0] 0 for a draw, -1 for an ongoing match, or the index of the winner
	# Index is in reference to the feedback array, with 1 being the agent robot
	var feedback: Array = [-1]
	var statuses: Array[bool] = _robot_status.values()
	if statuses.count(true) == 1:
		feedback[0] = statuses.find(true)
	elif statuses.count(true) == 0:
		feedback[0] = 0
	
	# Adds an entry to feedback for each robot with their state
	for robot: Robot in _robot_status:
		var state: Dictionary = {
			"active": false,
			"position": Vector3.ZERO,
			"rotation": Vector3.ZERO,
			"engine_force": 0.0,
			"brake": 0.0,
			"steering": 0.0
		}
		
		# Gets all the properties from the robot
		state["active"] = _robot_status[robot]
		state["position"] = robot.global_position
		state["rotation"] = robot.rotation
		state["engine_force"] = robot.engine_force
		state["steering"] = robot.steering
		feedback.append(state)
	return feedback
