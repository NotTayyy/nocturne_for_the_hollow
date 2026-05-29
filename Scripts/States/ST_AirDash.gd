extends State_Base
class_name ST_AirDash

const JUMP_COMMANDS := ["Jump","JumpFwd","JumpBack"]

func _ready() -> void:
	state_id = "AirDash"

func enter(_prev: String) -> void:
	frame         = 0
	apply_gravity = false
	fighter.velocity.y = 0.0
	gate_normal    = true
	gate_special   = true
	gate_drive     = true
	gate_overdrive = true
	gate_jump      = true
	ap.play("Airdash/FAirDash")


func exit() -> void:
	_reset_gates()

func update(_delta: float) -> void:
	frame += 1
	fighter.velocity.y = 0.0
	fighter.velocity.x = sign_x * cd.airdash_fwd_velocity
	if frame >= cd.airdash_duration:
		state_manager.request("Airborne", InputBuffer.PRIORITY["Jump"])

func on_command(command: Dictionary) -> void:
	var cmd  : String = command.get("Command", "")
	var prio : int    = InputBuffer.PRIORITY.get(command.get("Priority", ""), 0)
	match cmd:
		_ when cmd in JUMP_COMMANDS:
			if fighter.jumps_remaining <= 0: return
			fighter.velocity.x = 0.0
			var airborne := state_manager.states.get("Airborne") as ST_Airborne
			if airborne: airborne._request_airjump(cmd)
			state_manager.request("Airborne", prio)
