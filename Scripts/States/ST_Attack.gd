extends State_Base
class_name ST_Attack

## Set this before requesting the Attack state
var hfd : HitboxFrameData = null

func _ready() -> void:
	state_id = "Attack"

func enter(_prev: String) -> void:
	frame         = 0
	apply_gravity = false
	_reset_gates()

	if hfd == null:
		push_error("[ST_Attack] No HitboxFrameData assigned — returning to Idle")
		state_manager.force_transition("Idle")
		return

	hfd.begin(hfd.move_data)
	ap.play(hfd.move_data.move_id)

func exit() -> void:
	_reset_gates()
	if hfd != null:
		hfd.stop()
	hfd = null

func update(_delta: float) -> void:
	frame += 1

	if hfd == null:
		state_manager.force_transition("Idle")
		return

	hfd.tick()

	if frame >= hfd.move_data.total_frames():
		state_manager.force_transition("Idle")

func on_command(_command: Dictionary) -> void:
	pass # Cancel windows wired later
