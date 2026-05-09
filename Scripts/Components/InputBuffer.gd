# =============================================================================
# InputBuffer.gd
# Match-long event log + per-frame staged input + command matching.
#
# Flow per tick:
#   Fighter._stage_input() calls stage() for each hardware event
#   → appended to event_log (permanent) and _staged_this_frame (temp)
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
@export var max_buffer_frames  : int  = 12
@export var debug_mode         : bool = true

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
	"Guard Crush"    : 8,
	"Throw"          : 9,
	"Special"        : 10,
	"EX Special"     : 11,
	"Rapid Cancel"   : 12,
	"Ultimate Art"   : 13,
	"Burst"          : 14,
	"Barrier"        : 15,
}

## Input buffer window — frames a matched command stays buffered
@export var BUFFER_WINDOW : int = 8

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

var facing_right : bool = true
var character    : Node = null
var neg_edge_enabled   : bool = false

@onready var label : Label = %Button_Label

# -----------------------------------------------------------------------------
# Public API — called by Fighter
# -----------------------------------------------------------------------------

## Called by Fighter._stage_input() for every hardware event this frame.
## Appends to event_log AND _staged_this_frame. Does NOT run matching yet.
func stage(action: String, type: String) -> void:
	var frame := Engine.get_physics_frames()

	# Update held_inputs
	_update_held(action, type, frame)

	# Append to permanent log (skip duplicates)
	var last = event_log.back() if not event_log.is_empty() else null
	if last == null or last["action"] != action or last["type"] != type:
		event_log.append({ "action": action, "frame": frame, "type": type })

	# Append to this frame's staged list
	_staged_this_frame.append({ "action": action, "type": type })

	if label:
		label.text = _to_arrow(action)
	if debug_mode:
		print("Staged: %s %s @ %d  held:%s" % [type, action, frame, held_inputs.keys()])

## Called by State_Manager.tick() at end of frame.
## Runs all command matching against staged inputs, fires command_matched,
## attempts buffered command, then clears staged list.
func flush_staged() -> void:
	if _staged_this_frame.is_empty():
		_try_buffered_command()
		return

	# Collect what happened this frame
	var pressed_this_frame  : Array[String] = []
	var released_this_frame : Array[String] = []

	for entry in _staged_this_frame:
		if entry["type"] == "press":
			pressed_this_frame.append(entry["action"])
		else:
			released_this_frame.append(entry["action"])

	# Run matching for press events
	if not pressed_this_frame.is_empty():
		_match_commands("press", pressed_this_frame)

	# Run matching for release events (negative edge)
	if neg_edge_enabled and not released_this_frame.is_empty():
		_match_commands("release", released_this_frame)

	# Attempt buffered command from previous frames
	_try_buffered_command()

	# Clear staged list for next frame
	_staged_this_frame.clear()

## Called by State_Manager when a command successfully executes.
## Clears the buffer so it doesn't re-fire.
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

## Called by Fighter._update_facing() when character flips.
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
# State query API — called by states
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
# Command matching — runs on flush_staged()
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

# --- Held commands ---
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

# --- Charge commands ---
# Fixed: only counts a charge if the hold was uninterrupted —
# finds most recent release, verifies no second press of charge_dir
# between that release and its preceding press.
func _check_charge_command(cmd: Dictionary, type: String) -> bool:
	var sequence      : Array  = cmd["Sequence"]
	var charge_dir    : String = cmd["Button"][0]
	var charge_needed : int    = cmd["Charge"]

	# Find most recent release of charge_dir
	var charge_valid          := false
	var charge_released_frame := -1

	for i in range(event_log.size() - 1, -1, -1):
		var e = event_log[i]
		if e["action"] == charge_dir and e["type"] == "release":
			charge_released_frame = e["frame"]
			# Scan back for the press — must be uninterrupted
			# (no second press of charge_dir between them)
			var interrupted := false
			for j in range(i - 1, -1, -1):
				var pe = event_log[j]
				if pe["action"] == charge_dir:
					if pe["type"] == "press":
						# Found the press — check duration
						if charge_released_frame - pe["frame"] >= charge_needed:
							charge_valid = true
					else:
						# Another release before the press — interrupted
						interrupted = true
					break
			if interrupted:
				# This release is invalid — keep scanning for an earlier valid one
				continue
			break

	if not charge_valid:
		return false

	# Match the sequence following the charge release
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

# --- Combo commands (same-frame multi-button) ---
func _check_combo_command(cmd: Dictionary, inputs_this_frame: Array) -> bool:
	var required_buttons : Array = cmd["Buttons"]

	# All required buttons must appear in this frame's staged inputs as presses
	for btn in required_buttons:
		var found := false
		for entry in inputs_this_frame:
			if entry == btn:
				found = true
				break
		if not found:
			return false

	# Optional directional sequence check
	if "Sequence" in cmd and not cmd["Sequence"].is_empty():
		return _check_motion_command(cmd, "press")

	return true

# --- Motion commands ---
func _check_motion_command(cmd: Dictionary, type: String) -> bool:
	var sequence  : Array = cmd["Sequence"]
	var seq_index : int   = sequence.size() - 1
	var prev_frame: int   = -1
	var current   : int   = Engine.get_physics_frames()

	var last = event_log.back()
	if last == null or last["type"] != type:
		return false

	# Single step — allow diagonal equivalents (1/2/3 for crouch, 7/8/9 for jump)
	# Multi step — exact match only so 236 can't be input as 233
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

	var winner   : Dictionary = candidates[0]
	var top_prio : int        = PRIORITY.get(winner.get("Priority", ""), -1) 

	for cmd in candidates.slice(1):
		var p : int = PRIORITY.get(cmd.get("Priority", ""), -1)
		if p > top_prio:
			winner   = cmd
			top_prio = p

	if debug_mode:
		print("Matched: %s (%s)" % [winner.get("Command","?"), winner.get("Priority","?")])

	# Store as buffered command — will be attempted each tick until consumed or expired
	_buffered_command       = winner
	_buffered_command_frame = Engine.get_physics_frames()

	command_matched.emit(winner)

# -----------------------------------------------------------------------------
# Buffered command — attempted each tick until consumed or expired
# -----------------------------------------------------------------------------
func _try_buffered_command() -> void:
	if _buffered_command.is_empty():
		return
	
	var age := Engine.get_physics_frames() - _buffered_command_frame
	if age > BUFFER_WINDOW:
		_buffered_command       = {}
		_buffered_command_frame = -1
		return
	# Re-emit so State_Manager can try again against current gates
	print(_buffered_command["Command"]," ", age, " ", BUFFER_WINDOW)
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
