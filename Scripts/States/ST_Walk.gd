extends State_Base
class_name ST_Walk

var _last_forward : bool = true
var forward       : bool = true

func _ready() -> void:
	state_id = "Walk"

func enter(_prev: String) -> void:
	frame         = 0
	apply_gravity = false
	fighter.velocity.y = 0.0
	_last_forward  = "6" in input_buffer.held_inputs
	gate_normal    = true
	gate_special   = true
	gate_drive     = true
	gate_overdrive = true
	gate_jump      = true
	gate_dash      = true
	gate_backdash  = true
	_play_walk_anim()
	if hfd_node != null:
		hfd_node.begin(null)

func exit() -> void:
	_reset_gates()
	fighter.velocity.x = 0.0
	if hfd_node != null:
		hfd_node.stop()

func update(_delta: float) -> void:
	frame += 1
	if hfd_node != null:
		hfd_node.tick()
	var h       := input_buffer.held_inputs
	forward = "6" in h

	# Facing flipped this frame — mirror to correct animation
	if fighter.facing_updated:
		_change_anim()
	if forward == not _last_forward:
		_change_anim()

	var speed := fighter.get_walk_speed(forward)
	fighter.velocity.x = sign_x * speed if forward else -sign_x * speed

	# No direction held — return to idle
	if "6" not in h and "4" not in h:
		state_manager.request("Idle", InputBuffer.PRIORITY["Standing"])
	if "2" in h or "1" in h or "3" in h:
		state_manager.request("Crouch", InputBuffer.PRIORITY["Crouching"])

func on_command(command: Dictionary) -> void:
	var cmd  : String = command.get("Command", "")
	var prio : int    = InputBuffer.PRIORITY.get(command.get("Priority", ""), 0)
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
		"6B":
			_request_attack(command, "Components/FrameData/Cmd_6B")
		"Button A":
			_request_attack(command, "Components/FrameData/Nml_5A")
		"Crouch":
			state_manager.request("Crouch", prio)
		"Dash":
			state_manager.request("Dash", prio)
		"BackDash":
			state_manager.request("BackDash", prio)
		"Button D", "2D", "6D":
			state_manager.request("Ground_Stance", prio)
		_ when cmd in JUMP_COMMANDS:
			_request_jump(cmd, prio)

func _change_anim() -> void:
	_last_forward = not _last_forward
	var curr := ap.current_animation
	if curr in ["Walk/WalkF_Loop", "Walk/WalkB_Loop"]:
		ap.play("Walk/WalkF_Loop" if forward else "Walk/WalkB_Loop")
	else:
		ap.play("Walk/WalkF_Start" if forward else "Walk/WalkB_Start")

func _request_jump(cmd: String, prio: int) -> void:
	var prejump := state_manager.states.get("Prejump") as ST_Prejump
	if prejump: prejump.jump_command = cmd
	state_manager.request("Prejump", prio)

func _play_walk_anim() -> void:
	var loop : String = "Walk/WalkF_Loop" if _last_forward else "Walk/WalkB_Loop"
	if ap.current_animation == loop:
		return
	ap.play("Walk/WalkF_Start" if _last_forward else "Walk/WalkB_Start")
