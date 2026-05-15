extends Node
class_name State_Base

# -----------------------------------------------------------------------------
# Blackboard references — injected by State_Manager.initialise()
# -----------------------------------------------------------------------------
var fighter       : Fighter
var state_manager : State_Manager
var input_buffer  : InputBuffer
var cd            : CharacterData
var ap            : AnimationPlayer
var lockout_timer : int = 0

@export var hfd_node : HitboxFrameData = null

## Facing-relative horizontal sign. Always current — computed on access.
var sign_x : float :
	get: return 1.0 if fighter.dir_facing == "Right" else -1.0
	


# -----------------------------------------------------------------------------
# Per-state metadata
# -----------------------------------------------------------------------------
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
var invul_throw      : bool = false
var invul_burst      : bool = false
var invul_strike     : bool = false
var invul_all        : bool = false
var invul_head       : bool = false
var invul_foot       : bool = false
var invul_projectile : bool = false

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

func on_command(_command: Dictionary) -> void:
	pass

# -----------------------------------------------------------------------------
# Gate helpers — states call these in update() to open/close cancel windows
# -----------------------------------------------------------------------------
## Closes all Gates and Removes all Invulnerabilities
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
	invul_throw      = false
	invul_burst      = false
	invul_strike     = false
	invul_all        = false
	invul_head       = false
	invul_foot       = false
	invul_projectile = false

## Opens all the Gates that should be open when In an Idle state for ease of use
func _open_gate_neutral() -> void:
	gate_self      = true
	gate_special   = true
	gate_drive     = true
	gate_overdrive = true
	gate_jump      = true
	gate_dash      = true
	gate_backdash  = true
	gate_barrier   = true

func open_gate(move_data: MoveData, has_hit: bool, is_blocked: bool) -> void:
	gate_self      = move_data.cancel_self.is_available(frame, has_hit, is_blocked, false)
	gate_special   = move_data.cancel_special.is_available(frame, has_hit, is_blocked, false)
	gate_drive     = move_data.cancel_drive.is_available(frame, has_hit, is_blocked, false)
	gate_overdrive = move_data.cancel_overdrive.is_available(frame, has_hit, is_blocked, false)
	gate_jump      = move_data.cancel_jump.is_available(frame, has_hit, is_blocked, false)
	gate_rapid     = move_data.cancel_rapid.is_available(frame, has_hit, is_blocked, false)
	gate_dash      = move_data.cancel_dash.is_available(frame, has_hit, is_blocked, false)
	gate_backdash  = move_data.cancel_backdash.is_available(frame, has_hit, is_blocked, false)

## Safe animation play — silently skips missing animations.
## Prints a warning in debug mode.
func safe_play(anim_name: String) -> void:
	if ap.has_animation(anim_name):
		ap.play(anim_name)
	elif Global.game_manager.Debug:
		print("[%s] Animation not found: %s" % [state_id, anim_name])

## Routes an attack command to ST_Attack using the given HFD node path.
## Checks cancel windows if currently in ST_Attack.
## Returns true if the attack was successfully routed.
func _request_attack(command: Dictionary, hfd_path: String) -> bool:
	var attack : ST_Attack = state_manager.states.get("Attack") as ST_Attack
	if attack == null:
		return false
	var hfd : HitboxFrameData = fighter.get_node_or_null(hfd_path) as HitboxFrameData
	if hfd == null:
		push_error("[%s] Could not find HFD at path: %s" % [state_id, hfd_path])
		return false
	# Cancel window check if currently attacking
	if state_manager.active_state != null and state_manager.active_state.state_id == "Attack":
		var current_hfd : HitboxFrameData = (state_manager.active_state as ST_Attack).hfd
		if not _cancel_allowed(current_hfd):
			return false
	attack.hfd = hfd
	var prio : int = InputBuffer.PRIORITY.get(command.get("Priority", ""), 0)
	state_manager.request("Attack", prio)
	return true

## Checks whether a cancel out of the current attack is allowed.
## Rules: never during startup, on_hit/on_block only, on_whiff only if stated.
func _cancel_allowed(current_hfd : HitboxFrameData) -> bool:
	if current_hfd == null or current_hfd.move_data == null:
		return true
	var md    : MoveData = current_hfd.move_data
	var f     : int      = current_hfd._current_frame
	# Never during startup
	if f <= md.startup:
		return false
	# Check cancel windows
	var hit   : bool = current_hfd.hit_state == HitboxFrameData.HitState.HIT
	var block : bool = current_hfd.hit_state == HitboxFrameData.HitState.BLOCK
	var whiff : bool = current_hfd.hit_state == HitboxFrameData.HitState.NONE
	for window in md.cancel_windows:
		if not window.is_available(f, hit, block, whiff):
			continue
		if hit   and window.on_hit:   return true
		if block and window.on_block: return true
		if whiff and window.on_whiff: return true
	return false

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
	fighter.velocity.y += cd.gravity * delta

func land() -> void:
	fighter.velocity.y = 0.0
