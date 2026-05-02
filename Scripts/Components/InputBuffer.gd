
extends Node
class_name InputBuffer

signal command_matched(command: Dictionary)

@export var max_buffer_frames  : int  = 12
@export var neg_edge_enabled   : bool = false
@export var debug_mode         : bool = true

const BUTTONS    : Array[String] = ["A", "B", "C", "D"]
const DIRECTIONS : Array[String] = ["1","2","3","4","6","7","8","9"]

const DIAG_TO_CARDINALS : Dictionary = {
	"1": ["1","2","4"],
	"3": ["3","2","6"],
	"7": ["7","8","4"],
	"9": ["9","8","6"],
}

const CARDINAL_RELEASE_MAP : Dictionary = {
	"2": ["1","2","3"],
	"4": ["1","4","7"],
	"6": ["3","6","9"],
	"8": ["7","8","9"],
}

const PRIORITY : Dictionary = {
	"Standing"       : 0,
	"Walking"        : 1,
	"Crouching"      : 2,
	"Dash"           : 3,
	"Jump"           : 4, 
	"Super Jump"     : 5,
	"Normal"         : 6,
	"Command Normal" : 7,
	"Guard Crush"    : 8,
	"Throw"          : 9,
	"Special"        : 10,
	"EX Special"     : 11,
	"Rapid Cancel"   : 12,
	"Ultimate Art"   : 13,
	"Burst"          : 14,
	"Barrier"        : 15,
}

var event_log     : Array = [] ## Full match event log.
var held_inputs   : Dictionary = {} ## Live held-inputs

## Commands valid for the current state. Set by State_Manager on each transition.
var command_list          : Array = []
var release_command_list  : Array = []
## Set by Fighter when it flips — used only for debug arrow display.
var facing_right  : bool  = true
## Reference to owning character node. Set by Fighter._setup_input_buffer().
var character     : Node  = null

@onready var label : Label = %Button_Label 

# -----------------------------------------------------------------------------
# Public API
# -----------------------------------------------------------------------------

## Called once per relevant input event by Fighter._capture_input().
func register_input(action: String, type: String) -> void:
	var frame : int = Engine.get_physics_frames()

	_update_held(action, type, frame)

	#Skip duplicate — same action+type already last in log
	var last = event_log.back() if not event_log.is_empty() else null
	if last == null or last["action"] != action or last["type"] != type:
		event_log.append({ "action": action, "frame": frame, "type": type })

	if label:
		label.text = _to_arrow(action)
	if debug_mode:
		print("Input: %s %s @ %d  held:%s" % [type, action, frame, held_inputs.keys()])

	# Only run command matching on button events.
	# Direction-only changes update held_inputs but don't trigger scanning.
	if action in BUTTONS:
		_match_commands(type)
	elif action in DIRECTIONS and type == "press":
		_match_commands(type)

## Replace the active command set. Called by State_Manager on every transition.
func set_commands(press_cmds: Array, release_cmds: Array = []) -> void:
	command_list         = press_cmds
	release_command_list = release_cmds

## Clear everything. Call at round start.
func reset() -> void:
	event_log.clear()
	held_inputs.clear()

# -----------------------------------------------------------------------------
# State_Base query API
# -----------------------------------------------------------------------------

## True if `btn` was pressed within the last `window` frames.
func button_pressed_within(btn: String, window: int) -> bool:
	return _find_event(btn, "press", window) != null

## True if `btn` was released within the last `window` frames.
func button_released_within(btn: String, window: int) -> bool:
	return _find_event(btn, "release", window) != null

# -----------------------------------------------------------------------------
# Held-input maintenance  (O(1) per input)
# -----------------------------------------------------------------------------

func _update_held(action: String, type: String, frame: int) -> void:
	if type == "press":
		held_inputs[action] = frame
		if action in DIAG_TO_CARDINALS:
			for cardinal in DIAG_TO_CARDINALS[action]:
				if cardinal not in held_inputs:
					held_inputs[cardinal] = frame
		if action == "5":
			for d in DIRECTIONS:
				held_inputs.erase(d)
	else:  # release
		held_inputs.erase(action)
		if action in CARDINAL_RELEASE_MAP:
			for d in CARDINAL_RELEASE_MAP[action]:
				held_inputs.erase(d)

## Called by Fighter._update_facing() only when a flip actually occurs.
## Mirrors held directional inputs across the horizontal axis so that
## "6" (forward) becomes "4" (back) and vice versa — diagonals too.
## Called after facing_right is already updated.
func flip_held_directions() -> void:
	const MIRROR : Dictionary = {
		"4": "6", "6": "4",
		"1": "3", "3": "1",
		"7": "9", "9": "7",
	}
	var to_add    : Dictionary = {}
	var to_remove : Array      = []
 
	for key in held_inputs.keys():
		if key in MIRROR:
			to_add[MIRROR[key]] = held_inputs[key]
			to_remove.append(key)
 
	for key in to_remove:
		held_inputs.erase(key)
	for key in to_add:
		held_inputs[key] = to_add[key]
 
func _any_button_held() -> bool:
	for b in BUTTONS:
		if b in held_inputs:
			return true
	return false
