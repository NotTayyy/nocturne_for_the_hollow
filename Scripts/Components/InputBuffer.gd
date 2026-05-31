# =============================================================================
# InputBuffer.gd
# Match-long event log + per-frame staged input + command matching.
#
# Flow per tick:
#   InputBuffer._physics_process() reads raw hardware each frame (ALWAYS mode)
#   → stages direction and button events
#   State_Manager.tick() calls flush_staged() at end of frame
#   → combo/motion/charge/held matching runs on staged inputs
#   → command_matched fires
#   → buffered command attempted
#   → _staged_this_frame cleared
# =============================================================================
extends Node
class_name InputBuffer

# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------
signal command_matched(command: Dictionary)

# -----------------------------------------------------------------------------
# Exports
# -----------------------------------------------------------------------------
@export var max_buffer_frames : int  = 12
@export var debug_mode        : bool = true

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
const BUTTONS    : Array[String] = ["A", "B", "C", "D"]
const DIRECTIONS : Array[String] = ["1","2","3","4","5","6","7","8","9"]

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
	"Throw"          : 8,
	"Guard Break"    : 9,
	"Special"        : 10,
	"EX Special"     : 11,
	"Rapid Cancel"   : 12,
	"Ultimate Art"   : 13,
	"Burst"          : 14,
	"Barrier"        : 15,
}

## Input buffer window — frames a matched command stays buffered
@export var BUFFER_WINDOW : int = 12

# -----------------------------------------------------------------------------
# Runtime state
# -----------------------------------------------------------------------------

## Full match event log — append only, cleared on reset()
## Entry: { "action": String, "frame": int, "type": "press"|"release" }
var event_log    : Array = []

## Live held-input set — O(1) lookup, maintained incrementally
var held_inputs  : Dictionary = {}

## Current frame's staged inputs — cleared each flush_staged()
## Entry: { "action": String, "type": "press"|"release" }
var _staged_this_frame : Array = []

## Buffered command — last matched command kept for BUFFER_WINDOW frames
var _buffered_command       : Dictionary = {}
var _buffered_command_frame : int        = -1

## Commands registered by current state
var command_list         : Array = []
var release_command_list : Array = []

var facing_right     : bool    = true
var character        : Fighter = null
var neg_edge_enabled : bool    = false

# Action strings — set via setup_actions()
var _action_left  : String = ""
var _action_right : String = ""
var _action_up    : String = ""
var _action_down  : String = ""
var _action_a     : String = ""
var _action_b     : String = ""
var _action_c     : String = ""
var _action_d     : String = ""

@onready var label : Label = %Button_Label

# -----------------------------------------------------------------------------
# Setup
# -----------------------------------------------------------------------------

func _ready() -> void:
	# Always run so input is captured even during hitstop
	process_mode = Node.PROCESS_MODE_ALWAYS

## Called by Fighter._setup_input_buffer() — stores action strings and character ref
func setup_actions(player_id: int) -> void:
	var p      := "P%d_" % player_id
	_action_left  = p + "Left"
	_action_right = p + "Right"
	_action_up    = p + "Up"
	_action_down  = p + "Down"
	_action_a     = p + "Btn_A"
	_action_b     = p + "Btn_B"
	_action_c     = p + "Btn_C"
	_action_d     = p + "Btn_D"

# -----------------------------------------------------------------------------
# Input reading — always runs, owns all hardware input staging
# -----------------------------------------------------------------------------

var _flushed_this_frame : bool = false

func _physics_process(_delta: float) -> void:
	_flushed_this_frame = false
	if _action_left == "":
		return
	_stage_input()

