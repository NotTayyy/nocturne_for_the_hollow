extends State_Base
class_name ST_Dash

enum Phase { STARTUP, ACTIVE, RECOVERY }

var _phase      : int    = Phase.STARTUP
var _timer      : int    = 0
var _prev_state : String = "Idle"
var _min_dash_timer : int = 0

func _ready() -> void:
	state_id = "Dash"

func enter(prev: String) -> void:
	frame         = 0
	_prev_state   = prev
	_min_dash_timer = fighter.char_data.dash_min
	apply_gravity = false
	_reset_gates()
	fighter.velocity.y = 0.0

	match fighter.char_data.dashType:
		CharacterData.DashType.None:
			state_manager.force_transition(_prev_state)
			return
		CharacterData.DashType.Dash:
			_phase = Phase.ACTIVE
			gate_self      = true
			gate_special   = true
			gate_drive     = true
			gate_overdrive = true
			gate_jump      = true
			gate_barrier   = true
			fighter.anim_player.play("dash_Dash")
		CharacterData.DashType.Step:
			_phase = Phase.STARTUP
			_timer = fighter.char_data.step_Startup
			fighter.anim_player.play("dash_step_startup")
		CharacterData.DashType.Teleport:
			_phase = Phase.STARTUP
			_timer = fighter.char_data.step_Startup
			fighter.anim_player.play("dash_teleport_startup")

func exit() -> void:
	_reset_gates()

func update(_delta: float) -> void:
	frame += 1
	match fighter.char_data.dashType:
		CharacterData.DashType.Dash:      _update_Dash()
		CharacterData.DashType.Step:     _update_step()
		CharacterData.DashType.Teleport: _update_teleport()

func on_command(command: Dictionary) -> void:
	var cmd  : String = command.get("Command", "")
	var prio : int = InputBuffer.PRIORITY.get(command.get("Priority", ""), 0)
	match cmd:
		"Jump","JumpFwd","JumpBack","SuperJump","SuperJumpFwd","SuperJumpBack":
			# Velocity carries — ST_Prejump will add to it
			var prejump := state_manager.states.get("Prejump") as ST_Prejump
			if prejump: prejump.jump_command = cmd
			state_manager.request("Prejump", prio)
		_ when command.get("Priority","") in ["Special","EX Special","Ultimate Art"]:
			pass # wire to ST_Attack when ready


# =============================================================================
# Dash DASH
# =============================================================================
func _update_Dash() -> void:
	if _min_dash_timer > 0:
		_min_dash_timer -= 1
	fighter.velocity.x = move_toward(
		fighter.velocity.x,
		sign_x * cd.dash_max,
		cd.dash_acc
	)
	# Only allow skid after minimum distance committed
	if _min_dash_timer <= 0 and "6" not in input_buffer.held_inputs:
		state_manager.force_transition("RunSkid")

# =============================================================================
# STEP DASH
# =============================================================================
func _update_step() -> void:
	_timer -= 1

	match _phase:
		Phase.STARTUP:
			fighter.velocity.x = 0.0
			if _timer <= 0:
				_phase = Phase.ACTIVE
				_timer = cd.step_Duration
				fighter.velocity.x = sign_x * cd.step_distance
				fighter.anim_player.play("dash_step")

		Phase.ACTIVE:
			fighter.velocity.x = sign_x * cd.step_distance
			if _timer <= 0:
				state_manager.force_transition("Idle")

# =============================================================================
# TELEPORT DASH
# =============================================================================
func _update_teleport() -> void:
	_timer -= 1
	
	invul_all = (
		cd.backdash_invul_end > 0 and 
		frame >= cd.backdash_invul_start and 
		frame <= cd.backdash_invul_end
		)

	match _phase:
		Phase.STARTUP:
			fighter.velocity.x = 0.0
			if _timer <= 0:
				_enter_teleport_vanish()

		Phase.ACTIVE:
			if _timer <= 0:
				_exit_teleport_vanish()

		Phase.RECOVERY:
			fighter.velocity.x = 0.0
			_open_gate_neutral()
			if _timer <= 0:
				state_manager.force_transition("Idle")

func _enter_teleport_vanish() -> void:
	_phase = Phase.ACTIVE
	_timer = cd.step_Duration
	fighter.global_position.x += sign_x * cd.step_distance
	fighter.pushbox.set_deferred("monitoring", false)
	fighter.pushbox.set_deferred("monitorable", false)
	fighter.collision_Box.set_deferred("disabled", true)
	fighter.char_sprite.visible = false

func _exit_teleport_vanish() -> void:
	_phase = Phase.RECOVERY
	_timer = cd.step_recovery
	fighter.pushbox.set_deferred("monitoring", true)
	fighter.pushbox.set_deferred("monitorable", true)
	fighter.collision_Box.set_deferred("disabled", false)
	fighter.char_sprite.visible = true
	fighter.anim_player.play("dash_teleport_recovery")
