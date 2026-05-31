extends State_Base
class_name StKag6d

# TODO: Add any state-specific variables here
# var _timer : int = 0

const JUMP_COMMANDS := ["Jump","JumpFwd","JumpBack","SuperJump","SuperJumpFwd","SuperJumpBack"]

func _ready() -> void:
	state_id = "Template"   # TODO: rename to match scene node name

func enter(_prev: String) -> void:
	frame         = 0
	apply_gravity = false   # TODO: set true if aerial state

	# TODO: Set velocity if needed
	# fighter.velocity.x = 0.0
	# fighter.velocity.y = 0.0

	# TODO: Set cancel gates
	# All closed by default from _reset_gates() — open only what applies
	_reset_gates()
	# gate_self      = true
	# gate_special   = true
	# gate_drive     = true
	# gate_overdrive = true
	# gate_jump      = true
	# gate_rapid     = true
	# gate_dash      = true
	# gate_backdash  = true
	# gate_burst     = true
	# gate_barrier   = true

	# TODO: Set invul flags if needed
	# invul_strike     = true
	# invul_throw      = true
	# invul_head       = true
	# invul_foot       = true
	# invul_projectile = true
	# invul_burst      = true
	# invul_all        = true

	# TODO: Add properties if needed
	# fighter.add_property(Property.new("PropertyName", duration, "self", value))

	# TODO: Play animation
	# fighter.anim_player.play("anim_name")

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