# -----------------------------------------------------------------------------
# Command matching
# -----------------------------------------------------------------------------

func _match_commands(type: String) -> void:
	var candidates : Array = []
	var list := release_command_list if (type == "release" and neg_edge_enabled) else command_list
	
	if type == "release" and not neg_edge_enabled:
		return

	for cmd in list:
		if   "Held"   in cmd and _check_held_command(cmd, type):
			candidates.append(cmd)
		elif "Charge" in cmd and _check_charge_command(cmd, type):
			candidates.append(cmd)
		elif _check_motion_command(cmd, type):
			candidates.append(cmd)

	_resolve(candidates)

# --- Held commands ---
# Must match sequence AND all "Held" directions are in held_inputs right now.
func _check_held_command(cmd: Dictionary, type: String) -> bool:
	var sequence : Array = cmd["Sequence"]
	var required : Array = cmd["Held"]
	var frame    : int   = Engine.get_physics_frames()

	var last = event_log.back()
	if last == null or last["action"] != sequence[-1] or last["type"] != type:
		return false
	if frame - last["frame"] > max_buffer_frames:
		return false

	for h in required:
		if h not in held_inputs:
			return false
	return true

# --- Charge commands ---
# Finds most recent valid charge hold, then matches the follow-up sequence.
func _check_charge_command(cmd: Dictionary, type: String) -> bool:
	var sequence      : Array  = cmd["Sequence"]
	var charge_dir    : String = cmd["Button"][0]
	var charge_needed : int    = cmd.get("Charge")

	# Find the most recent release of charge_dir that was held long enough
	var charge_valid          := false
	var charge_released_frame := -1

	for i in range(event_log.size() - 1, -1, -1):
		var e = event_log[i]
		if e["action"] == charge_dir and e["type"] == "release":
			charge_released_frame = e["frame"]
			for j in range(i - 1, -1, -1):
				var pe = event_log[j]
				if pe["action"] == charge_dir and pe["type"] == "press":
					if charge_released_frame - pe["frame"] >= charge_needed:
						charge_valid = true
					break
			break  # only check most recent release

	if not charge_valid:
		return false

	# Match the sequence following the charge release
	var seq_index  := sequence.size() - 1
	var prev_frame := -1
	var current    := Engine.get_physics_frames()

	for i in range(event_log.size() - 1, -1, -1):
		if seq_index < 0:
			break
		var e = event_log[i]
		var expected_type := "release" if e["action"] == charge_dir else type
		if e["action"] != sequence[seq_index] or e["type"] != expected_type:
			continue
		if prev_frame == -1:
			if current - e["frame"] > max_buffer_frames:
				return false
		else:
			if prev_frame - e["frame"] > max_buffer_frames:
				return false
		prev_frame = e["frame"]
		seq_index -= 1

	return seq_index < 0

# --- Motion commands ---
# Standard QCF, DP, HCF etc.
func _check_motion_command(cmd: Dictionary, type: String) -> bool:
	var sequence  : Array = cmd["Sequence"]
	var seq_index : int   = sequence.size() - 1
	var prev_frame: int   = -1
	var current   : int   = Engine.get_physics_frames()

	var last = event_log.back()
	if last == null or last["action"] != sequence[-1] or last["type"] != type:
		return false

	for i in range(event_log.size() - 1, -1, -1):
		if seq_index < 0:
			break
		var e = event_log[i]
		if e["action"] != sequence[seq_index] or e["type"] != type:
			continue
		if prev_frame == -1:
			if current - e["frame"] > max_buffer_frames:
				return false
		else:
			if prev_frame - e["frame"] > max_buffer_frames:
				return false
		prev_frame = e["frame"]
		seq_index -= 1

	return seq_index < 0

# -----------------------------------------------------------------------------
# Priority resolution
# -----------------------------------------------------------------------------

func _resolve(candidates: Array) -> void:
	if candidates.is_empty():
		return

	var winner    : Dictionary = candidates[0]
	var top_prio  : int        = PRIORITY.get(winner.get("Priority", ""), -1)

	for cmd in candidates.slice(1):
		var p = PRIORITY.get(cmd.get("Priority", ""), -1)
		if p > top_prio:
			winner   = cmd
			top_prio = p

	if debug_mode:
		print("Matched: %s (%s)" % [winner.get("Command","?"), winner.get("Priority","?")])

	command_matched.emit(winner)
	return

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

func _find_event(action: String, type: String, window: int):
	var cutoff := Engine.get_physics_frames() - window
	for i in range(event_log.size() - 1, -1, -1):
		var e = event_log[i]
		if e["frame"] < cutoff:
			break
		if e["action"] == action and e["type"] == type:
			return e
	return null

func _to_arrow(action: String) -> String:
	var r := {"1":"🢇","2":"🢃","3":"🢆","4":"🢀","5":"·","6":"🢂","7":"🢄","8":"🢁","9":"🢅"}
	var l := {"1":"🢆","2":"🢃","3":"🢇","4":"🢂","5":"·","6":"🢀","7":"🢅","8":"🢁","9":"🢄"}
	return (r if facing_right else l).get(action, action)
