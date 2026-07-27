extends State_Base
class_name ST_AirBackDash

func _ready() -> void:
	state_id = "AirBackDash"

func enter(_prev: String) -> void:
	frame         = 0
	apply_gravity = false
	fighter.velocity.x = sign_x * fighter.char_data.airdash_bwd_velocity
	fighter.velocity.y = 0.0

	# Cancellable into everything except burst and barrier
	gate_normal    = true
	gate_special   = true
	gate_drive     = true
	gate_overdrive = true
	gate_jump      = true
	gate_dash      = true
	gate_backdash  = true
	ap.play("Airdash/BAirDash")

func exit() -> void:
	_reset_gates()

func update(_delta: float) -> void:
	frame += 1
	fighter.velocity.y = 0.0
	if frame >= fighter.char_data.airdash_duration:
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
