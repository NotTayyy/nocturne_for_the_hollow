extends Node
class_name InputBuffer

const _Max_Buffer_Length := 30

var buffer: Array = []

func push_input(action: String, input_type: String) -> void:
	var frame = Engine.get_physics_frames()
	buffer.append({
		"action": action,
		"frame": frame,
		"type": input_type
	})
	
	while buffer.size() > 1000:
		buffer.pop_front()

func get_recent_inputs(legal_frames: int = 10) -> Array:
	var current_frame = Engine.get_physics_frames()
	return buffer.filter(func(entry): return current_frame - entry.frame <= legal_frames)

func clear_buffer():
	buffer.clear()
