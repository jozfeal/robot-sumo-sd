## Component that provides movement for a [VehicleBody3D] through inputs.
class_name VehicleController3D
extends Node

@export_group("Inputs", "input_")
## Must be defined in Input Map.
@export var input_forward: String = "forward"
## Must be defined in Input Map.
@export var input_backward: String = "backward"
## Must be defined in Input Map.
@export var input_left: String = "left"
## Must be defined in Input Map.
@export var input_right: String = "right"

@export_group("Nodes")
## Vehicle to apply movement to.
@export var vehicle: VehicleBody3D
@export_group("")

@export_group("Vehicle Quirks")
## Some vehicle physics bodies apply [member VehicleBody3D.engine_force] 
## along +Z rather than -Z, opposite the scene's mesh-forward convention. 
## Enable this if the vehicle drives backward relative to its visual facing direction.
@export var invert_engine_force: bool = false
@export_group("")

## Maximum degrees in radians the steering wheels are able to turn.
@export var max_steer: float = 45
## How fast the steering wheels turn.
@export var turn_speed: float = 2.5
## How much force is applied by accelerating.
@export var engine_power: float = 300

func _ready() -> void:
	assert(InputMap.has_action(input_forward), "%s is not defined in InputMap." % input_forward)
	assert(InputMap.has_action(input_backward), "%s is not defined in InputMap." % input_backward)
	assert(InputMap.has_action(input_left), "%s is not defined in InputMap." % input_left)
	assert(InputMap.has_action(input_right), "%s is not defined in InputMap." % input_right)

func _physics_process(delta: float) -> void:
	var max_rads: float = deg_to_rad(max_steer)
	vehicle.steering = move_toward(vehicle.steering, Input.get_axis(input_right, input_left) * max_rads, \
		delta * turn_speed)
	
	var throttle_input: float = Input.get_axis(input_backward, input_forward)
	vehicle.engine_force = throttle_input * engine_power * (-1.0 if invert_engine_force else 1.0)
