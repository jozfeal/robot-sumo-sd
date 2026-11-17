class_name Robot
extends VehicleBody3D

@export_group("Nodes")
## Robot's left wheel for differential steering.
@export var left_wheel: VehicleWheel3D
## Robot's right wheel for differential steering.
@export var right_wheel: VehicleWheel3D
## Mesh for which color is changed.
@export var color_mesh: MeshInstance3D
@export_group("")

@export var robot_name: String
@export var color: Color

func _ready() -> void:
	color_mesh.material_override.albedo_color = color
