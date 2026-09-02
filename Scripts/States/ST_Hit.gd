extends State_Base
class_name ST_Hit_Lv1

func _ready() -> void:
	state_id = "St_Hit"

func enter(_prev: String) -> void:
	var reult : HitResult = transition_payload
	frame         = 0
	if fighter.has_property(Property.Type.Airborne, "Airborn"):
		apply_gravity = true   # TODO: set true if aerial state
	else:
		apply_gravity = false

	_reset_gates()

	gate_overdrive = true
	gate_burst     = true

	fighter.anim_player.play("anim_name")

func exit() -> void:
	_reset_gates()

	# TODO: Remove any properties added in enter()
	# fighter.remove_property("PropertyName")

func update(_delta: float) -> void:
	frame += 1

	# TODO: Per-frame logic — write velocity here
	# fighter.velocity.x = sign_x * some_speed
	# fighter.velocity.y = ...

	# TODO: Per-frame gate updates if gates change mid-state
	# gate_special = frame >= 10

	# TODO: Per-frame invul window updates if needed
	# invul_strike = frame >= cd.some_invul_start and frame <= cd.some_invul_end

	# TODO: Timer-based self-transitions
	# if frame >= cd.some_duration:
	#     state_manager.force_transition("Idle")

func on_command(command: Dictionary) -> void:
	var cmd  : String = command.get("Command", "")
	var prio : int    = InputBuffer.PRIORITY.get(command.get("Priority", ""), 0)

	match cmd:
		# TODO: Handle jump commands if this state allows jumping
		# _ when cmd in JUMP_COMMANDS:
		#     var prejump := state_manager.states.get("Prejump") as ST_Prejump
		#     if prejump: prejump.jump_command = cmd
		#     state_manager.request("Prejump", prio)

		# TODO: Handle other commands
		# "Dash":
		#     state_manager.request("Dash", prio)
		"Burst":
			state_manager.request("Burst", prio)

		# TODO: Wire to ST_Attack when ready
		# _ when command.get("Priority","") in ["Normal","Command Normal","Special","EX Special","Drive","Ultimate Art"]:
		#     pass
		_:
			pass
