# =============================================================================
# State_Manager.gd
# Thin state machine. Holds the active state, ticks it, handles transitions.
#
# Command routing:
#   InputBuffer fires command_matched signal.
#   State_Manager checks the gate on the active state.
#   If gate is open, passes command to active_state.on_command().
#   The state decides what to do with it — no "State" key needed in commands.
#
# Priority resolution:
#   get_transition() — physics-driven (landing, timer expiry)
#   on_command()     — input-driven (all player actions)
#   Both can request a transition each frame.
#   Highest priority wins. One transition per frame.
# =============================================================================
extends Node
class_name State_Manager

# -----------------------------------------------------------------------------
# Exports
# -----------------------------------------------------------------------------
@export var initial_state_id : String = "Idle"
@export var debug_mode       : bool   = false
@export var State_Label      : Label

# -----------------------------------------------------------------------------
# State registry — populated from children in initialise()
# -----------------------------------------------------------------------------
var states       : Dictionary = {}
var active_state : State_Base = null
var fighter      : Fighter

# Pending transition for this frame — highest priority wins
var _pending : Dictionary = {}

# -----------------------------------------------------------------------------
# Initialise — called by Fighter._ready()
# -----------------------------------------------------------------------------
func initialise(p_fighter: Fighter) -> void:
	fighter = p_fighter

	for child in get_children():
		if child is State_Base:
			states[child.state_id] = child
			child.fighter       = fighter
			child.state_manager = self
			child.input_buffer  = fighter.input_buffer

	assert(states.has(initial_state_id),
		"State_Manager: initial state '%s' not found." % initial_state_id)

	fighter.input_buffer.command_matched.connect(_on_command_matched)
	_enter_state(initial_state_id, "")

# -----------------------------------------------------------------------------
# Main tick — called by Fighter._physics_process()
# -----------------------------------------------------------------------------
func tick(delta: float) -> void:
	assert(active_state != null, "State_Manager: no active state.")

	active_state.update(delta)

	if active_state.apply_gravity:
		active_state.tick_gravity(delta)

	var state_request := active_state.get_transition()
	if state_request != "":
		_request(state_request, _state_priority(state_request))

	_flush_pending()

# -----------------------------------------------------------------------------
# Command routing — all input-driven transitions come through here
# -----------------------------------------------------------------------------
func _on_command_matched(command: Dictionary) -> void:
	var priority_name : String = command.get("Priority", "")

	# Burst and Barrier bypass the gate — always checked
	var always_allowed := priority_name in ["Burst", "Barrier"]

	if not always_allowed and not _gate_open_for(priority_name):
		return

	# Pass to the active state — it decides what to do
	active_state.on_command(command)

## Check if the active state's cancel gate allows this priority type
func _gate_open_for(priority_name: String) -> bool:
	match priority_name:
		"Normal", "Command Normal": return active_state.gate_self
		"Special", "EX Special":   return active_state.gate_special
		"Drive":                   return active_state.gate_drive
		"Overdrive":               return active_state.gate_overdrive
		"Jump", "Super Jump":      return active_state.gate_jump
		"Dash":                    return active_state.gate_dash or active_state.gate_backdash
		"Burst":                   return active_state.gate_burst
		"Barrier":                 return active_state.gate_barrier
		_:                         return false

# -----------------------------------------------------------------------------
# Transition API — called by states via on_command() or get_transition()
# -----------------------------------------------------------------------------

## Request a transition at a given priority. Highest priority wins per frame.
func request(target_id: String, priority: int) -> void:
	if not states.has(target_id):
		push_warning("State_Manager: unknown state '%s'" % target_id)
		return
	if _pending.is_empty() or priority > _pending["priority"]:
		_pending = { "id": target_id, "priority": priority }

## Force an immediate transition — bypasses priority.
## Use for knockdown, KO, round reset only.
func force_transition(target_id: String) -> void:
	_pending.clear()
	_do_transition(target_id)

# -----------------------------------------------------------------------------
# Internal
# -----------------------------------------------------------------------------
func _request(target_id: String, priority: int) -> void:
	request(target_id, priority)

func _flush_pending() -> void:
	if _pending.is_empty():
		return
	var target = _pending["id"]
	_pending.clear()
	_do_transition(target)

func _do_transition(target_id: String) -> void:
	if not states.has(target_id):
		push_warning("State_Manager: cannot transition to '%s'" % target_id)
		return
	if debug_mode:
		print("[SM] %s → %s  frame:%d" % [
			active_state.state_id if active_state else "none",
			target_id,
			active_state.frame if active_state else 0
		])
	var prev_id := active_state.state_id if active_state else ""
	if active_state:
		active_state.exit()
	_enter_state(target_id, prev_id)

func _enter_state(target_id: String, prev_id: String) -> void:
	active_state = states[target_id]
	if State_Label:
		State_Label.text = active_state.state_id 
	active_state.enter(prev_id)

# -----------------------------------------------------------------------------
# Priority helpers
# -----------------------------------------------------------------------------
func _state_priority(state_id: String) -> int:
	match state_id:
		"Idle", "Walk", "Crouch": return 0
		"Prejump":                return 1
		"Airborne":               return 2
		"AirDash":                return 3
		_:                        return 5

func _command_priority(priority_name: String) -> int:
	return InputBuffer.PRIORITY.get(priority_name, 0)

# -----------------------------------------------------------------------------
# Query helpers
# -----------------------------------------------------------------------------
func is_in_state(id: String) -> bool:
	return active_state != null and active_state.state_id == id
