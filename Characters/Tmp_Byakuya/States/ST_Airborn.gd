extends State_Base
class_name ST_Airborne

# Countdown stocks — both deplete on any aerial action
var jumps_remaining  : int = 0
var dashes_remaining : int = 0
var _lockout_timer   : int = 0
var _airjump_pending : bool = false

func _ready() -> void:
	state_id = "Airborne"

func enter(prev: String) -> void:
	frame         = 0
	apply_gravity = true
	gate_special   = true
	gate_drive     = true
	gate_overdrive = true
	gate_burst     = true
	gate_barrier   = true

	var from_ground := prev in ["Prejump", "Idle", "Walk", "Crouch"]
	if from_ground:
		# Reset stocks to max on leaving the ground
		jumps_remaining  = fighter.char_data.air_Jumps
		dashes_remaining = fighter.char_data.air_Dashes
		_lockout_timer   = fighter.char_data.airjump_lockout

	_airjump_pending = false

	if prev != "Prejump":
		fighter.velocity.y = maxf(fighter.velocity.y, 0.0)

	_update_gates()
	_play_jump_anim()

func exit() -> void:
	_reset_gates()

func update(_delta: float) -> void:
	frame += 1
	_airjump_pending = false

	if _lockout_timer > 0:
		_lockout_timer -= 1

	_update_gates()

func get_transition() -> String:
	if fighter.is_on_floor() and fighter.velocity.y >= 0.0:
		land()
		return "Idle"
	return ""

func on_command(command: Dictionary) -> void:
	var cmd  : String = command.get("Command", "")
	var prio : int = InputBuffer.PRIORITY.get(command.get("Priority", ""), 0)

	match cmd:
		"Jump", "JumpFwd", "JumpBack":
			_request_airjump(cmd)
		"Dash", "AirDash":
			_request_airdash(prio, false)
		"BackDash", "AirBackDash":
			_request_airdash(prio, true)

# -----------------------------------------------------------------------------
# Stock management
# -----------------------------------------------------------------------------

## Both pools deplete on every aerial action
func _spend_aerial_stock() -> void:
	jumps_remaining  = maxi(jumps_remaining  - 1, 0)
	dashes_remaining = maxi(dashes_remaining - 1, 0)

func _can_airjump() -> bool:
	return jumps_remaining > 0 and _lockout_timer <= 0 and not _airjump_pending

func _can_airdash() -> bool:
	return dashes_remaining > 0

func _update_gates() -> void:
	gate_jump     = _can_airjump()
	gate_dash     = _can_airdash()
	gate_backdash = _can_airdash()

# -----------------------------------------------------------------------------
# Air jump
# -----------------------------------------------------------------------------
func _request_airjump(cmd: String) -> void:
	if not _can_airjump(): return

	_airjump_pending = true
	_spend_aerial_stock()
	_update_gates()

	var cd     := fighter.char_data
	var sign_x := 1.0 if fighter.dir_facing == "Right" else -1.0

	# Add to current velocity rather than replacing — boost feel not full reset
	match cmd:
		"Jump":
			fighter.velocity.x = 0.0
			fighter.velocity.y = cd.jump_velocity * 1
		"JumpFwd":
			fighter.velocity.x = sign_x * cd.jump_fwd_velocity * 0.8
			fighter.velocity.y = cd.jump_velocity * 1
		"JumpBack":
			fighter.velocity.x = sign_x * -cd.jump_bwd_velocity * 0.8
			fighter.velocity.y = cd.jump_velocity * 1

	# Clamp so velocity doesn't exceed a sensible max
	_play_jump_anim()

# -----------------------------------------------------------------------------
# Air dash
# -----------------------------------------------------------------------------
func _request_airdash(prio: int, _is_back: bool) -> void:
	if not _can_airdash(): return
	_spend_aerial_stock()
	_update_gates()
	state_manager.request("AirDash", prio)

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
func _play_jump_anim() -> void:
	var vx     := fighter.velocity.x
	var sign_x := 1.0 if fighter.dir_facing == "Right" else -1.0
	var fwd    := vx * sign_x > 0.1
	var back   := vx * sign_x < -0.1
	if   fwd:  fighter.anim_player.play("jump_fwd")
	elif back: fighter.anim_player.play("jump_bwd")
	else:      fighter.anim_player.play("jump_neutral")
