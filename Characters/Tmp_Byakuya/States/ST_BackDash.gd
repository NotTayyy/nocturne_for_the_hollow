extends State_Base
class_name ST_BackDash

enum Phase { INVUL, TRAVEL, RECOVERY }

var _phase      : int    = Phase.INVUL
var _timer      : int    = 0
var _velocity_x : float  = 0.0
var _prev_state : String = "Idle"

func _ready() -> void:
	state_id = "BackDash"

func enter(prev: String) -> void:
	frame       = 0
	_prev_state = prev
	apply_gravity = false
	fighter.velocity.y = 0.0
	_reset_gates()

	var cd := fighter.char_data

	match cd.backdash_type:
		CharacterData.BackDashType.Step:
			state_manager.force_transition(_prev_state)
			return
		_:
			_phase = Phase.INVUL
			_timer = cd.backdash_invul
			var sign_x := 1.0 if fighter.dir_facing == "Right" else -1.0
			_velocity_x = -sign_x * (float(cd.backdash_distance) / float(cd.backdash_duration))
			invul_strike = true
			invul_throw  = true
			fighter.anim_player.play("backdash")

func exit() -> void:
	_reset_gates()

func update(_delta: float) -> void:
	frame += 1
	match fighter.char_data.backdash_type:
		CharacterData.BackDashType.Dash: _update_Dash()
		CharacterData.BackDashType.Step: _update_step()
		CharacterData.BackDashType.Teleport: _update_teleport()

func get_transition() -> String:
	if fighter.is_airborne: return "Airborne"
	return ""

func on_command(command: Dictionary) -> void:
	pass   # backdash ignores all commands until recovery ends

func _open_recovery_gates() -> void:
	gate_special   = true
	gate_jump      = true
	gate_burst     = true

func _update_step() -> void:
	_timer -= 1

	match _phase:
		Phase.INVUL:
			fighter.velocity.x = _velocity_x
			if _timer <= 0:
				_phase = Phase.TRAVEL
				_timer = fighter.char_data.backdash_duration - fighter.char_data.backdash_invul
				invul_strike = false
				invul_throw  = false

		Phase.TRAVEL:
			fighter.velocity.x = _velocity_x
			if _timer <= 0:
				_phase = Phase.RECOVERY
				_timer = 8
				fighter.velocity.x = 0.0
				_open_recovery_gates()
				fighter.anim_player.play("backdash_recovery")

		Phase.RECOVERY:
			if _timer <= 0:
				state_manager.force_transition("Idle")

func _update_Dash() -> void:
	_phase = Phase.INVUL
	
func _update_teleport() -> void:
	_timer -= 1

	match _phase:
		Phase.INVUL:
			fighter.velocity.x = 0.0
			if _timer <= 0:
				_enter_vanish()

		Phase.TRAVEL:
			fighter.velocity.x = 0.0
			if _timer <= 0:
				_exit_vanish()

		Phase.RECOVERY:
			if _timer <= 0:
				state_manager.force_transition("Idle")

func _enter_vanish() -> void:
	_phase = Phase.TRAVEL
	_timer = fighter.char_data.backdash_invul
	var sign_x := 1.0 if fighter.dir_facing == "Right" else -1.0
	fighter.global_position.x -= sign_x * fighter.char_data.backdash_distance
	fighter.pushbox.set_deferred("monitoring", false)
	fighter.pushbox.set_deferred("monitorable", false)
	fighter.pushbox_shape.set_deferred("disabled", true)
	fighter.char_sprite.visible = false
	invul_all = true

func _exit_vanish() -> void:
	_phase = Phase.RECOVERY
	_timer = 8
	fighter.pushbox.set_deferred("monitoring", true)
	fighter.pushbox.set_deferred("monitorable", true)
	fighter.pushbox_shape.set_deferred("disabled", false)
	fighter.char_sprite.visible = true
	invul_all = false
	_open_recovery_gates()
	fighter.anim_player.play("backdash_recovery")
