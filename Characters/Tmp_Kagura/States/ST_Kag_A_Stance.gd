extends Stance_Base
class_name ST_Kag_A_Stance


func _ready() -> void:
	state_id = "Neutral_Stance"

func enter(_prev: String) -> void:
	pass
	# fighter.anim_player.play("anim_name")

func exit() -> void:
	_reset_gates()

func update(_delta: float) -> void:
	frame += 1
	
	#if frame >= Stance_Timer:
		#state_manager.force_transition("Idle")

func on_command(command: Dictionary) -> void:
	var cmd  : String = command.get("Command", "")
	var prio : int    = InputBuffer.PRIORITY.get(command.get("Priority", ""), 0)

	match cmd:
		"4D":
			input_buffer.consume_buffer()
			phase = StancePhase.Recovery
			print(phase, ' ', frame, " Changed ")
		_:
			pass
