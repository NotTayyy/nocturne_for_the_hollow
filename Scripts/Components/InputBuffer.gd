extends Node
class_name InputBuffer

@export var max_buffer_frames: int = 25

var current_frame = 0

var buffer_history: Array = []
var has_neg_edge: bool = false

var release_command_list
var command_list 

func _ready() -> void:
		await get_tree().process_frame

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
		check_Command_list("press", command_list)
	elif last_entry["type"] == "release" and release_command_list != null:
		check_Command_list("release", release_command_list)

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
					#BUG: If you Hold 4, then Hold 6, 4 Will still count as being held, Fix this
	return held_inputs.keys()

func check_Command_list(type, cmd_list: Array):
	var held_inputs = check_held_inputs()
	var matched_commands: Array = []
	for command in cmd_list:
		var sequence = command["Sequence"]
		var priority = command["Priority"]
		var seq_index = sequence.size() - 1
		var prev_frame: int = -1
		var starter = buffer_history[-1]
		
		#Checks Only The Command Normals
		if "Held" in command:
			for i in range(buffer_history.size() - 1, -1, -1):
				if seq_index < 0:
					break
					
				var entry = buffer_history[i]
				if starter["action"] == sequence[-1]:
					if entry["action"] == sequence[seq_index] and entry["type"] == type:
						if current_frame - starter["action_frame"] < max_buffer_frames: 
							seq_index -= 1
							if seq_index == -1:
								for held_input in command["Held"]:
									if held_inputs.has(held_input):
										matched_commands.append(command)
								break	
		#Checks only the Charge Based Commands
		#if "Charge" in command:
			#var charge_Btn = command["Button"]
			#var charge_Frames = command["Charge"]
			#for i in range(buffer_history.size() - 1, -1, -1):
				#var entry = buffer_history[i]
				#if starter["action"] == sequence[-1]:
					#if entry["action"] == sequence[seq_index] and entry["type"] == type:
						#if current_frame - entry
		#Checks only the leftover Commands.
		else: 
			for i in range(buffer_history.size() - 1, -1, -1):
				if seq_index < 0:
					break
					
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
				if seq_index == -1:
					matched_commands.append(command)
					break

	if matched_commands.size() == 1:
		print(matched_commands[0]["Command"])
		return
	elif matched_commands.size() > 1:
		var curr_priority: int = -1
		var curr_command = null
		print(matched_commands)
		for entry in matched_commands:
			if entry["Priority"] > curr_priority:
				curr_command = entry
				curr_priority = entry["Priority"]
		print(curr_command["Command"])
		return
		
		

func print_buffer():
	var entry = buffer_history[-1]
	print("Action: ", entry["type"], " : ", entry["action"], " at frame ", entry["action_frame"])

func _physics_process(_delta: float) -> void:
	pass
