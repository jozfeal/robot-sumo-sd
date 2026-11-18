class_name Robot
extends Node3D

@export var max_wheel_speed: float = 20.0   # rad/s; ground speed = this * wheel radius
@export var motor_max_impulse: float = 0.01 # motor strength per physics step; tune this

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

@export var color: Color

func _ready() -> void:
	color_mesh.material_override.albedo_color = color
	
	for hinge in [left_hinge, right_hinge]:
		hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
		hinge.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, motor_max_impulse)

func set_drive(left: float, right: float) -> void:
	# left/right in [-1, 1]
	left_hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, -left * max_wheel_speed)
	right_hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, -right * max_wheel_speed)
