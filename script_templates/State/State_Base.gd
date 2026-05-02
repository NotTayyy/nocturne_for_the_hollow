# =============================================================================
# State_Base.gd
# Base class for every fighter state.
# States read from the fighter blackboard and write velocity back.
# They never reference each other directly.
#
# Frame counter:
#   `frame` increments every update(). Reset to 0 in enter().
#   Matches FG frame data notation exactly.
#
# Command handling:
#   State_Manager calls on_command(cmd) when InputBuffer fires command_matched.
#   Each state implements on_command() and decides what to do with it.
#   States that don't care about a command simply don't handle it.
# =============================================================================
extends Node
class_name State_Base

var fighter       : Fighter
var state_manager : State_Manager
var input_buffer  : InputBuffer

var state_id      : String = ""
var apply_gravity : bool   = false

# -----------------------------------------------------------------------------
# Cancel gate — replaces single cancellable bool
# States set these each frame based on current frame window and hit state.
# State_Manager checks these before accepting a command.
# -----------------------------------------------------------------------------
var gate_self      : bool = false
var gate_special   : bool = false
var gate_drive     : bool = false
var gate_overdrive : bool = false
var gate_jump      : bool = false
var gate_rapid     : bool = false
var gate_dash      : bool = false
var gate_backdash  : bool = false
var gate_burst     : bool = false   ## Burst always checked separately — bypasses most gates
var gate_barrier   : bool = false   ## Barrier always available while blocking

# Throw and burst invul flags — checked by hit resolution system
var invul_throw    : bool = false
var invul_burst    : bool = false
var invul_strike   : bool = false
var invul_all      : bool = false

# -----------------------------------------------------------------------------
# Frame counter — increments every update(), reset in enter()
# -----------------------------------------------------------------------------
var frame : int = 0

# -----------------------------------------------------------------------------
# Lifecycle — override in subclasses
# -----------------------------------------------------------------------------
func enter(_prev_state_id: String) -> void:
	frame = 0
	_reset_gates()

func exit() -> void:
	_reset_gates()

func update(_delta: float) -> void:
	frame += 1

func get_transition() -> String:
	return ""

## Called by State_Manager when InputBuffer fires command_matched.
## Each state overrides this and handles only the commands it cares about.
func on_command(_command: Dictionary) -> void:
	pass

# -----------------------------------------------------------------------------
# Gate helpers — states call these in update() to open/close cancel windows
# -----------------------------------------------------------------------------
func _reset_gates() -> void:
	gate_self      = false
	gate_special   = false
	gate_drive     = false
	gate_overdrive = false
	gate_jump      = false
	gate_rapid     = false
	gate_dash      = false
	gate_backdash  = false
	gate_burst     = false
	gate_barrier   = false
	invul_throw    = false
	invul_burst    = false
	invul_strike   = false
	invul_all      = false

func open_gate(move_data: MoveData, has_hit: bool, is_blocked: bool) -> void:
	gate_self      = move_data.cancel_self.is_available(frame, has_hit, is_blocked, false)
	gate_special   = move_data.cancel_special.is_available(frame, has_hit, is_blocked, false)
	gate_drive     = move_data.cancel_drive.is_available(frame, has_hit, is_blocked, false)
	gate_overdrive = move_data.cancel_overdrive.is_available(frame, has_hit, is_blocked, false)
	gate_jump      = move_data.cancel_jump.is_available(frame, has_hit, is_blocked, false)
	gate_rapid     = move_data.cancel_rapid.is_available(frame, has_hit, is_blocked, false)
	gate_dash      = move_data.cancel_dash.is_available(frame, has_hit, is_blocked, false)
	gate_backdash  = move_data.cancel_backdash.is_available(frame, has_hit, is_blocked, false)

# -----------------------------------------------------------------------------
# Button helpers
# -----------------------------------------------------------------------------
func pressed(btn: String, window: int = 1) -> bool:
	return input_buffer.button_pressed_within(btn, window)

func released(btn: String, window: int = 1) -> bool:
	return input_buffer.button_released_within(btn, window)

func any_button_just_pressed() -> bool:
	for b in InputBuffer.BUTTONS:
		if pressed(b):
			return true
	return false

# -----------------------------------------------------------------------------
# Physics helpers
# -----------------------------------------------------------------------------
func tick_gravity(delta: float) -> void:
	fighter.velocity.y += fighter.char_data.gravity * delta

func land() -> void:
	fighter.velocity.y = 0.0
