extends State_Base
class_name ST_Airborne

enum JumpPhase { ASCENT, APEX, DESCENT }

var APEX_THRESHOLD  : float = 300
var _jump_phase     : int   = JumpPhase.ASCENT
var from_ground     : bool
var _jump_8_released : bool = false  ## Must release 8 before a new air jump direction registers

func _ready() -> void:
	state_id = "Airborne"

func enter(prev: String) -> void:
	from_ground = prev in ["Prejump", "Idle", "Walk", "RunSkid", "Dash"]
	frame            = 0
	apply_gravity    = true
	if from_ground:
		fighter.jumps_remaining  = cd.air_Jumps
		fighter.dashes_remaining = cd.air_Dashes
		lockout_timer   = cd.airjump_lockout
	else:
		lockout_timer = 0
	_reset_gates()
	_jump_8_released = false  ## Must release 8 before new air jump registers
	_play_jump_anim()
	if hfd_node != null:
		hfd_node.begin(null)

func exit() -> void:
	_reset_gates()
	if hfd_node != null:
		hfd_node.stop()

func update(_delta: float) -> void:
	frame += 1
	if hfd_node != null:
		hfd_node.tick()

	if lockout_timer > 0:
		lockout_timer -= 1
		# Keep jump/dash gates closed during lockout
		gate_jump     = false
		gate_dash     = false
		gate_backdash = false
	else:
		_update_gates()
	
	_update_jump_phase()

	# Track 8 release for deliberate air jump inputs
	if not _jump_8_released and "8" not in fighter.input_buffer.held_inputs:
		_jump_8_released = true

func get_transition() -> String:
	if fighter.is_on_floor() and fighter.velocity.y >= 0.0:
		land()
		return "JumpLanding"
	return ""

func on_command(command: Dictionary) -> void:
	var cmd  : String = command.get("Command", "")
	var prio : int    = InputBuffer.PRIORITY.get(command.get("Priority", ""), 0)
	match cmd:
		"Jump", "JumpFwd", "JumpBack":
			_request_airjump(cmd)
		"Dash", "AirDash":
			_request_airdash(prio, false)
		"BackDash", "AirBackDash":
			_request_airdash(prio, true)

func _update_jump_phase() -> void:
	var new_phase : int
	if   fighter.velocity.y < -APEX_THRESHOLD: new_phase = JumpPhase.ASCENT
	elif fighter.velocity.y >  APEX_THRESHOLD: new_phase = JumpPhase.DESCENT
	else:                                       new_phase = JumpPhase.APEX
 
	if new_phase != _jump_phase:
		_jump_phase = new_phase
		_play_jump_anim()
 
func _play_jump_anim() -> void:
	match _jump_phase:
		JumpPhase.ASCENT:  fighter.anim_player.play("Jump/Jump_Asc")
		JumpPhase.APEX:    fighter.anim_player.play("Jump/Jump_Apex")
		JumpPhase.DESCENT: fighter.anim_player.play("Jump/Jump_Desc")
 
# -----------------------------------------------------------------------------
# Stock management
# -----------------------------------------------------------------------------
func _spend_aerial_stock() -> void:
	fighter.jumps_remaining  = maxi(fighter.jumps_remaining  - 1, 0)
	fighter.dashes_remaining = maxi(fighter.dashes_remaining - 1, 0)

func _can_airjump() -> bool:
	return fighter.jumps_remaining > 0 and lockout_timer <= 0

func _can_airdash() -> bool:
	return fighter.dashes_remaining > 0 and lockout_timer <= 0

func _update_gates() -> void:
	gate_jump      = _can_airjump()
	gate_dash      = _can_airdash()
	gate_backdash  = _can_airdash()
	gate_special   = true
	gate_drive     = true
	gate_overdrive = true
	gate_normal    = true

# -----------------------------------------------------------------------------
# Air jump
# -----------------------------------------------------------------------------
func _request_airjump(cmd: String) -> void:
	if not _can_airjump(): return
	if not _jump_8_released: return  ## Must release 8 since last jump
	_spend_aerial_stock()
	_update_gates()
	_jump_8_released = false  ## Reset — must release 8 again for next air jump
	fighter.input_buffer.consume_buffer()
	
	if not from_ground:
		fighter.velocity.x = 0

	match cmd:
		"Jump":
			fighter.velocity.x += 0.0
			fighter.velocity.y = cd.jump_velocity
		"JumpFwd":
			fighter.velocity.x = sign_x * cd.jump_fwd_velocity * 0.8
			fighter.velocity.y = cd.jump_velocity
		"JumpBack":
			fighter.velocity.x = sign_x * -cd.jump_bwd_velocity * 0.8
			fighter.velocity.y = cd.jump_velocity

	fighter.velocity.y = maxf(fighter.velocity.y, cd.jump_velocity * 1.5)
	
	_jump_phase = JumpPhase.ASCENT
	_play_jump_anim()

# -----------------------------------------------------------------------------
# Air dash
# -----------------------------------------------------------------------------
func _request_airdash(prio: int, is_back: bool) -> void:

	if not _can_airdash(): return
	_spend_aerial_stock()
	_update_gates()
	state_manager.request("AirBackDash" if is_back else "AirDash", prio)
