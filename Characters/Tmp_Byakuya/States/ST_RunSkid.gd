# =============================================================================
# ST_RunSkid.gd
# Entered when a run ends without canceling into another action.
# Velocity decays at 0.9x per frame until near zero then transitions to Idle.
#
# Cancel rules:
#   Everything EXCEPT block — normals, specials, jump, dash, backdash, burst
#   Barrier is the only path to blocking (Barrier Brake)
#   Walk forward/back available — transitions to ST_Walk
#   Re-dash available via Dash command
#
# Velocity carries into all cancels — receiving state decides whether to keep it.
# =============================================================================
extends State_Base
class_name ST_RunSkid

const JUMP_COMMANDS := ["Jump","JumpFwd","JumpBack","SuperJump","SuperJumpFwd","SuperJumpBack"]

func _ready() -> void:
	state_id = "RunSkid"

func enter(_prev: String) -> void:
	frame         = 0
	apply_gravity = false
	# Do NOT touch velocity — carry dash momentum in

	# All gates open except block — barrier is the only path to block
	gate_self      = true
	gate_special   = true
	gate_drive     = true
	gate_overdrive = true
	gate_jump      = true
	gate_rapid     = true
	gate_dash      = true    # re-dash allowed
	gate_backdash  = true
	gate_burst     = true
	gate_barrier   = true    # Barrier Brake — only path to blocking

	fighter.anim_player.play("run_skid")

func exit() -> void:
	_reset_gates()

func update(_delta: float) -> void:
	frame += 1
	fighter.velocity.x *= 0.9
	if absf(fighter.velocity.x) < 100.0:
		state_manager.request("Idle", 0)

func on_command(command: Dictionary) -> void:
	var cmd  : String = command.get("Command", "")
	var prio : int = InputBuffer.PRIORITY.get(command.get("Priority", ""), 0)

	match cmd:
		"Walk", "WalkBack":
			state_manager.request("Walk", prio)
		"Dash":
			state_manager.request("Dash", prio)
		"BackDash":
			state_manager.request("BackDash", prio)
		_ when cmd in JUMP_COMMANDS:
			var prejump := state_manager.states.get("Prejump") as ST_Prejump
			if prejump: prejump.jump_command = cmd
			state_manager.request("Prejump", prio)
		"Barrier":
			state_manager.request("Barrier", prio)
		_ when command.get("Priority","") in ["Normal","Command Normal",
			   "Special","EX Special","Drive","Ultimate Art"]:
			pass # wire to ST_Attack when ready
