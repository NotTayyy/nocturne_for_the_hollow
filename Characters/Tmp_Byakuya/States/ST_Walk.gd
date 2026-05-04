extends State_Base
class_name ST_Walk

const JUMP_COMMANDS := ["Jump","JumpFwd","JumpBack","SuperJump","SuperJumpFwd","SuperJumpBack"]

func _ready() -> void:
	state_id = "Walk"

func enter(_prev: String) -> void:
	frame         = 0
	apply_gravity = false
	fighter.velocity.y = 0.0
	gate_self      = true
	gate_special   = true
	gate_drive     = true
	gate_overdrive = true
	gate_jump      = true
	gate_rapid     = true
	gate_dash      = true
	gate_backdash  = true
	gate_burst     = true
	gate_barrier   = true

func exit() -> void:
	_reset_gates()
	fighter.velocity.x = 0.0

func update(_delta: float) -> void:
	frame += 1
	fighter.update_facing()
	var h       := input_buffer.held_inputs
	var forward := "6" in h
	var speed   := fighter.get_walk_speed(forward)
	fighter.velocity.x = sign_x * speed if forward else -sign_x * speed
	fighter.anim_player.play("walk_fwd" if forward else "walk_bwd")

	# No direction held — return to idle
	if "6" not in h and "4" not in h:
		state_manager.request("Idle", InputBuffer.PRIORITY["Standing"])

func on_command(command: Dictionary) -> void:
	var cmd  : String = command.get("Command", "")
	var prio : int = InputBuffer.PRIORITY.get(command.get("Priority", ""), 0)
	match cmd:
		"Crouch":
			state_manager.request("Crouch", prio)
		"Dash":
			state_manager.request("Dash", prio)
		"BackDash":
			state_manager.request("BackDash", prio)
		_ when cmd in JUMP_COMMANDS:
			_request_jump(cmd, prio)

func _request_jump(cmd: String, prio: int) -> void:
	var prejump := state_manager.states.get("Prejump") as ST_Prejump
	if prejump:
		prejump.jump_command = cmd
	state_manager.request("Prejump", prio)
