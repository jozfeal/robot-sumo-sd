extends Node

# Stores the robots in the match as keys, and their match status as value.
# When a robot is eliminated from the match its value becomes false.
var _robot_status: Dictionary

# -1 while the match is running, 0 for a draw, otherwise the winner index in get_feedback()
var _match_result: int = -1

## Stores an internal dictionary of robots and marks them all as active.
## [param agent_index] selects the agent robot inside [param robots].
func assign_robots(robots: Array[Robot], agent_index: int) -> void:
	_robot_status.clear()
	_match_result = -1
	# Make the agent the first entry of _robot_status
	var agent: Robot = robots.pop_at(agent_index)
	robots.push_front(agent)
	for r: Robot in robots:
		_robot_status[r] = true

## Marks a robot as lost. Returns the winner if this exit ends the match, otherwise null.
func robot_lost(robot: Robot) -> Robot:
	# Ignore exits after the result is set
	if _match_result != -1 or not _robot_status.has(robot):
		return null
	_robot_status[robot] = false

	var statuses: Array[bool] = []
	statuses.assign(_robot_status.values())
	if statuses.count(true) == 1:
		# Add 1 so that 0 can be used for draws
		_match_result = statuses.find(true) + 1
		return _robot_status.keys()[_match_result - 1]
	elif statuses.count(true) == 0:
		_match_result = 0
	return null

## Returns the result followed by each robot, with the agent first.
func get_feedback() -> Array:
	var feedback: Array = [_match_result]

	# Adds an entry to feedback for each robot with their state
	for robot: Robot in _robot_status:
		var state: Dictionary
		# Get all the properties from the robot
		state["active"] = _robot_status[robot]
		state["position"] = robot.global_position
		state["rotation"] = robot.rotation
		state["linear_velocity"] = robot.linear_velocity
		state["angular_velocity"] = robot.angular_velocity
		state["engine_force"] = robot.engine_force
		state["steering"] = robot.steering
		feedback.append(state)
	return feedback
