extends State_Base
class_name ST_Crouch

const JUMP_COMMANDS := ["SuperJump","SuperJumpFwd","SuperJumpBack"]

const STAND_UP_FRAMES : int = 8

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
	gate_normal    = true
	gate_special   = true
	gate_drive     = true
	gate_overdrive = true
	gate_jump      = true
	ap.play("Crouch/Crouch_Start")
	fighter.add_property(Property.new(Property.Type.Crouching, -1, "system"))
	if hfd_node != null:
		hfd_node.begin(null)

func exit() -> void:
	_reset_gates()
	_standing_up    = false
	_stand_up_timer = 0
	fighter.remove_property(Property.Type.Crouching)
	if hfd_node != null:
		hfd_node.stop()

func update(_delta: float) -> void:
	frame += 1
	if hfd_node != null:
		hfd_node.tick()
	
	if fighter.facing_updated == true:
		ap.play("Crouch/Crouch_Turn")
	
	if not ap.is_playing():
		ap.play("Crouch/Crouch_Loop")

	# Released down — begin stand-up
	if "2" not in input_buffer.held_inputs and not _standing_up:
		_standing_up    = true
		_stand_up_timer = STAND_UP_FRAMES
		ap.play("Crouch/Crouch_End")

	if _standing_up:
		if _stand_up_timer > 0:
			_stand_up_timer -= 1
		else:
			state_manager.request("Idle", InputBuffer.PRIORITY["Standing"])

func on_command(command: Dictionary) -> void:
	var cmd   : String = command.get("Command", "")
	var _prio : int    = InputBuffer.PRIORITY.get(command.get("Priority", ""), 0)
	match cmd:
		_ when cmd in JUMP_COMMANDS:
			_request_SuperJump(cmd, _prio)
			
func _request_SuperJump(cmd: String, prio: int) -> void:
	var prejump := state_manager.states.get("Prejump") as ST_Prejump
	if prejump:
		prejump.jump_command = cmd
	state_manager.request("Prejump", prio)
