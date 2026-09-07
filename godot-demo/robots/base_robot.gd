class_name Robot
extends VehicleBody3D

@export var robot_name: String
@export var color: Color

func _ready() -> void:
	$Body.material.albedo_color = color
