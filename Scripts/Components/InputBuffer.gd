extends Node
class_name InputBuffer

@export var max_buffer_frames: int = 15

var current_frame = 0

var buffer_history: Array = []

var command_list = [
	{ "Command": "Forward Dash", "Sequence": ["6", "5", "6"], "Priority": "1" },
	{ "Command": "Backwards Dash", "Sequence": ["4", "5", "4"], "Priority": "1" },
	{ "Command": "Universal Anti-Air", "Sequence": ["6", "A"], "Priority": "1", "Held": ["6"]}
]

var release_command_list = [
	{ "Command": "Negative A", "Sequence": ["A"], "Priority": "1", "Charge": 15 },
	{ "Command": "Flash Kick A", "Sequence": ["2", "8", "A"], "Priority": "2", "Charge": 15}
]

func register_input(action: String, type: String) -> void:
	current_frame = Engine.get_physics_frames()
	
	buffer_history.append({
		"action": action,
		"action_frame": current_frame,
		"type": type
	})
	
	print_buffer()
	check_commands()


func clear():
	buffer_history.clear()

func check_commands():
	if buffer_history.is_empty():
		return
	
	var last_entry = buffer_history[-1]
	
	if last_entry["type"] == "press":
		check_Command_list(last_entry["type"], command_list)
	elif last_entry["type"] == "release":
		check_Command_list(last_entry["type"], release_command_list)

func check_held_inputs() -> Array:
	var held_inputs:= {}
	var direction_map:= {
		"1": ["2", "4"],
		"3": ["2", "6"],
		"7": ["8", "4"],
		"9": ["8", "6"]
	}
	var directions := ["2", "4", "6", "8"]
	var buttons:= ["A", "B", "C", "D"]
	
	for entry in buffer_history:
		var keys = direction_map.get(entry.action, [entry.action])
		for key in keys:
			if key in directions or key in buttons:
				if entry["type"] == "press":
					held_inputs[key] = true
				if entry["type"] == "release":
					held_inputs.erase(key)
	
	#var direction_held := false
	#for dir in directions:
		#if held_inputs.has(dir):
			#direction_held = true
			#break
	#
	#if not direction_held:
		#held_inputs["5"] =  true
	if held_inputs != {}:
		print(held_inputs)
	return held_inputs.keys()

func check_Command_list(type, cmd_list: Array):
	var held_inputs = check_held_inputs()
	var matched_commands: Array = []
	for command in cmd_list:
		var sequence = command["Sequence"]
		var priority = command["Priority"]
		var seq_index = sequence.size() - 1
		var prev_frame: int = -1
		var match_buffer = []

		for i in range(buffer_history.size() - 1, -1, -1):
			var entry = buffer_history[i]
			if entry["action"] == sequence[seq_index] and entry["type"] == type:
				if prev_frame == -1:
					if current_frame - entry["action_frame"] > max_buffer_frames:
						break
					prev_frame = entry["action_frame"]
				else:
					if prev_frame - entry["action_frame"] > max_buffer_frames:
						break
					else:
						prev_frame = entry["action_frame"]
				
				seq_index -= 1
				print(seq_index)
				if seq_index == -1:
					matched_commands.append(command["Command"])
					break
	
	if matched_commands != []:
		print(matched_commands)	
		return

func print_buffer():
	var entry = buffer_history[-1]
	print("Action: ", entry["type"], " : ", entry["action"], " at frame ", entry["action_frame"])

func _physics_process(_delta: float) -> void:
	pass