func _stage_input() -> void:
	var current_directions : Array = []
	for action in [_action_left, _action_right, _action_up, _action_down]:
		if Input.is_action_pressed(action):
			current_directions.append(action)

	# Direction just pressed — release previous numpad, press new
	for action in [_action_left, _action_right, _action_up, _action_down]:
		if Input.is_action_just_pressed(action):
			var prev := _held_to_numpad(current_directions.filter(func(a): return a != action))
			var curr := _held_to_numpad(current_directions)
			if prev != curr:
				stage(prev, "release")
			stage(curr, "press")
			break

	# Direction just released — release it, re-register what remains
	for action in [_action_left, _action_right, _action_up, _action_down]:
		if Input.is_action_just_released(action):
			var released_dir := _held_to_numpad([action])
			if released_dir != "":
				stage(released_dir, "release")
			current_directions = []
			for a in [_action_left, _action_right, _action_up, _action_down]:
				if Input.is_action_pressed(a):
					current_directions.append(a)
			var remaining := _held_to_numpad(current_directions)
			stage(remaining, "press")
			break

	# Buttons — each independent
	for pair in [[_action_a,"A"],[_action_b,"B"],[_action_c,"C"],[_action_d,"D"]]:
		if   Input.is_action_just_pressed(pair[0]):
			stage(pair[1], "press")
		elif Input.is_action_just_released(pair[0]):
			stage(pair[1], "release")

	# During hitstop, match immediately so commands get buffered
	if character != null and character.process_mode == Node.PROCESS_MODE_DISABLED:
		if not _flushed_this_frame:
			flush_staged()

## Converts held action strings to numpad notation
func _held_to_numpad(held: Array) -> String:
	var v := ""
	var h := ""

	if _action_up in held and _action_down in held:
		v = ""
	elif _action_up in held:
		v = "8"
	elif _action_down in held:
		v = "2"

	if _action_left in held and _action_right in held:
		h = ""
	elif facing_right:
		if   _action_left  in held: h = "4"
		elif _action_right in held: h = "6"
	else:
		if   _action_left  in held: h = "6"
		elif _action_right in held: h = "4"

	if   v == "8" and h == "4": return "7"
	elif v == "8" and h == "6": return "9"
	elif v == "2" and h == "4": return "1"
	elif v == "2" and h == "6": return "3"
	elif v != "":                return v
	elif h != "":                return h
	return "5"

# -----------------------------------------------------------------------------
# Public API
# -----------------------------------------------------------------------------

## Appends a hardware event to the log and staged list
func stage(action: String, type: String) -> void:
	var frame := Engine.get_physics_frames()

	_update_held(action, type, frame)

	var last = event_log.back() if not event_log.is_empty() else null
	if last == null or last["action"] != action or last["type"] != type:
		event_log.append({ "action": action, "frame": frame, "type": type })

	_staged_this_frame.append({ "action": action, "type": type })

	if label:
		label.text = _to_arrow(action)

## Called by State_Manager.tick() at end of frame.
func flush_staged() -> void:
	_flushed_this_frame = true
	if _staged_this_frame.is_empty():
		_try_buffered_command()
		return

	var pressed_this_frame  : Array[String] = []
	var released_this_frame : Array[String] = []

	for entry in _staged_this_frame:
		if entry["type"] == "press":
			pressed_this_frame.append(entry["action"])
		else:
			released_this_frame.append(entry["action"])

	if not pressed_this_frame.is_empty():
		_match_commands("press", pressed_this_frame)

	if neg_edge_enabled and not released_this_frame.is_empty():
		_match_commands("release", released_this_frame)

	_try_buffered_command()
	_staged_this_frame.clear()

## Called by State_Manager when a command successfully executes.
func consume_buffer() -> void:
	_buffered_command       = {}
	_buffered_command_frame = -1

## Replace active command set — called by State_Manager on transition.
func set_commands(press_cmds: Array, release_cmds: Array = []) -> void:
	command_list         = press_cmds
	release_command_list = release_cmds

## Clear everything — call at round start.
func reset() -> void:
	event_log.clear()
	held_inputs.clear()
	_staged_this_frame.clear()
	_buffered_command       = {}
	_buffered_command_frame = -1

## Called by Fighter.update_facing() when character flips.
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

# -----------------------------------------------------------------------------
# State query API
# -----------------------------------------------------------------------------
func button_pressed_within(btn: String, window: int) -> bool:
	return _find_event(btn, "press", window) != null

