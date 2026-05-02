extends State_Base
class_name ST_Prejump

var jump_command : String = "Jump"
var _timer       : int    = 0
var _launch_vel_x : float = 0.0
var _launch_vel_y : float = 0.0

func _ready() -> void:
	state_id = "Prejump"

func enter(_prev: String) -> void:
	frame         = 0
	apply_gravity = false
	_timer        = fighter.char_data.prejump
	fighter.velocity.x = 0.0
	fighter.velocity.y = 0.0
	invul_throw    = true
	invul_burst    = true
	gate_special   = true
	gate_burst     = true
	fighter.anim_player.play("prejump")
	_set_launch_velocity()

func exit() -> void:
	_reset_gates()
	jump_command = "Jump"

func update(_delta: float) -> void:
	frame  += 1
	_timer -= 1

func get_transition() -> String:
	if "2" in input_buffer.held_inputs: return "Idle"
	if _timer <= 0:
		_launch()
		return "Airborne"
	return ""

func on_command(command: Dictionary) -> void:
	var cmd  : String = command.get("Command", "")
	var prio : int = InputBuffer.PRIORITY.get(command.get("Priority", ""), 0)
	if cmd in ["Special", "EX Special"]:
		pass # wire to ST_Attack when ready

func _set_launch_velocity() -> void:
	var cd     := fighter.char_data
	var sign_x := 1.0 if fighter.dir_facing == "Right" else -1.0
	match jump_command:
		"Jump":
			_launch_vel_x = 0.0
			_launch_vel_y = cd.jump_velocity
		"JumpFwd":
			_launch_vel_x =  sign_x * cd.jump_fwd_velocity
			_launch_vel_y = cd.jump_velocity
		"JumpBack":
			_launch_vel_x =  sign_x * -cd.jump_bwd_velocity
			_launch_vel_y = cd.jump_velocity
		"SuperJump":
			_launch_vel_x = 0.0
			_launch_vel_y = cd.superjump_velocity
		"SuperJumpFwd":
			_launch_vel_x =  sign_x * cd.superjump_fwd_velocity
			_launch_vel_y = cd.superjump_velocity
		"SuperJumpBack":
			_launch_vel_x =  sign_x * -cd.superjump_bwd_velocity
			_launch_vel_y = cd.superjump_velocity

func _launch() -> void:
	fighter.velocity.x = _launch_vel_x
	fighter.velocity.y = _launch_vel_y
