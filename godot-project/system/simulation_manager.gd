class_name SimulationManager
extends Node

# headless runs faster, with the same simulation time per tick
var HEADLESS_SPEED_FACTOR: float = 10.0
var DEFAULT_PHYSICS_TICKS: int = 60

# shared across scene reloads
static var episode_count := 0

@onready var red_robot: Robot = $"../Robots/RedRobot"
@onready var blue_robot: Robot = $"../Robots/BlueRobot"
@onready var ring: Area3D = $"../RingArea"

var feedback: SumoStateFeedback
var match_finished := false
var _last_delta := 0.0


func _ready() -> void:
	if DisplayServer.get_name() == "headless" or not DisplayServer.window_can_draw():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
		Engine.time_scale = HEADLESS_SPEED_FACTOR
		@warning_ignore("narrowing_conversion")
		Engine.physics_ticks_per_second = DEFAULT_PHYSICS_TICKS * HEADLESS_SPEED_FACTOR

	# read before the controllers change steering and throttle
	process_physics_priority = -1
	feedback = SumoStateFeedback.new(red_robot, blue_robot)
	episode_count += 1
	feedback.start_episode(episode_count, ring.robots.has(red_robot), ring.robots.has(blue_robot))


func _physics_process(delta: float) -> void:
	if match_finished:
		return
	if _last_delta == 0.0:
		# no completed step yet
		_last_delta = delta
		return

	var winner := ""
	if ring.winner == red_robot:
		winner = "red"
	elif ring.winner == blue_robot:
		winner = "blue"
	# physics ran after the last call; use the duration from that call
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
