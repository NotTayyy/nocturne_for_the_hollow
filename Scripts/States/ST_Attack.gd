extends State_Base
class_name ST_Attack

## Set before requesting — points to the HFD for this move
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

	# Play animation from valid_animations[0]
	if not hfd.valid_animations.is_empty():
		safe_play(hfd.valid_animations[0])
	else:
		push_warning("[ST_Attack] No valid_animations set on HFD: %s" % hfd.name)

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
	_apply_self_impulses()

	if hfd.move_data != null and frame >= hfd.move_data.total_frames():
		state_manager.force_transition("Idle")

func _apply_self_impulses() -> void:
	if hfd == null or hfd.move_data == null:
		return
	for impulse : Dictionary in hfd.move_data.self_impulses:
		var s : int = impulse.get("start", -1)
		var e : int = impulse.get("end",   -1)
		var in_window : bool = true
		if s != -1 and frame < s: in_window = false
		if e != -1 and frame > e: in_window = false
		if not in_window:
			continue
		var ix      : float = impulse.get("x",       0.0)
		var iy      : float = impulse.get("y",       0.0)
		var falloff : float = impulse.get("falloff", 1.0)
		# Apply facing direction to X
		var dir_x : float = 1.0 if fighter.dir_facing == "Right" else -1.0
		fighter.velocity.x += ix * dir_x
		fighter.velocity.y += iy
		# Apply falloff to existing velocity
		if falloff < 1.0:
			fighter.velocity.x *= falloff
			fighter.velocity.y *= falloff

func on_command(command: Dictionary) -> void:
	pass # Cancel routing wired later via MoveData.cancel_windows