func button_released_within(btn: String, window: int) -> bool:
	return _find_event(btn, "release", window) != null

# -----------------------------------------------------------------------------
# Held-input maintenance
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
	else:
		held_inputs.erase(action)
		if action in CARDINAL_RELEASE_MAP:
			for d in CARDINAL_RELEASE_MAP[action]:
				held_inputs.erase(d)

func _any_button_held() -> bool:
	for b in BUTTONS:
		if b in held_inputs: return true
	return false

# -----------------------------------------------------------------------------
# Command matching
# -----------------------------------------------------------------------------
func _match_commands(type: String, inputs_this_frame: Array) -> void:
	var candidates : Array = []
	var list := release_command_list if (type == "release" and neg_edge_enabled) \
		else command_list

	for cmd in list:
		if   "Held"   in cmd and _check_held_command(cmd, type):
			candidates.append(cmd)
		elif "Charge" in cmd and _check_charge_command(cmd, type):
			candidates.append(cmd)
		elif "Combo"  in cmd and _check_combo_command(cmd, inputs_this_frame):
			candidates.append(cmd)
		elif "Held" not in cmd and "Charge" not in cmd and "Combo" not in cmd \
			 and _check_motion_command(cmd, type):
			candidates.append(cmd)

	_resolve(candidates)

func _check_held_command(cmd: Dictionary, type: String) -> bool:
	var sequence : Array = cmd["Sequence"]
	var required : Array = cmd["Held"]
	var frame    : int   = Engine.get_physics_frames()
	var last             = event_log.back()
	if last == null or last["action"] != sequence[-1] or last["type"] != type:
		return false
	if frame - last["frame"] > max_buffer_frames:
		return false
	for h in required:
		if h not in held_inputs:
			return false
	return true

func _check_charge_command(cmd: Dictionary, type: String) -> bool:
	var sequence      : Array  = cmd["Sequence"]
	var charge_dir    : String = cmd["Button"][0]
	var charge_needed : int    = cmd["Charge"]

	var charge_valid          := false
	var charge_released_frame := -1

	for i in range(event_log.size() - 1, -1, -1):
		var e = event_log[i]
		if e["action"] == charge_dir and e["type"] == "release":
			charge_released_frame = e["frame"]
			var interrupted := false
			for j in range(i - 1, -1, -1):
				var pe = event_log[j]
				if pe["action"] == charge_dir:
					if pe["type"] == "press":
						if charge_released_frame - pe["frame"] >= charge_needed:
							charge_valid = true
					else:
						interrupted = true
					break
			if interrupted:
				continue
			break

	if not charge_valid:
		return false

	var seq_index  := sequence.size() - 1
	var prev_frame := -1
	var current    := Engine.get_physics_frames()

	for i in range(event_log.size() - 1, -1, -1):
		if seq_index < 0: break
		var e = event_log[i]
		var expected_type := "release" if e["action"] == charge_dir else type
		if e["action"] != sequence[seq_index] or e["type"] != expected_type:
			continue
		if prev_frame == -1:
			if current - e["frame"] > max_buffer_frames: return false
		else:
			if prev_frame - e["frame"] > max_buffer_frames: return false
		prev_frame = e["frame"]
		seq_index -= 1

	return seq_index < 0

func _check_combo_command(cmd: Dictionary, inputs_this_frame: Array) -> bool:
	var sequence : Array = cmd["Sequence"]

	# Split sequence into directions (must be held) and buttons (must be pressed this frame)
	var required_dirs    : Array[String] = []
	var required_buttons : Array[String] = []
	for entry in sequence:
		if entry in DIRECTIONS:
			required_dirs.append(entry)
		else:
			required_buttons.append(entry)

	# Check all required directions are currently held
	for dir in required_dirs:
		if dir not in held_inputs:
			return false

	# Check all required buttons were pressed this frame
	for btn in required_buttons:
		if btn not in inputs_this_frame:
			return false

	return true

