extends State_Base
class_name ST_Idle

const JUMP_COMMANDS := ["Jump","JumpFwd","JumpBack","SuperJump","SuperJumpFwd","SuperJumpBack"]

func _ready() -> void:
	state_id = "Idle"

func enter(_prev: String) -> void:
	frame         = 0
	apply_gravity = false
	fighter.velocity.x = 0.0
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
	fighter.anim_player.play("idle")

func exit() -> void:
	_reset_gates()

func update(_delta: float) -> void:
	frame += 1
	fighter.update_facing()

func get_transition() -> String:
	var h := input_buffer.held_inputs
	if fighter.is_airborne:   return "Airborne"
	if "2" in h:              return "Crouch"
	if "6" in h or "4" in h: return "Walk"
	return ""

func on_command(command: Dictionary) -> void:
	var cmd  : String = command.get("Command", "")
	var prio : int = InputBuffer.PRIORITY.get(command.get("Priority", ""), 0)
	match cmd:
		"Dash":     state_manager.request("Dash", prio)
		"BackDash": state_manager.request("BackDash", prio)
		_ when cmd in JUMP_COMMANDS:
			_request_jump(cmd, prio)

func _request_jump(cmd: String, prio: int) -> void:
	var prejump := state_manager.states.get("Prejump") as ST_Prejump
	if prejump:
		prejump.jump_command = cmd
	state_manager.request("Prejump", prio)
