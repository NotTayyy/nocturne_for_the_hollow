extends State_Base
class_name ST_Crouch

const JUMP_COMMANDS := ["Jump","JumpFwd","JumpBack","SuperJump","SuperJumpFwd","SuperJumpBack"]
const STAND_UP_FRAMES : int = 4

var _stand_up_timer : int  = 0
var _standing_up    : bool = false

func _ready() -> void:
	state_id = "Crouch"

func enter(_prev: String) -> void:
	frame           = 0
	apply_gravity   = false
	_stand_up_timer = 0
	_standing_up    = false
	fighter.velocity.x = 0.0
	fighter.velocity.y = 0.0
	gate_special   = true
	gate_drive     = true
	gate_overdrive = true
	gate_burst     = true
	gate_barrier   = true
	gate_dash      = false
	fighter.anim_player.play("crouch_down")

func exit() -> void:
	_reset_gates()
	_standing_up    = false
	_stand_up_timer = 0

func update(_delta: float) -> void:
	frame += 1
	fighter.update_facing()

	if not fighter.anim_player.is_playing():
		fighter.anim_player.play("crouch_idle")

	# Released down — begin stand-up
	if "2" not in input_buffer.held_inputs and not _standing_up:
		_standing_up    = true
		_stand_up_timer = STAND_UP_FRAMES
		fighter.anim_player.play("crouch_up")

	if _standing_up:
		if _stand_up_timer > 0:
			_stand_up_timer -= 1
		else:
			state_manager.request("Idle", InputBuffer.PRIORITY["Standing"])

func on_command(command: Dictionary) -> void:
	var cmd  : String = command.get("Command", "")
	var prio : int = InputBuffer.PRIORITY.get(command.get("Priority", ""), 0)
	match cmd:
		"BackDash": state_manager.request("BackDash", prio)
		_ when cmd in JUMP_COMMANDS:
			_request_jump(cmd, prio)

func _request_jump(cmd: String, prio: int) -> void:
	var prejump := state_manager.states.get("Prejump") as ST_Prejump
	if prejump:
		prejump.jump_command = cmd
	state_manager.request("Prejump", prio)
