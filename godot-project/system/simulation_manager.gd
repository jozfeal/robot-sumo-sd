class_name SimulationManager
extends Node

## Speed up factor for the physics ticks when running in headless mode.
var HEADLESS_SPEED_FACTOR: float = 10.0
var DEFAULT_PHYSICS_TICKS: int = 60

# survives scene reloads
static var episode_count := 0

@onready var red_robot: Robot = $"../Robots/RedRobot"
@onready var blue_robot: Robot = $"../Robots/BlueRobot"
@onready var ring: Area3D = $"../RingArea"

var feedback: SumoStateFeedback
var match_finished := false
var _last_delta := 0.0


func _ready() -> void:
	# If the simulation is in headless mode, uncap fps for RL training
	if DisplayServer.get_name() == "headless" or not DisplayServer.window_can_draw():
		# Disable VSync so the engine isnt capped by monitor refresh rate
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
		Engine.time_scale = HEADLESS_SPEED_FACTOR
		@warning_ignore("narrowing_conversion")
		Engine.physics_ticks_per_second = DEFAULT_PHYSICS_TICKS * HEADLESS_SPEED_FACTOR

	# read the finished step before the controllers set their next inputs
	process_physics_priority = -1
	feedback = SumoStateFeedback.new(red_robot, blue_robot)
	episode_count += 1
	feedback.start_episode(episode_count, ring.robots.has(red_robot), ring.robots.has(blue_robot))


func _physics_process(delta: float) -> void:
	# keep the last result available until the scene is restarted
	if match_finished:
		return
	if _last_delta == 0.0:
		# the first call happens before physics has moved either robot
		_last_delta = delta
		return

	var winner := ""
	if ring.winner == red_robot:
		winner = "red"
	elif ring.winner == blue_robot:
		winner = "blue"
	# these positions came from the previous physics step, so use its delta
	feedback.capture_step(
		_last_delta, ring.robots.has(red_robot), ring.robots.has(blue_robot), winner
	)
	_last_delta = delta
	match_finished = not winner.is_empty()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()
	elif event.is_action_pressed("save_feedback"):
		var path := "user://sumo_state.json"
		var error := feedback.save_state(path)
		if error != OK:
			push_error("cant save feedback: %s" % error_string(error))
		else:
			print("Saved state: ", ProjectSettings.globalize_path(path))
