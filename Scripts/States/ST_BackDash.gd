extends State_Base
class_name ST_BackDash

enum Phase { STARTUP, ACTIVE, RECOVERY }

var _phase      : int    = Phase.STARTUP
var _timer      : int    = 0
var _prev_state : String = "Idle"
var _min_dash_timer : int = 0
var _friction_offset : float = 0.05

func _ready() -> void:
	state_id = "BackDash"

func enter(prev: String) -> void:
	frame              = 0
	_prev_state   = prev
	_min_dash_timer = cd.dash_min
	apply_gravity      = false
	fighter.velocity.y = 0.0
	_reset_gates()
	ap.play("Dash/DashBack")

	match cd.backdash_type:
		CharacterData.DashType.Dash:
			_phase = Phase.ACTIVE
			gate_self      = true
			gate_special   = true
			gate_drive     = true
			gate_overdrive = true
			gate_jump      = true
			gate_barrier   = true
		
		CharacterData.DashType.Step:
			_phase = Phase.STARTUP
			_timer = cd.backdash_startup
		
		CharacterData.DashType.Teleport:
			_phase = Phase.STARTUP
			_timer = cd.backdash_startup

func exit() -> void:
	_reset_gates()
	fighter.remove_property(Property.Type.PAirborne)

func update(_delta: float) -> void:
	frame += 1

	# Invul window
	invul_all = (
		cd.backdash_invul_end > 0 and 
		frame >= cd.backdash_invul_start and 
		frame <= cd.backdash_invul_end
		)

	match cd.backdash_type:
		CharacterData.BackDashType.Step:      _update_step()
		CharacterData.BackDashType.Dash:      _update_dash()
		CharacterData.BackDashType.Teleport:  _update_teleport()

func on_command(command: Dictionary) -> void:
	var prio : int = InputBuffer.PRIORITY.get(command.get("Priority", ""), 0)
	if command.get("Command", "") == "Burst":
		state_manager.request("Burst", prio)

# =============================================================================
# STEP
# =============================================================================
func _update_step() -> void:
	_timer -= 1
	
	var in_window := (cd.backdash_airborne_end > 0 and
		frame >= cd.backdash_airborne_start and
		frame <= cd.backdash_airborne_end)

	if in_window:
		if not fighter.has_property(Property.Type.PAirborne):
			fighter.add_property(Property.new(Property.Type.PAirborne, -1, "self"))
		invul_foot = true
	else:
		fighter.remove_property(Property.Type.PAirborne)
		invul_foot = false

	match _phase:
		Phase.STARTUP:
			fighter.velocity.x = 0.0
			if _timer <= 0:
				_phase = Phase.ACTIVE
				_timer = cd.backdash_duration

		Phase.ACTIVE:
			fighter.velocity.x = -sign_x * cd.backdash_distance
			if _timer <= 0:
				_phase = Phase.RECOVERY
				_timer = cd.backdash_recovery
				
		Phase.RECOVERY:
			fighter.velocity.x *= cd.friction - _friction_offset
			if _timer <= 0:
				state_manager.force_transition("Idle")

func _update_dash() -> void:
	if _min_dash_timer > 0:
		_min_dash_timer -= 1
	fighter.velocity.x = move_toward(
		fighter.velocity.x,
		-sign_x * cd.dash_max,
		cd.dash_acc
	)
	# Only allow skid after minimum distance committed
	if _min_dash_timer <= 0 and "4" not in input_buffer.held_inputs:
		state_manager.force_transition("RunSkid")

func _update_teleport() -> void:
	_timer -= 1

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
			invul_all = false

			if _timer <= 0:
				state_manager.force_transition("Idle")

func _enter_teleport_vanish() -> void:
	_phase = Phase.ACTIVE
	_timer = cd.backdash_duration
	fighter.global_position.x += -sign_x * cd.backdash_distance
	fighter.pushbox.set_deferred("monitoring", false)
	fighter.pushbox.set_deferred("monitorable", false)
	fighter.collision_Box.set_deferred("disabled", true)	
	fighter.char_sprite.visible = false


func _exit_teleport_vanish() -> void:
	_phase = Phase.RECOVERY
	_timer = cd.backdash_recovery
	_open_gate_neutral()
	fighter.pushbox.set_deferred("monitoring", true)
	fighter.pushbox.set_deferred("monitorable", true)
	fighter.collision_Box.set_deferred("disabled", false)
	fighter.char_sprite.visible = true
	ap.play("dash_teleport_recovery")