func _check_motion_command(cmd: Dictionary, type: String) -> bool:
	var sequence  : Array = cmd["Sequence"]
	var seq_index : int   = sequence.size() - 1
	var prev_frame: int   = -1
	var current   : int   = Engine.get_physics_frames()

	var last = event_log.back()
	if last == null or last["type"] != type:
		return false

	if sequence.size() == 1:
		var valid = CARDINAL_RELEASE_MAP.get(sequence[-1], [sequence[-1]])
		if last["action"] not in valid:
			return false
	else:
		if last["action"] != sequence[-1]:
			return false

	for i in range(event_log.size() - 1, -1, -1):
		if seq_index < 0: break
		var e = event_log[i]
		if e["action"] != sequence[seq_index] or e["type"] != type:
			continue
		if prev_frame == -1:
			if current - e["frame"] > max_buffer_frames: return false
		else:
			if prev_frame - e["frame"] > max_buffer_frames: return false
		prev_frame = e["frame"]
		seq_index -= 1

	return seq_index < 0

# -----------------------------------------------------------------------------
# Priority resolution
# -----------------------------------------------------------------------------
func _resolve(candidates: Array) -> void:
	if candidates.is_empty():
		return

	var winner     : Dictionary = candidates[0]
	var top_prio   : int        = PRIORITY.get(winner.get("Priority", ""), -1)
	var top_spec   : int        = _held_specificity(winner)

	for cmd in candidates.slice(1):
		var p    : int = PRIORITY.get(cmd.get("Priority", ""), -1)
		var spec : int = _held_specificity(cmd)
		if p > top_prio or (p == top_prio and spec > top_spec):
			winner   = cmd
			top_prio = p
			top_spec = spec

	_buffered_command       = winner
	_buffered_command_frame = Engine.get_physics_frames()

	if character != null and character.process_mode == Node.PROCESS_MODE_DISABLED:
		return
	command_matched.emit(winner)

## Specificity score for tiebreaking equal-priority held commands.
## Down beats back when holding a down-diagonal (1 or 3).
## Up beats back when holding an up-diagonal (7 or 9).
## Diagonal exact match beats cardinal expansion.
func _held_specificity(cmd: Dictionary) -> int:
	if "Held" not in cmd:
		return 0
	var score : int = 0
	for h in cmd["Held"]:
		if h in ["1","3","7","9"] and h in held_inputs:
			score += 3   # exact diagonal match
		elif h == "2" and ("1" in held_inputs or "3" in held_inputs):
			score += 2   # down preferred on down-diagonal
		elif h == "8" and ("7" in held_inputs or "9" in held_inputs):
			score += 2   # up preferred on up-diagonal
		elif h in held_inputs:
			score += 1   # plain cardinal match
	return score

# -----------------------------------------------------------------------------
# Buffered command
# -----------------------------------------------------------------------------
func _try_buffered_command() -> void:
	if _buffered_command.is_empty():
		return
	if character != null and character.process_mode == Node.PROCESS_MODE_DISABLED:
		return
	var age := Engine.get_physics_frames() - _buffered_command_frame
	if age > BUFFER_WINDOW:
		_buffered_command       = {}
		_buffered_command_frame = -1
		return
	# Barrier is sustained by held inputs — only emit once on the frame it was matched
	# Re-emission would cause it to toggle, _tick_barrier_held handles sustaining it
	if _buffered_command.get("Command", "") == "Barrier":
		return
	command_matched.emit(_buffered_command)

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
func _find_event(action: String, type: String, window: int):
	var cutoff := Engine.get_physics_frames() - window
	for i in range(event_log.size() - 1, -1, -1):
		var e = event_log[i]
		if e["frame"] < cutoff: break
		if e["action"] == action and e["type"] == type: return e
	return null

func _to_arrow(action: String) -> String:
	var r := {"1":"🢇","2":"🢃","3":"🢆","4":"🢀","5":"·","6":"🢂","7":"🢄","8":"🢁","9":"🢅"}
	var l := {"1":"🢆","2":"🢃","3":"🢇","4":"🢂","5":"·","6":"🢀","7":"🢅","8":"🢁","9":"🢄"}
	return (r if facing_right else l).get(action, action)
