extends State_Base
class_name St_JumpLanding

const JUMP_COMMANDS := ["Jump","JumpFwd","JumpBack","SuperJump","SuperJumpFwd","SuperJumpBack"]

func _ready() -> void:
	state_id = "JumpLanding"

func enter(_prev: String) -> void:
	frame         = 0
	apply_gravity = false

	fighter.velocity.x = 0.0
	fighter.velocity.y = 0.0
	_reset_gates()
	
	gate_normal    = true
	gate_special   = true
	gate_drive     = true
	gate_overdrive = true
	gate_dash      = true

	fighter.remove_property(Property.Type.Airborne)

	fighter.anim_player.play("Jump/Jump_LandRecov")

func exit() -> void:
	_reset_gates()

func update(_delta: float) -> void:
	frame += 1

	if frame >= cd.landing_recovery and "Jump/Jump_LandRecov" == ap.current_animation:
		state_manager.force_transition("Idle")

func on_command(command: Dictionary) -> void:
	var cmd  : String = command.get("Command", "")
	var prio : int    = InputBuffer.PRIORITY.get(command.get("Priority", ""), 0)

	match cmd:
		"Dash":
			state_manager.request("Dash", prio)
