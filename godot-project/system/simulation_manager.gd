class_name SimulationManager
extends Node

## All [RLAgent]s being trained.
@export var agents: Array[RLAgent]
## Robot assigned to the training agent.
@export var agent_robot: Robot
## Node holding all robots in simulation as children.
@export var robot_holder: Node
## [CollisionShape] that determines the ring size.
@export var ring_shape: CollisionShape3D
@export var round_timer: Timer
@export var sync: Sync

## Speed up factor for the physics ticks when running in headless mode.
var HEADLESS_SPEED_FACTOR: float = 10.0
var DEFAULT_PHYSICS_TICKS: int = 60

func _ready() -> void:
	assert(agent_robot != null, "agent_robot not assigned in SimulationManager.")
	# Wait for the Sync node to connect
	call_deferred("_wait_for_sync")
	start_simulation()

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()

## Initializes a new simulation round.
func start_simulation() -> void:
	# Gets all Robot type children of robot_holder and adds them to robots array
	var robots: Array[Robot] = []
	robots.assign(robot_holder.get_children().filter(func(child): return child is Robot))
	var ring_radius: float = (ring_shape.shape as CylinderShape3D).radius
	
	# Spawns the robots in a random equivalent distance around the circle
	# Helps prevent overfitting
	var spawn_dist: float = randf_range(0.70, 0.55) * ring_radius
	var random_spawn: Vector2 = Vector2.RIGHT.rotated(randf() * TAU) * spawn_dist
	robots[0].teleport(Vector3(random_spawn.x, 0, random_spawn.y))
	robots[1].teleport(Vector3(-random_spawn.x, 0 , -random_spawn.y))
	# Aligns orientation so robot looks at center.
	robots[0].look_at(Vector3.ZERO)
	robots[1].look_at(Vector3.ZERO)
	
	# Initialize StateFeedback values
	StateFeedback.assign_robots(robots)
	StateFeedback.ring_radius = ring_radius
	
	# Initialize enemy distance for rewards
	for a: RLAgent in agents:
		a.previous_enemy_distance = \
				(StateFeedback.get_feedback(a.controller.robot)[2]["relative_position"] as Vector3).length_squared()
	
	round_timer.start()

func _on_round_timer_timeout() -> void:
	if all_agents_done():
		return
	StateFeedback.end_draw()
	set_agents_done()

# Waits for the Sync node to establish a connection with Python
func _wait_for_sync():
	# Wait for Sync initialization to finish
	while not sync.initialized:
		await get_tree().process_frame
	
	if not sync.connected:
		push_error("Failed to connect to Python!")


func _on_ring_area_round_over() -> void:
	if sync.control_mode == Sync.ControlModes.HUMAN:
		start_simulation()
	
	if all_agents_done():
		return
	set_agents_done()
	
	# Gives +100 reward to agents who are active at round end, and -100 otherwise
	# Results in -100 rewards for all agents on draw
	for agent: RLAgent in agents:
		var feedback: Array = StateFeedback.get_feedback(agent.controller.robot)
		for i in range(1, feedback.size()):
			var state: Dictionary = feedback[i]
			if state["robot"] == agent.controller.robot:
				if state["active"]:
					agent.reward += 100
				else:
					agent.reward -= 100
				break

func _physics_process(_delta: float) -> void:
	# Ensures the agents gets terminal rewards before restarting simulation
	if all_agents_done():
		for agent: RLAgent in agents:
			agent.reset()
		start_simulation()

## Sets the done and reset flags on all simulation agents.
func set_agents_done(done: bool = true) -> void:
	for agent: RLAgent in agents:
		agent.done = true
		agent.needs_reset = true

## Checks that all agents are done.
func all_agents_done() -> bool:
	for agent: RLAgent in agents:
		if agent.done == false:
			return false
	return true
