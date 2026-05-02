extends State_Base
class_name ST_AirDash

enum Phase { STARTUP, ACTIVE, RECOVERY }

var _phase           : int   = Phase.STARTUP
var _timer           : int   = 0
var _is_forward_dash : bool  = true

func _ready() -> void:
	state_id = "AirDash"

func enter(_prev: String) -> void:
	frame         = 0
	apply_gravity = false
	_reset_gates()

	var cd     := fighter.char_data
	var sign_x := 1.0 if fighter.dir_facing == "Right" else -1.0

	_is_forward_dash = "4" not in input_buffer.held_inputs
	fighter.velocity.x = sign_x * cd.airdash_speed if _is_forward_dash \
						else -sign_x * cd.airdash_speed
	fighter.velocity.y = 0.0

	_phase = Phase.STARTUP
	_timer = cd.airdash_startup_frames
	fighter.anim_player.play("airdash_fwd" if _is_forward_dash else "airdash_bwd")

func exit() -> void:
	_reset_gates()
	apply_gravity = false

func update(_delta: float) -> void:
	frame  += 1
	_timer -= 1

	match _phase:
		Phase.STARTUP:
			fighter.velocity.x = 0.0
			fighter.velocity.y = 0.0
			if _timer <= 0:
				_enter_active()

		Phase.ACTIVE:
			fighter.velocity.y = 0.0
			if _timer <= 0:
				_enter_recovery()

		Phase.RECOVERY:
			if _timer <= 0:
				state_manager.force_transition("Airborne")

func get_transition() -> String:
	return ""

func on_command(command: Dictionary) -> void:
	var prio : int = InputBuffer.PRIORITY.get(command.get("Priority", ""), 0)
	if _phase == Phase.ACTIVE and _is_forward_dash:
		if command.get("Priority", "") in ["Normal", "Command Normal", "Special", "EX Special"]:
			pass # state_manager.request("Attack", prio) — wired when ST_Attack exists

func _enter_active() -> void:
	_phase = Phase.ACTIVE
	_timer = fighter.char_data.airdash_active_frames
	# Forward airdash can cancel into air normals — matches BBCF
	if _is_forward_dash:
		gate_self    = true
		gate_special = true
		gate_drive   = true
		gate_burst   = true

func _enter_recovery() -> void:
	_phase        = Phase.RECOVERY
	_timer        = fighter.char_data.airdash_recovery_frames
	apply_gravity = true
	_reset_gates()
	fighter.velocity.x = 0.0
