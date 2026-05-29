extends State_Base
class_name ST_StandBlock

var barrier_active : bool = false

func _ready() -> void:
	state_id = "StandBlock"

func enter(_prev: String) -> void:
	frame              = 0
	apply_gravity      = false
	barrier_active     = false
	ap.play("Idle/Idle")  # Placeholder — replace with block animation

func exit() -> void:
	barrier_active = false
	_reset_gates()

func update(_delta: float) -> void:
	frame += 1
	fighter.velocity.x *= cd.friction
	# Stay in block while barrier is active OR while in blockstun
	if not fighter.has_property(Property.Type.Blockstun) and not barrier_active:
		state_manager.force_transition("Idle")

func on_command(_command: Dictionary) -> void:
	pass
