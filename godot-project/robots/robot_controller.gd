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
## Only in effect if [member input_mode] is set to [enum InputMode.USER].
@export var input_left_fwd: String = "left_fwd"
## Must be defined in Input Map.
## Only in effect if [member input_mode] is set to [enum InputMode.USER].
@export var input_left_bwd: String = "left_bwd"
## Must be defined in Input Map.
## Only in effect if [member input_mode] is set to [enum InputMode.USER].
@export var input_right_fwd: String = "right_fwd"
## Must be defined in Input Map.
## Only in effect if [member input_mode] is set to [enum InputMode.USER].
@export var input_right_bwd: String = "right_bwd"

@export_group("Nodes")
## Robot that this controller is assigned to.
@export var robot: Robot
@export_group("")

# Current input values to process in _physics_process.
# X corresponds to left wheel throttle, Y corresponds to right wheel throttle.
var _input: Vector2 = Vector2.ZERO

## Maximum degrees in degrees the steering wheels are able to turn.
@export var max_steer: float = 45
## How fast the steering wheels turn.
@export var turn_speed: float = 2.5
## How much force is applied by accelerating.
@export var engine_power: float = 300

## Maximum force a wheel can output.
@export var max_wheel_force: float = 2.0

## Sets [member input] by clamping [param input_value] to ensure it can be used
## in [method physics_process].
func receive_input(input_value: Vector2) -> void:
	if input_mode == InputMode.VALUE:
		# Ensure input magnitude is not greater than 1
		_input = input_value.clamp(-Vector2.ONE, Vector2.ONE)

func _ready() -> void:
	if input_mode == InputMode.USER:
		assert(InputMap.has_action(input_left_fwd), "%s is not defined in InputMap." % input_left_fwd)
		assert(InputMap.has_action(input_left_bwd), "%s is not defined in InputMap." % input_left_bwd)
		assert(InputMap.has_action(input_right_fwd), "%s is not defined in InputMap." % input_right_fwd)
		assert(InputMap.has_action(input_right_bwd), "%s is not defined in InputMap." % input_right_bwd)

func _physics_process(_delta: float) -> void:
	# Obtain input vector from the user input axises
	if input_mode == InputMode.USER:
		_input = Vector2(Input.get_axis(input_left_fwd, input_left_bwd), \
				Input.get_axis(input_right_fwd, input_right_bwd))
	
	robot.set_drive(_input.x, _input.y)
