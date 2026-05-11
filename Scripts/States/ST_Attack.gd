extends State_Base
class_name ST_Attack

## Set this before requesting the Attack state
var hfd : HitboxFrameData = null
var md  : MoveData        = null

func _ready() -> void:
	state_id = "Attack"
	

func enter(_prev: String) -> void:
	md = hfd.move_data
	frame         = 0
	apply_gravity = false
	_reset_gates()

	if hfd == null:
		push_error("[ST_Attack] No HitboxFrameData assigned — returning to Idle")
		state_manager.force_transition("Idle")
		return

	hfd.begin(md)
	if md.anim_path != "":
		ap.play(md.anim_path)
	else:
		push_warning("No Animation found for ", md.move_name)

func exit() -> void:
	_reset_gates()
	if hfd != null:
		hfd.stop()
	hfd = null

func update(_delta: float) -> void:
	frame += 1
	fighter.velocity.x *= cd.friction

	if hfd == null:
		state_manager.force_transition("Idle")
		return

	hfd.tick()

	if frame >= md.total_frames():
		state_manager.force_transition("Idle")

func on_command(_command: Dictionary) -> void:
	pass # Cancel windows wired later
