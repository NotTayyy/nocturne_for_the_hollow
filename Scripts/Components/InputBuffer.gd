extends Node
class_name InputBuffer

@export var max_buffer_frames: int = 30

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
	
	check_commands()

func clear():
	buffer_history.clear()

func check_commands():
	if buffer_history.is_empty():
		return
	print_buffer()

	var last_entry = buffer_history[-1]
	
	if last_entry["type"] == "press":
		check_Command_list("press", command_list)
	elif last_entry["type"] == "release" and release_command_list != null:
		check_Command_list("release", release_command_list)

#Bug I Dont know if it was here but Holding 1 then holding 3 wont cancel out 4 and 6
#Bug When Canceling 4 AND 6 OR 8 And 2 it will not register a release. Just a press of 5

func check_held_inputs() -> Array:
	var held_inputs:= {}
	var directions := ["2", "4", "6", "8", "1", "3", "7", "9"]
	var buttons:= ["A", "B", "C", "D"]
	var direction_map:= {
		"1": ["1", "2", "4"],
		"3": ["3", "2", "6"],
		"7": ["7", "8", "4"],
		"9": ["9", "8", "6"],
	}
	var release_map:= {
		"2": ["1", "2", "3"],
		"4": ["1", "4", "7"],
		"8": ["7", "8", "9"],
		"6": ["9", "6", "3"],
	}

	for entry in buffer_history:
		var Inputs = direction_map.get(entry.action, [entry.action])
		var release = release_map.get(entry.action, [entry.action])
		for key in Inputs:
			if key == "5" and entry["type"] == "press":
				held_inputs.clear()
			if key in directions or key in buttons:
				if entry["type"] == "press":
					held_inputs[key] = true
				if entry["type"] == "release":
					for btn in release:
						held_inputs.erase(btn)
	
	return held_inputs.keys()

func check_Command_list(type, cmd_list: Array):
	var held_inputs = check_held_inputs()
	var matched_commands: Array = []
	print(held_inputs)
	
	for command in cmd_list:
		var sequence: Array = command["Sequence"]
		var priority: int = command["Priority"]
		var seq_index: int = sequence.size() - 1
		var prev_frame: int = -1
		var starter: Dictionary = buffer_history[-1]
		var charge: int
		
		#Checks Only The Command Normals
		if "Held" in command:
			for i in range(buffer_history.size() - 1, -1, -1):
				if seq_index < 0:
					break
				
				var entry = buffer_history[i]
				if starter["action"] == sequence[-1]:
					if current_frame - starter["action_frame"] < max_buffer_frames: 
						if entry["action"] == sequence[seq_index] and entry["type"] == type:
							seq_index -= 1
							if seq_index == -1:
								for held_input in command["Held"]:
									#Fixed Bug(Diagonals Would make this run)
									if held_inputs.has(held_input):
										matched_commands.append(command)
								break
		
		#Checks only the Charge Based Commands
		elif "Charge" in command:
			var charge_btn: String  = command["Button"][0]
			var charge_frames: int = command["Charge"]
			var charge_met: bool = false
					
			for i in range(buffer_history.size() - 1, -1, -1):
				var release_entry = buffer_history[i]
				if release_entry["action"] == charge_btn and release_entry["type"] == "release":
					# Step 2: Find matching press before that release
					for j in range(i - 1, -1, -1):
						var press_entry = buffer_history[j]
						if press_entry["action"] == charge_btn and press_entry["type"] == "press":
							var held_frames = release_entry["action_frame"] - press_entry["action_frame"]
							if held_frames >= charge_frames:
								charge_met = true
							break
					break
				
			if not charge_met:
				continue
				
			for i in range(buffer_history.size() -1, -1, -1):
				if seq_index < 0:
					break
				
				var entry = buffer_history[i]
				if entry["action"] == sequence[seq_index]:
					# If this is the charge button, expect a RELEASE
					if sequence[seq_index] == charge_btn:
						if entry["type"] != "release":
							continue
						if prev_frame - entry["action_frame"] > max_buffer_frames:
							break
					else:
						if entry["type"] != type:
							continue
						if prev_frame == -1:
							if current_frame - entry["action_frame"] > max_buffer_frames:
								break
						else:
							if prev_frame - entry["action_frame"] > max_buffer_frames:
								break
						prev_frame = entry["action_frame"]
						
					seq_index -= 1
				if seq_index == -1:
					matched_commands.append(command)
		
		#Checks only the leftover Commands.
		else: 
			for i in range(buffer_history.size() - 1, -1, -1):
				if seq_index < 0:
					break
					
				var entry = buffer_history[i]
				if starter["action"] == sequence[-1]:
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

#We need to make a list of possible actions during any given state
#Then relate the possible actions to the ones that were possibly inputted and only compare
#Priorities for the possible ones
	if matched_commands.size() == 1:
		print(matched_commands[0]["Command"])
		return
	elif matched_commands.size() > 1:
		var curr_priority: int = -1
		var curr_command = null
		for entry in matched_commands:
			if entry["Priority"] > curr_priority:
				curr_command = entry
				curr_priority = entry["Priority"]
		print(matched_commands)
		print(curr_command["Command"])
		return

func print_buffer():
	var entry = buffer_history[-1]
	print("Action: ", entry["type"], " : ", entry["action"], " at frame ", entry["action_frame"])

func _physics_process(_delta: float) -> void:
	pass
