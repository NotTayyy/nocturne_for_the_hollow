extends Node
class_name State_Base

const JUMP_COMMANDS := ["Jump","JumpFwd","JumpBack","SuperJump","SuperJumpFwd","SuperJumpBack"]

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

## The command that triggered the transition into this state.
## Set by State_Manager before enter() is called.
var entered_via : Dictionary = {}

# -----------------------------------------------------------------------------
# Cancel gates
# States set these based on current frame window and hit state.
# State_Manager checks these before accepting a command.
# -----------------------------------------------------------------------------
var gate_normal    : bool = false
var gate_special   : bool = false
var gate_drive     : bool = false
var gate_overdrive : bool = false
var gate_jump      : bool = false
var gate_rapid     : bool = false
var gate_dash      : bool = false
var gate_backdash  : bool = false
var gate_burst     : bool = false

# Invul flags — checked by hit resolution system
var invul_head        : bool = false
var invul_body        : bool = false
var invul_foot        : bool = false
var invul_throw       : bool = false
var invul_projectile  : bool = false
var invul_burst       : bool = false
var invul_all         : bool = false
var invul_guard_point : bool = false

# -----------------------------------------------------------------------------
# Frame counter
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
# Gate helpers
# -----------------------------------------------------------------------------
func _reset_gates() -> void:
	gate_normal    = false
	gate_special   = false
	gate_drive     = false
	gate_overdrive = false
	gate_jump      = false
	gate_rapid     = false
	gate_dash      = false
	gate_backdash  = false
	gate_burst     = false
	invul_head        = false
	invul_body        = false
	invul_foot        = false
	invul_throw       = false
	invul_projectile  = false
	invul_burst       = false
	invul_all         = false
	invul_guard_point = false

func _open_gate_neutral() -> void:
	gate_normal    = true
	gate_special   = true
	gate_drive     = true
	gate_overdrive = true
	gate_jump      = true
	gate_dash      = true
	gate_backdash  = true

func open_gate(move_data: MoveData, has_hit: bool, is_blocked: bool) -> void:
	gate_normal    = move_data.cancel_normal.is_available(has_hit, is_blocked)
	gate_special   = move_data.cancel_special.is_available(has_hit, is_blocked)
	gate_drive     = move_data.cancel_drive.is_available(has_hit, is_blocked)
	gate_overdrive = move_data.cancel_overdrive.is_available(has_hit, is_blocked)
	gate_jump      = move_data.cancel_jump.is_available(has_hit, is_blocked)
	gate_rapid     = move_data.cancel_rapid.is_available(has_hit, is_blocked)
	gate_dash      = move_data.cancel_dash.is_available(has_hit, is_blocked)
	gate_backdash  = move_data.cancel_backdash.is_available(has_hit, is_blocked)
	gate_burst     = move_data.cancel_burst.is_available(has_hit, is_blocked)

func safe_play(anim_name: String) -> void:
	if ap.has_animation(anim_name):
		ap.play(anim_name)
	elif Global.game_manager.Debug:
		print("[%s] Animation not found: %s" % [state_id, anim_name])

func _request_attack(command: Dictionary, hfd_path: String) -> bool:
	var attack : ST_Attack = state_manager.states.get("Attack") as ST_Attack
	if attack == null:
		return false
	var hfd : HitboxFrameData = fighter.get_node_or_null(hfd_path) as HitboxFrameData
	if hfd == null:
		push_error("[%s] Could not find HFD at path: %s" % [state_id, hfd_path])
		return false
	var in_attack : bool = state_manager.active_state != null \
						   and state_manager.active_state.state_id == "Attack"
	if in_attack:
		var current_hfd : HitboxFrameData = (state_manager.active_state as ST_Attack).hfd
		if not _cancel_allowed(current_hfd, command):
			return false
		var old_hfd : HitboxFrameData = attack.hfd
		attack._staged_hfd = hfd
		attack.hfd         = old_hfd
		attack.exit()
		attack.hfd = null
		attack.enter("Attack")
		state_manager.active_state = attack
	else:
		attack.hfd = hfd
		var prio : int = InputBuffer.PRIORITY.get(command.get("Priority", ""), 0)
		state_manager.request("Attack", prio)
	return true

func _request_from_route(command: Dictionary, path: String) -> bool:
	# HFD path — contains "/" — go to Attack state
	if "/" in path:
		return _request_attack(command, path)
	# State ID — transition directly
	if not state_manager.states.has(path):
		push_error("[%s] CancelRoute state '%s' not found" % [state_id, path])
		return false
	var current_hfd : HitboxFrameData = null
	if state_manager.active_state != null and state_manager.active_state.state_id == "Attack":
		current_hfd = (state_manager.active_state as ST_Attack).hfd
	if current_hfd != null and not _cancel_allowed(current_hfd, command):
		return false
	fighter.input_buffer.consume_buffer()
	state_manager.force_transition(path)
	return true

func _cancel_allowed(current_hfd : HitboxFrameData, command : Dictionary = {}) -> bool:
	if current_hfd == null or current_hfd.move_data == null:
		return true
	var md : MoveData = current_hfd.move_data
	var f  : int      = current_hfd._current_frame
	if f <= md.startup:
		return false
	var window : CancelWindow = _get_window_for_priority(md, command.get("Priority", ""))
	if window == null:
		return false
	var hit   : bool = current_hfd.hit_state == HitboxFrameData.HitState.HIT
	var block : bool = current_hfd.hit_state == HitboxFrameData.HitState.BLOCK
	return window.is_available(hit, block)

func _get_window_for_priority(md : MoveData, priority : String) -> CancelWindow:
	match priority:
		"Normal", "Command Normal", "Throw", "Guard Crush":
			return md.cancel_normal
		"Special", "EX Special", "Ultimate Art":
			return md.cancel_special
		"Drive":
			return md.cancel_drive
		"Overdrive":
			return md.cancel_overdrive
		"Jump", "Super Jump":
			return md.cancel_jump
		"Rapid Cancel":
			return md.cancel_rapid
		"Dash":
			return md.cancel_dash
		"BackDash":
			return md.cancel_backdash
		"Burst":
			return md.cancel_burst
		_:
			return null

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

# -----------------------------------------------------------------------------
# Aerial stock helpers
# -----------------------------------------------------------------------------
var jumps_remaining  : int :
	get: return fighter.jumps_remaining
var dashes_remaining : int :
	get: return fighter.dashes_remaining
