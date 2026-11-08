extends Node

## Radius of the ring, used for normalization.
var ring_radius: float = 10
## Robot that the agent controls.
var agent: Robot

# Stores the robots in the match as keys, and their match status as value.
# When a robot is eliminated from the match its value becomes false.
var _robot_status: Dictionary

## Stores an internal dictionary of robots and marks them all as active.
## [param agent_index] is the index of the agent's robot inside [param robots].
func assign_robots(robots: Array[Robot], agent_index: int) -> void:
	_robot_status.clear()
	# Make the agent the first entry of _robot_status
	agent = robots.pop_at(agent_index)
	robots.push_front(agent)
	for r: Robot in robots:
		_robot_status[r] = true

## Marks a robot as lost in feedback.
func robot_lost(robot: Robot) -> void:
	_robot_status[robot] = false

## Ends the current round in a draw.
func end_draw() -> void:
	for robot: Robot in _robot_status:
		robot_lost(robot)

## Returns a list containing all feedback.
## Call after all assignments, updates, and at the end of the physics tick.
func get_feedback() -> Array:
	# Makes feedback[0] 0 for a draw, -1 for an ongoing match, or the index of the winner
	# Index is in reference to the feedback array, with 1 being the agent robot
	var feedback: Array = [-1]
	var statuses: Array[bool] = []
	statuses.assign(_robot_status.values())
	if statuses.count(true) == 1:
		# Add 1 so that 0 can be used for draws
		feedback[0] = statuses.find(true) + 1
	elif statuses.count(true) == 0:
		feedback[0] = 0
	
	# Adds an entry to feedback for each robot with their state
	for robot: Robot in _robot_status:
		var state: Dictionary
		# Get all the properties from the robot
		state["active"] = _robot_status[robot]
		state["edge_distance"] = (ring_radius - robot.global_position.length()) / ring_radius
		state["position"] = robot.global_position
		state["relative_position"] = robot.global_position - agent.global_position
		state["rotation"] = robot.rotation
		state["relative_rotation"] = robot.rotation - agent.rotation
		state["engine_force"] = robot.engine_force
		state["steering"] = robot.steering
		state["linear_velocity"] = robot.linear_velocity
		state["angular_velocity"] = robot.angular_velocity
		feedback.append(state)
	return feedback

## Returns true if the agent robot is blocked by another robot.
func agent_blocked() -> bool:
	for robot: Robot in _robot_status:
		if robot == agent:
			continue
		
		if is_blocking(robot, agent):
			return true
	return false

## Returns true if the agent robot is blocking another robot.
func agent_blocking() -> bool:
	for robot: Robot in _robot_status:
		if robot == agent:
			continue
		
		if is_blocking(agent, robot):
			return true
	return false

## Returns true if [param blocker] is directly blocking [member blocked]'s path to
## the center of the ring.
func is_blocking(blocker: Robot, blocked: Robot) -> bool:
	var space_state = get_tree().root.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		# Average the heights to make the raycast more accurate
		Vector3(0, (blocker.global_position.y + blocked.global_position.y) / 2, 0),
		blocked.global_position
	)
	var result = space_state.intersect_ray(query)
	return not result.is_empty() and result["collider"] == blocker
