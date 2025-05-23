extends Node
class_name InputBuffer

@export var max_buffer_length : int = 10
@export var buffer_limit : int = 10

var current_frame = 0

var buffer_history: Array = []

func register_input(action: String, type: String) -> void:
	current_frame = Engine.get_physics_frames()
	
	#Check If Diagonal
	
	
	buffer_history.append({
		"action": action,
		"action_frame": current_frame,
		"type": type
	})
	
	while buffer_history.size() > max_buffer_length:
		buffer_history.remove_at(0)

	check_commands()
	print_buffer()

func clear():
	buffer_history.clear()

func check_commands():
	pass

func print_buffer():
	if buffer_history != []:
		var entry = buffer_history[-1]
		print("Action: ", entry["type"], " : ", entry["action"], " at frame ", entry["action_frame"])

func _physics_process(delta: float) -> void:

	pass

#[{ "action": "P1_Down", "action_frame": 955, "type": "press" },
 #{ "action": "P1_Right", "action_frame": 960, "type": "press" },
 #{ "action": "P1_Down", "action_frame": 962, "type": "release" },
 #{ "action": "P1_Right", "action_frame": 967, "type": "release" },
 #{ "action": "P1_Down", "action_frame": 1087, "type": "press" },
 #{ "action": "P1_Right", "action_frame": 1091, "type": "press" },
 #{ "action": "P1_Down", "action_frame": 1092, "type": "release" },
 #{ "action": "P1_Right", "action_frame": 1097, "type": "release" },
 #{ "action": "P1_Btn_A", "action_frame": 1098, "type": "press" },
 #{ "action": "P1_Btn_A", "action_frame": 1105, "type": "release" }]



func check_input(action: String, type: String, frame_limit: int = buffer_limit) -> bool:
	for entry in buffer_history:
		if entry.action == action and entry.type == type and current_frame - entry.action_frame <= frame_limit:
			return true
	return false

func get_sequence(types: Array = ["press", "release"]) -> Array:
	return buffer_history.filter(func(entry):
		return current_frame - entry.action_frame <= buffer_limit and entry.type in types
	).map(func(entry): return entry.action + ":" + entry.type)
	
