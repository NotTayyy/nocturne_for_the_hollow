# =============================================================================
# State_Manager.gd
# Tick order:
#   1. active_state.update()
#   2. Apply gravity
#   3. get_transition()           ← physics only (landing, falling)
#   4. input_buffer.flush_staged() ← command matching, fires command_matched
#   5. _tick_barrier_held()       ← barrier meter
#   6. _flush_pending()           ← execute highest priority transition
# =============================================================================
extends Node
class_name State_Manager

@export var initial_state_id : String = "Idle"
@export var debug_mode       : bool   = false

@onready var State_Label      : Label = %State_Label

var states       : Dictionary = {}
var active_state : State_Base = null
var fighter      : Fighter
var _pending     : Dictionary = {}
var last_command : Dictionary = {}

# -----------------------------------------------------------------------------
# Initialise
# -----------------------------------------------------------------------------
func initialise(p_fighter: Fighter) -> void:
	fighter = p_fighter

	for child in get_children():
		if child is State_Base:
			states[child.state_id] = child
			child.fighter       = fighter
			child.state_manager = self
			child.input_buffer  = fighter.input_buffer
			child.cd            = fighter.char_data
			child.ap            = fighter.anim_player   

	assert(states.has(initial_state_id),
		"State_Manager: initial state '%s' not found." % initial_state_id)

	fighter.input_buffer.command_matched.connect(_on_command_matched)
	_enter_state(initial_state_id, "")

# -----------------------------------------------------------------------------
# Main tick
# -----------------------------------------------------------------------------
func tick(delta: float) -> void:
	assert(active_state != null, "State_Manager: no active state.")

	# Global airborne override — catches launches, knockbacks, anything that
	# puts the fighter in the air outside of the normal Prejump → Airborne flow


	# 1. State logic
	active_state.update(delta)

	# Apply friction during hitstun/hitstop so pushback decays naturally
	if not fighter._is_actionable():
		fighter.velocity.x *= fighter.char_data.friction

	# 2. Gravity
	if active_state.apply_gravity:
		active_state.tick_gravity(delta)

	# 3. Physics-driven transitions
	var state_request := active_state.get_transition()
	if state_request != "":
		request(state_request, _state_priority(state_request))

	# 4. Flush staged inputs — runs command matching, fires command_matched
	fighter.input_buffer.flush_staged()

	# 5. Barrier — sync active state and tick meter
	_tick_barrier_held(delta)

	# 6. Execute highest priority pending transition
	_flush_pending()

func _tick_barrier_held(delta: float) -> void:
	var held        := fighter.input_buffer.held_inputs
	var in_block    : bool = active_state.state_id in ["StandBlock", "CrouchBlock", "AirBlock"]
	var back_held   : bool = "4" in held or "1" in held or "7" in held
	var can_barrier : bool = back_held and "A" in held and "B" in held \
		and in_block and not fighter.char_data.in_broken

	if "barrier_active" in active_state:
		active_state.barrier_active = can_barrier

	fighter.char_data.tick_barrier(delta, can_barrier)

	# Switch between Stand and Crouch barrier based on held direction
	if in_block and can_barrier and not fighter.is_airborne:
		var want_crouch : bool = "1" in held
		if want_crouch and active_state.state_id == "StandBlock":
			force_transition("CrouchBlock")
			if "barrier_active" in active_state:
				active_state.barrier_active = true
		elif not want_crouch and active_state.state_id == "CrouchBlock":
			force_transition("StandBlock")
			if "barrier_active" in active_state:
				active_state.barrier_active = true

# -----------------------------------------------------------------------------
# Command routing
# -----------------------------------------------------------------------------
func _on_command_matched(command: Dictionary) -> void:
	last_command = command
	# Barrier — only allowed when already blocking or wants_to_block
	if command.get("Command", "") == "Barrier":
		if fighter.char_data.in_broken:
			return
		if fighter.wants_to_block and fighter._is_actionable():
			var block_type : String = fighter.get_block_type()
			var target     : String
			if fighter.is_airborne:
				target = "AirBlock"
			elif block_type == "Crouch":
				target = "CrouchBlock"
			else:
				target = "StandBlock"
			force_transition(target)
			_pending.clear()
		return

	# During hitstun/hitstop — only burst gets through
	if not fighter._is_actionable():
		if command.get("Command", "") == "Burst" and active_state.gate_burst:
			active_state.on_command(command)
		return

	# In attack state — bypass gate check, ST_Attack handles cancel validation
	if active_state.state_id == "Attack":
		active_state.on_command(command)
		return

	if not _gate_open_for(command.get("Priority", "")):
		return

	active_state.on_command(command)

func _gate_open_for(priority_name: String) -> bool:
	match priority_name:
		"Standing":                        return true
		"Walking":                         return true
		"Crouching":                       return true
		"Dash":                            return active_state.gate_dash
		"Jump", "Super Jump":              return active_state.gate_jump
		"Normal":                          return active_state.gate_normal
		"Command Normal":                  return active_state.gate_normal
		"Guard Crush":                     return active_state.gate_special
		"Throw":                           return active_state.gate_special
		"Special", "EX Special":           return active_state.gate_special
		"Rapid Cancel":                    return active_state.gate_rapid
		"Ultimate Art":                    return active_state.gate_special
		"Burst":                           return active_state.gate_burst
		_:                                 return false

# -----------------------------------------------------------------------------
# Transition API
# -----------------------------------------------------------------------------
func request(target_id: String, priority: int) -> void:
	if not states.has(target_id):
		push_warning("State_Manager: unknown state '%s'" % target_id)
		return
	if _pending.is_empty() or priority > _pending["priority"]:
		_pending = { "id": target_id, "priority": priority }

func force_transition(target_id: String) -> void:
	_pending.clear()
	_do_transition(target_id, false)

func _flush_pending() -> void:
	if _pending.is_empty(): return
	var target : String = _pending["id"]
	_pending.clear()
	_do_transition(target, true)

func _do_transition(target_id: String, player_initiated: bool = true) -> void:
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
	_enter_state(target_id, prev_id, player_initiated)

func _enter_state(target_id: String, prev_id: String, consume: bool = true) -> void:
	active_state = states[target_id]
	active_state.entered_via = last_command
	active_state.enter(prev_id)
	State_Label.text = active_state.state_id
	# Only consume buffer on player-initiated transitions
	if consume:
		fighter.input_buffer.consume_buffer()

# -----------------------------------------------------------------------------
# Priority helpers
# -----------------------------------------------------------------------------
func _state_priority(state_id: String) -> int:
	match state_id:
		"Idle", "Walk", "Crouch": return 0
		"Prejump":                return 1
		"JumpLanding":            return 2
		"Airborne":               return 3
		"AirDash":                return 4
		_:                        return 5

func is_in_state(id: String) -> bool:
	return active_state != null and active_state.state_id == id
