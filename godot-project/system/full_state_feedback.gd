class_name SumoStateFeedback
extends RefCounted

var red_robot: Robot
var blue_robot: Robot

var _episode_id := 0
var _step_id := 0
var _elapsed_seconds := 0.0
var _latest_state: Dictionary = {}


func _init(red: Robot, blue: Robot) -> void:
	red_robot = red
	blue_robot = blue


func start_episode(episode_id: int, red_in_ring: bool, blue_in_ring: bool) -> void:
	_episode_id = episode_id
	_step_id = 0
	_elapsed_seconds = 0.0
	_capture(red_in_ring, blue_in_ring, "running", "")


func capture_step(delta: float, red_in_ring: bool, blue_in_ring: bool, winner: String) -> void:
	_step_id += 1
	_elapsed_seconds += delta
	var status := "running" if winner.is_empty() else "terminated"
	_capture(red_in_ring, blue_in_ring, status, winner)


func get_state() -> Dictionary:
	# return a copy so callers cant change the saved robot data
	return _latest_state.duplicate(true)


func get_state_json() -> String:
	return JSON.stringify(_latest_state)


func save_state(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(_latest_state, "\t"))
	file.flush()
	var error := file.get_error()
	file.close()
	return error


func _capture(red_in_ring: bool, blue_in_ring: bool, status: String, winner: String) -> void:
	_latest_state = {
		"schema_version": 2,
		"episode_id": _episode_id,
		"step_id": _step_id,
		"elapsed_seconds": _elapsed_seconds,
		"robots": {
			"red": _read_robot(red_robot, red_in_ring),
			"blue": _read_robot(blue_robot, blue_in_ring),
		},
		"match": {
			"status": status,
			"winner": winner if not winner.is_empty() else null,
			"end_reason": "ring_exit" if status == "terminated" else "",
		},
	}


func _read_robot(robot: Robot, in_ring: bool) -> Dictionary:
	# orthonormalized() drops any scale
	var rotation := robot.global_basis.orthonormalized().get_rotation_quaternion()
	return {
		"position": _vector_array(robot.global_position),
		# x, y, z, w
		"rotation": [rotation.x, rotation.y, rotation.z, rotation.w],
		"linear_velocity": _vector_array(robot.linear_velocity),
		"angular_velocity": _vector_array(robot.angular_velocity),
		# steering lags the requested angle
		"steering": robot.steering,
		"engine_force": robot.engine_force,
		"brake": robot.brake,
		# from RingArea, same source as the win check
		"inside_ring": in_ring,
	}


func _vector_array(value: Vector3) -> Array:
	return [value.x, value.y, value.z]
