extends Node
class_name InputBuffer

@export var max_buffer_length : int = 6
@export var buffer_limit : int = 10

var current_frame = 0

var buffer_history: Array = []

func register_input(char_name: String, action: String, type: String) -> void:
	buffer_history.append({
		"name": char_name,
		"action": action,
		"action_frame": current_frame,
		"type": type
	})
	
	while buffer_history.size() > max_buffer_length:
		buffer_history.remove_at(0)

func check_input(action: String, type: String, frame_limit: int = buffer_limit) -> bool:
	for entry in buffer_history:
		if entry.action == action and entry.type == type and current_frame - entry.action_frame <= frame_limit:
			return true
	return false


func clear():
	buffer_history.clear()

func get_sequence(types: Array = ["press", "release"]) -> Array:
	return buffer_history.filter(func(entry):
		return current_frame - entry.action_frame <= buffer_limit and entry.type in types
	).map(func(entry): return entry.action + ":" + entry.type)
	
func print_buffer():
	#print("Buffer: ", get_sequence(), " ", buffer_history.size())
	pass
	
#func check_buffer() -> String:
	#for entry in range(buffer_history.size() -1, -1, -1):
		#if entry.action
#

func _physics_process(delta: float) -> void:
	current_frame = Engine.get_physics_frames()
	#print_buffer()
	print(buffer_history)
