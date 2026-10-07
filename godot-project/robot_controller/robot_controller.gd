## Component that provides movement for a [Robot].
## Can be set to utilize inputs defined in the InputMap or take
## an input as a value.
class_name RobotController
extends Node

enum InputMode { 
	## Inputs are received from the user. Must be defined in InputMap.
	USER,
	## Inputs are received through the [method receive_input] method every physics tick.
	VALUE,
}
@export_group("Input", "input_")
## Defines if the controller receives input as a value or through user inputs.
@export var input_mode: InputMode
## Must be defined in Input Map.
@export var input_forward: String = "forward"
## Must be defined in Input Map.
@export var input_backward: String = "backward"
## Must be defined in Input Map.
@export var input_left: String = "left"
## Must be defined in Input Map.
@export var input_right: String = "right"

@export_group("Nodes")
## Robot that this controller is assigned to.
@export var robot: Robot
@export_group("")

# Current input values to process in _physics_process.
# X corresponds to steering, Y corresponds to engine throttle.
var _input: Vector2 = Vector2.ZERO

## Maximum degrees in degrees the steering wheels are able to turn.
@export var max_steer: float = 45
## How fast the steering wheels turn.
@export var turn_speed: float = 2.5
## How much force is applied by accelerating.
@export var engine_power: float = 300

## Sets [member input] by clamping [param input_value] to ensure it can be used
## in [method physics_process].
func receive_input(input_value: Vector2) -> void:
	if input_mode == InputMode.VALUE:
		# Ensure input magnitude is not greater than 1
		_input = input_value.clamp(-Vector2.ONE, Vector2.ONE)

func _ready() -> void:
	assert(InputMap.has_action(input_forward), "%s is not defined in InputMap." % input_forward)
	assert(InputMap.has_action(input_backward), "%s is not defined in InputMap." % input_backward)
	assert(InputMap.has_action(input_left), "%s is not defined in InputMap." % input_left)
	assert(InputMap.has_action(input_right), "%s is not defined in InputMap." % input_right)

func _physics_process(delta: float) -> void:
	# Obtain input vector from the user input axises
	if input_mode == InputMode.USER:
		_input = Vector2(Input.get_axis(input_right, input_left), \
				Input.get_axis(input_backward, input_forward))
	
	var max_rads: float = deg_to_rad(max_steer)
	robot.steering = move_toward(robot.steering, _input.x * max_rads, delta * turn_speed)
	robot.engine_force = _input.y * engine_power
