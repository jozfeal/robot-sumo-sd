class_name SimulationManager
extends Node

@export_group("Physics Nodes")
@export var pnodes: Array[Node]

func _physics_process(delta: float) -> void:
	for node: Node in pnodes:
		if node.has_method("physics_step"):
			node.physics_step(delta)

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
