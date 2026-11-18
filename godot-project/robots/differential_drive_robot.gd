class_name DiffDriveRobot
extends Node3D

@export var max_wheel_speed: float = 20.0   # rad/s; ground speed = this * wheel radius
@export var motor_max_impulse: float = 0.01 # motor strength per physics step; tune this

@onready var chassis: RigidBody3D = $Chassis
@onready var left_wheel: RigidBody3D = $LeftWheel
@onready var right_wheel: RigidBody3D = $RightWheel
@onready var left_hinge: HingeJoint3D = $LeftHinge
@onready var right_hinge: HingeJoint3D = $RightHinge

func _ready() -> void:
	for hinge in [left_hinge, right_hinge]:
		hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
		hinge.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, motor_max_impulse)

func set_drive(left: float, right: float) -> void:
	# left/right in [-1, 1]
	left_hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, -left * max_wheel_speed)
	right_hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, -right * max_wheel_speed)
