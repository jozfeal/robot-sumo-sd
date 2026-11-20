class_name Robot
extends Node3D

## How much the wheel is able to spin, essentially the torque of the motor.
@export var max_wheel_speed: float = 65.0
## The force applied by the motor.
@export var motor_max_impulse: float = 0.01

@export_group("Nodes")
## Robot's chassis body.
@export var chassis: RigidBody3D
## Robot's left wheel for differential steering.
@export var left_wheel: RigidBody3D
## Robot's right wheel for differential steering.
@export var right_wheel: RigidBody3D
## Robot's left wheel hinge.
@export var left_hinge: HingeJoint3D
## Robot's right wheel hinge.
@export var right_hinge: HingeJoint3D
## Mesh for which color is changed.
@export var color_mesh: MeshInstance3D
@export_group("")

## Color of the robot's chassis.
@export var color: Color

# List of all physics components making up the robot.
var physics_components: Array[Node3D]
# Dictionary with each component's default local transform.
var component_transforms: Dictionary

func _ready() -> void:
	color_mesh.material_override.albedo_color = color
	physics_components = [chassis, left_wheel, right_wheel, left_hinge, right_hinge]
	for component: Node3D in physics_components:
		component_transforms[component] = component.transform
	
	# Sets up hinges to work as motors
	for hinge in [left_hinge, right_hinge]:
		hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
		hinge.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, motor_max_impulse)

## Spins the wheels based on [param left] and [param right] parameters.
func set_drive(left: float, right: float) -> void:
	left_hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, -left * max_wheel_speed)
	right_hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, -right * max_wheel_speed)

## Teleports the robot to the given position.
## Use this instead of setting [member global_position].
func teleport(to: Vector3) -> void:
	global_position = to
	for component: Node3D in physics_components:
		component.transform = component_transforms[component]
	chassis.linear_velocity = Vector3.ZERO
	chassis.angular_velocity = Vector3.ZERO

## Returns global transform of the chassis, repesenting the robot's visual position.
func get_visual_transform() -> Transform3D:
	return chassis.global_transform

## Returns the linear velocity of the chassis, representing the robot's visual linear velocity.
func get_visual_linear_velocity() -> Vector3:
	return chassis.linear_velocity

## Returns the angular velocity of the chassis, representing the robot's visual linear velocity.
func get_visual_angular_velocity() -> Vector3:
	return chassis.angular_velocity

## Returns the left wheel's wheel speed.
func get_left_wheel_speed() -> float:
	return left_hinge.get_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY)

## Returns the right wheel's wheel speed.
func get_right_wheel_speed() -> float:
	return right_hinge.get_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY)
