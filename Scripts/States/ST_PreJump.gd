extends State_Base
class_name ST_Prejump

var jump_command : String = "Jump"
var _timer       : int    = 0
var _launch_vel_x : float = 0.0
var _launch_vel_y : float = 0.0
var JS            : String = "Jump"
var friction      : float  = 0.5

func _ready() -> void:
	state_id = "Prejump"

func enter(_prev: String) -> void:
	frame         = 0
	apply_gravity = false
	_timer        = fighter.char_data.prejump
	fighter.velocity.y = 0.0
	invul_throw    = true
	invul_burst    = true
	gate_special   = true
	gate_burst     = true
	ap.play("Jump/Jump_Pre")
	_set_launch_velocity()

func exit() -> void:
	_reset_gates()
	jump_command = "Jump"

func update(_delta: float) -> void:
	frame  += 1
	_timer -= 1
	
	if _timer <= 0:
		_launch()

func on_command(command: Dictionary) -> void:
	var cmd  : String = command.get("Command", "")
	var _prio : int = InputBuffer.PRIORITY.get(command.get("Priority", ""), 0)
	if cmd in ["Special", "EX Special"]:
		pass # wire to ST_Attack when ready

func _set_launch_velocity() -> void:
	match jump_command:
		"Jump":
			_launch_vel_x = 0.0
			_launch_vel_y = cd.jump_velocity
			JS = "Jump"
		"JumpFwd":
			_launch_vel_x =  sign_x * cd.jump_fwd_velocity
			_launch_vel_y = cd.jump_velocity
			JS = "Jump"
		"JumpBack":
			_launch_vel_x =  sign_x * -cd.jump_bwd_velocity
			_launch_vel_y = cd.jump_velocity
			JS = "Jump"
		"SuperJump":
			_launch_vel_x = 0.0
			_launch_vel_y = cd.superjump_velocity
			JS = "Super Jump"
		"SuperJumpFwd":
			_launch_vel_x =  sign_x * cd.superjump_fwd_velocity
			_launch_vel_y = cd.superjump_velocity
			JS = "Super Jump"
		"SuperJumpBack":
			_launch_vel_x =  sign_x * -cd.superjump_bwd_velocity
			_launch_vel_y = cd.superjump_velocity
			JS = "Super Jump"

func _launch() -> void:
	fighter.velocity.x = (fighter.velocity.x * friction) + _launch_vel_x 
	fighter.velocity.y = _launch_vel_y
	state_manager.request("Airborne", InputBuffer.PRIORITY[JS])
