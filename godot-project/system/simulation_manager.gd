class_name SimulationManager
extends Node

## Speed up factor for the physics ticks when running in headless mode.
var HEADLESS_SPEED_FACTOR: float = 10.0
var DEFAULT_PHYSICS_TICKS: int = 60

func _ready() -> void:
	# If the simulation is in headless mode, uncap fps for RL training
	if DisplayServer.get_name() == "headless" or not DisplayServer.window_can_draw():
		# Disable VSync so the engine isn't capped by monitor refresh rate
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
		Engine.time_scale = HEADLESS_SPEED_FACTOR
		@warning_ignore("narrowing_conversion")
		Engine.physics_ticks_per_second = DEFAULT_PHYSICS_TICKS * HEADLESS_SPEED_FACTOR

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
