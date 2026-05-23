extends State_Base
class_name ST_AirBlock

var barrier_active : bool = false

func _ready() -> void:
	state_id = "AirBlock"

func enter(_prev: String) -> void:
	frame          = 0
	apply_gravity  = true
	barrier_active = false

func exit() -> void:
	barrier_active = false
	_reset_gates()

func update(_delta: float) -> void:
	frame += 1
	fighter.velocity.x *= cd.friction

	# Landing — transition to grounded block state, carry barrier over
	if fighter.is_on_floor():
		var held        := fighter.input_buffer.held_inputs
		var want_crouch : bool = "1" in held
		var was_barrier : bool = barrier_active
		if want_crouch:
			state_manager.force_transition("CrouchBlock")
		else:
			state_manager.force_transition("StandBlock")
		# Re-apply barrier_active on the new state if it was active
		if was_barrier and "barrier_active" in state_manager.active_state:
			state_manager.active_state.barrier_active = true
		return

	# No blockstun and no barrier — exit to airborne
	if not fighter.has_property(Property.Type.Blockstun) and not barrier_active:
		state_manager.force_transition("Airborne")

func on_command(_command: Dictionary) -> void:
	pass
