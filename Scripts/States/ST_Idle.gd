extends State_Base
class_name ST_Idle

const JUMP_COMMANDS := ["Jump","JumpFwd","JumpBack","SuperJump","SuperJumpFwd","SuperJumpBack"]

var _chance  : int            = 10

func _ready() -> void:
	state_id = "Idle"

func enter(_prev: String) -> void:
	frame         = 0
	apply_gravity = false
	fighter.velocity.y = 0.0
	gate_self      = true
	gate_special   = true
	gate_drive     = true
	gate_overdrive = true
	gate_jump      = true
	gate_dash      = true
	gate_backdash  = true
	gate_barrier   = true
	ap.play("Idle/Idle")
	if hfd_node != null:
		hfd_node.begin(null)

func exit() -> void:
	_reset_gates()
	if hfd_node != null:
		hfd_node.stop()

func update(_delta: float) -> void:
	frame += 1
	fighter.velocity.x *= cd.friction
	var h := input_buffer.held_inputs
	if hfd_node != null:
		hfd_node.tick()
	
	if fighter.facing_updated == true:
		ap.play("Idle/Idle_Turn")
	 
	if frame % 60 == 0:
		_chance += 10
		
		if randi_range(1, 100) <= _chance:
			ap.play("Idle/Idle_Goad")
			_chance = -100
	
	if "2" in h:
		state_manager.request("Crouch", InputBuffer.PRIORITY["Crouching"])
	if "4" in h or "6" in h:
		state_manager.request("Walk", InputBuffer.PRIORITY["Walking"])

func to_idle():
	ap.play("Idle/Idle")

func on_command(command: Dictionary) -> void:
	var cmd  : String = command.get("Command", "")
	var prio : int = InputBuffer.PRIORITY.get(command.get("Priority", ""), 0)
	match cmd:
		"Button A":
			_request_attack(command, "Components/FrameData/Nml_5A")
		"Button B":
			_request_attack(command, "Components/FrameData/Nml_5B")
		"Button C":
			_request_attack(command, "Components/FrameData/Nml_5C")
		"Button D":
			_request_attack(command, "Components/FrameData/Nml_5D")
		"6A":
			_request_attack(command, "Components/FrameData/Cmd_6A")
		"Walk", "WalkBack":
			state_manager.request("Walk", prio)
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
