extends State_Base
class_name ST_Dash

enum Phase { STARTUP, ACTIVE, SKID, RECOVERY }

var _phase      : int    = Phase.STARTUP
var _timer      : int    = 0
var _prev_state : String = "Idle"

func _ready() -> void:
	state_id = "Dash"

func enter(prev: String) -> void:
	frame       = 0
	_prev_state = prev
	_phase      = Phase.STARTUP
	_timer      = fighter.char_data.dash_Startup
	apply_gravity = false
	fighter.velocity.y = 0.0
	_reset_gates()

	match fighter.char_data.dashType:
		CharacterData.DashType.None:
			state_manager.force_transition(_prev_state)
			return
		CharacterData.DashType.Dash:
			fighter.anim_player.play("dash_run_startup")
		CharacterData.DashType.Step:
			fighter.anim_player.play("dash_step_startup")
		CharacterData.DashType.Teleport:
			fighter.anim_player.play("dash_teleport_startup")

func exit() -> void:
	_reset_gates()

func update(_delta: float) -> void:
	frame += 1
	match fighter.char_data.dashType:
		CharacterData.DashType.Dash:      _update_run()
		CharacterData.DashType.Step:     _update_step()
		CharacterData.DashType.Teleport: _update_teleport()
		CharacterData.DashType.None:     return

func get_transition() -> String:
	if fighter.is_airborne: return "Airborne"
	return ""

func on_command(command: Dictionary) -> void:
	var prio : int = InputBuffer.PRIORITY.get(command.get("Priority", ""), 0)
	match command.get("Command", ""):
		"Jump": state_manager.request("Prejump", prio)

func _open_active_gates() -> void:
	gate_special   = true
	gate_drive     = true
	gate_overdrive = true
	gate_burst     = true
	gate_jump      = true

# =============================================================================
# RUN DASH
# =============================================================================
func _update_run() -> void:
	var cd     := fighter.char_data
	var sign_x := 1.0 if fighter.dir_facing == "Right" else -1.0
	_timer -= 1

	match _phase:
		Phase.STARTUP:
			fighter.velocity.x = 0.0
			if _timer <= 0:
				_phase = Phase.ACTIVE
				_open_active_gates()
				fighter.anim_player.play("dash_run")

		Phase.ACTIVE:
			if "6" in input_buffer.held_inputs:
				fighter.velocity.x = move_toward(fighter.velocity.x, sign_x * cd.dash_max, cd.dash_acc)
			else:
				_phase = Phase.SKID
				_timer = cd.dash_skid
				_reset_gates()
				fighter.anim_player.play("dash_run_skid")

		Phase.SKID:
			fighter.velocity.x = move_toward(fighter.velocity.x, 0.0, cd.dash_acc)
			if _timer <= 0:
				state_manager.force_transition("Idle")

# =============================================================================
# STEP DASH
# =============================================================================
func _update_step() -> void:
	var cd     := fighter.char_data
	var sign_x := 1.0 if fighter.dir_facing == "Right" else -1.0
	_timer -= 1

	match _phase:
		Phase.STARTUP:
			fighter.velocity.x = 0.0
			if _timer <= 0:
				_phase = Phase.ACTIVE
				_timer = cd.dash_int
				_open_active_gates()
				fighter.velocity.x = sign_x * cd.dash_max
				fighter.anim_player.play("dash_step")

		Phase.ACTIVE:
			fighter.velocity.x = sign_x * cd.dash_max
			if _timer <= 0:
				_phase = Phase.RECOVERY
				_timer = cd.dash_skid
				_reset_gates()
				fighter.velocity.x = 0.0
				fighter.anim_player.play("dash_step_recovery")

		Phase.RECOVERY:
			if _timer <= 0:
				state_manager.force_transition("Idle")

# =============================================================================
# TELEPORT DASH
# =============================================================================
func _update_teleport() -> void:
	_timer -= 1

	match _phase:
		Phase.STARTUP:
			fighter.velocity.x = 0.0
			if _timer <= 0:
				_enter_teleport_vanish()

		Phase.ACTIVE:
			fighter.velocity.x = 0.0
			if _timer <= 0:
				_exit_teleport_vanish()

		Phase.RECOVERY:
			fighter.velocity.x = 0.0
			if _timer <= 0:
				state_manager.force_transition("Idle")

func _enter_teleport_vanish() -> void:
	_phase = Phase.ACTIVE
	_timer = fighter.char_data.backdash_invul
	var sign_x := 1.0 if fighter.dir_facing == "Right" else -1.0
	fighter.global_position.x += sign_x * fighter.char_data.dash_int
	fighter.pushbox.set_deferred("monitoring", false)
	fighter.pushbox.set_deferred("monitorable", false)
	fighter.pushbox_shape.set_deferred("disabled", true)
	fighter.char_sprite.visible = false
	invul_all = true

func _exit_teleport_vanish() -> void:
	_phase = Phase.RECOVERY
	_timer = fighter.char_data.dash_skid
	fighter.pushbox.set_deferred("monitoring", true)
	fighter.pushbox.set_deferred("monitorable", true)
	fighter.pushbox_shape.set_deferred("disabled", false)
	fighter.char_sprite.visible = true
	invul_all = false
	_open_active_gates()
	fighter.anim_player.play("dash_teleport_recovery")
