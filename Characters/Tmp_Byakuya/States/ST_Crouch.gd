extends State_Base
class_name ST_Crouch

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
	gate_self      = true
	gate_special   = true
	gate_drive     = true
	gate_overdrive = true
	gate_jump      = true
	gate_rapid     = true
	gate_burst     = true
	gate_barrier   = true
	gate_dash      = false   # cannot dash from crouch
	gate_backdash  = true
	fighter.anim_player.play("crouch_down")

func exit() -> void:
	_reset_gates()
	_standing_up    = false
	_stand_up_timer = 0

func update(delta: float) -> void:
	frame += 1
	fighter.update_facing()
	if not _standing_up and not fighter.anim_player.is_playing():
		fighter.anim_player.play("crouch_idle")
	if _stand_up_timer > 0:
		_stand_up_timer -= 1

func get_transition() -> String:
	var h := input_buffer.held_inputs
	if fighter.is_airborne: return "Airborne"
	if "8" in h:            return "Prejump"
	if "2" not in h and not _standing_up:
		_standing_up    = true
		_stand_up_timer = STAND_UP_FRAMES
		fighter.anim_player.play("crouch_up")
	if _standing_up and _stand_up_timer <= 0:
		return "Idle"
	return ""

func on_command(command: Dictionary) -> void:
	var cmd  : String = command.get("Command", "")
	var prio : int    = InputBuffer.PRIORITY.get(command.get("Priority", ""), 0)
	match cmd:
		"BackDash": state_manager.request("BackDash", prio)
		"Jump", "Super Jump":
			var prejump := state_manager.states.get("Prejump") as ST_Prejump
			if prejump:
				prejump.is_superjump = (cmd == "Super Jump")
			state_manager.request("Prejump", prio)
