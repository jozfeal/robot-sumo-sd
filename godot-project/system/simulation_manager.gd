class_name SimulationManager
extends Node

## [RLAgent].
@export var agent: RLAgent
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
	
	# If the simulation is in headless mode, uncap fps for RL training
	#if DisplayServer.get_name() == "headless" or not DisplayServer.window_can_draw():
		## Disable VSync so the engine isn't capped by monitor refresh rate
		#DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		#Engine.max_fps = 0
		#Engine.time_scale = HEADLESS_SPEED_FACTOR
		#@warning_ignore("narrowing_conversion")
		#Engine.physics_ticks_per_second = DEFAULT_PHYSICS_TICKS * HEADLESS_SPEED_FACTOR

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()

## Initializes a new simulation round.
func start_simulation() -> void:
	# Gets all Robot type children of robot_holder and adds them to robots array
	var robots: Array[Robot] = []
	robots.assign(robot_holder.get_children().filter(func(child): return child is Robot))
	StateFeedback.assign_robots(robots, robots.find(agent_robot))
	StateFeedback.ring_radius = (ring_shape.shape as CylinderShape3D).radius
	
	round_timer.start()

func _on_round_timer_timeout() -> void:
	StateFeedback.end_draw()

# Waits for the Sync node to establish a connection with Python
func _wait_for_sync():
	# Wait for Sync initialization to finish
	while not sync.initialized:
		await get_tree().process_frame
	
	if not sync.connected:
		push_error("Failed to connect to Python!")
