extends State_Base
class_name ST_Attack

## Set before requesting — points to the HFD for this move
var hfd        : HitboxFrameData = null
var _staged_hfd : HitboxFrameData = null  ## Holds the next HFD during attack-to-attack cancel

## Width of the proximity block warning box (forward-facing from attacker)
@export var proximity_box_width  : float = 400.0
@export var proximity_box_height : float = 200.0

var _proximity_area  : Area2D           = null
var _proximity_shape : CollisionShape2D = null

func _ready() -> void:
	state_id = "Attack"

func enter(_prev: String) -> void:
	frame         = 0
	apply_gravity = false
	_reset_gates()

	# Pick up staged HFD from attack-to-attack cancel
	if _staged_hfd != null:
		hfd         = _staged_hfd
		_staged_hfd = null

	if hfd == null:
		push_error("[ST_Attack] No HitboxFrameData assigned — returning to Idle")
		state_manager.force_transition("Idle")
		return

	hfd.begin(hfd.move_data)

	# Always restart animation from frame 0
	if not hfd.valid_animations.is_empty():
		var anim : String = hfd.valid_animations[0]
		if ap.has_animation(anim):
			ap.stop()
			ap.play(anim)
		else:
			push_warning("[ST_Attack] Animation not found: %s" % anim)
	else:
		push_warning("[ST_Attack] No valid_animations set on HFD: %s" % hfd.name)

	_spawn_proximity_box()

func exit() -> void:
	_reset_gates()
	if hfd != null:
		hfd.stop()
	hfd = null
	_despawn_proximity_box()

func update(_delta: float) -> void:
	frame += 1
	fighter.velocity.x *= cd.friction

	if hfd == null:
		state_manager.force_transition("Idle")
		return

	hfd.tick()
	_apply_self_impulses()

	# Despawn proximity box on hit, block, or when active frames end
	if is_instance_valid(_proximity_area):
		var hit_or_block : bool = hfd.hit_state == HitboxFrameData.HitState.HIT \
							  or hfd.hit_state == HitboxFrameData.HitState.BLOCK
		var in_recovery : bool = hfd.move_data != null \
							  and frame > (hfd.move_data.startup + hfd.move_data.active.reduce(func(a,b): return a+b, 0))
		if hit_or_block or in_recovery:
			_despawn_proximity_box()

	if hfd.move_data != null and frame >= hfd.move_data.total_frames():
		state_manager.force_transition("Idle")

# =============================================================================
# Proximity Block Box
# =============================================================================

func _spawn_proximity_box() -> void:
	_proximity_area  = Area2D.new()
	_proximity_shape = CollisionShape2D.new()

	var rect : RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(proximity_box_width, proximity_box_height)

	_proximity_shape.shape       = rect
	_proximity_shape.debug_color = Color(0.6, 0.0, 1.0, 0.25)  # Purple

	# Offset so box extends forward from attacker's position
	var dir_x : float = 1.0 if fighter.dir_facing == "Right" else -1.0
	_proximity_shape.position = Vector2((proximity_box_width / 2.0) * dir_x, -120.0)

	_proximity_area.add_child(_proximity_shape)
	fighter.add_child(_proximity_area)

	# Use a layer that doesn't interact with hitboxes or hurtboxes
	_proximity_area.collision_layer = 0
	_proximity_area.collision_mask  = 0
	_proximity_area.monitoring      = true
	_proximity_area.monitorable     = false

	_proximity_area.area_entered.connect(_on_proximity_entered)
	_proximity_area.area_exited.connect(_on_proximity_exited)

func _despawn_proximity_box() -> void:
	if is_instance_valid(_proximity_area):
		_proximity_area.queue_free()
	_proximity_area  = null
	_proximity_shape = null

func _on_proximity_entered(area : Area2D) -> void:
	if area.owner == fighter:
		return
	var defender : Fighter = area.owner as Fighter
	if defender == null:
		return
	# Placeholder — tell defender an attack is incoming
	if defender.has_method("notify_proximity_block"):
		defender.notify_proximity_block(true)

func _on_proximity_exited(area : Area2D) -> void:
	if area.owner == fighter:
		return
	var defender : Fighter = area.owner as Fighter
	if defender == null:
		return
	if defender.has_method("notify_proximity_block"):
		defender.notify_proximity_block(false)

# =============================================================================
# Self Impulses
# =============================================================================

func _apply_self_impulses() -> void:
	if hfd == null or hfd.move_data == null:
		return
	var md : MoveData = hfd.move_data
	if md.impulse_x == 0.0 and md.impulse_y == 0.0:
		return
	var in_window : bool = true
	if md.impulse_start != -1 and frame < md.impulse_start: in_window = false
	if md.impulse_end   != -1 and frame > md.impulse_end:   in_window = false
	if not in_window:
		return
	var dir_x : float = 1.0 if fighter.dir_facing == "Right" else -1.0
	fighter.velocity.x += md.impulse_x * dir_x
	fighter.velocity.y += md.impulse_y
	if md.impulse_falloff < 1.0:
		fighter.velocity.x *= md.impulse_falloff
		fighter.velocity.y *= md.impulse_falloff

func on_command(command: Dictionary) -> void:
	if hfd == null or hfd.move_data == null:
		return
	var cmd : String = command.get("Command", "")
	for route : CancelRoute in hfd.move_data.cancel_routes:
		if route == null or route.command != cmd or route.hfd_path == "":
			continue
		if not _cancel_allowed(hfd, command):
			break
		fighter.input_buffer.consume_buffer()
		_request_attack(command, route.hfd_path)
		return
