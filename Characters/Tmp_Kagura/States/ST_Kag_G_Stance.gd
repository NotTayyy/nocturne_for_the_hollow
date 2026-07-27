extends Stance_Base
class_name ST_Kag_G_Stance

func _ready() -> void:
	state_id = "Ground_Stance"

func enter(_prev: String) -> void:
	frame = 0
	recov_timer = 0
	curr_stance = _stance_from_command(entered_via.get("Command", ""))
	phase = StancePhase.Active
	gate_normal = true
	gate_special = true
	gate_drive = true
	
	match curr_stance:
		2:
			fighter.add_property(Property.new(Property.Type.Crouching, -1, "system"))
			

func exit() -> void:
	_reset_gates()
	if fighter.has_property(Property.Type.Crouching):
		fighter.remove_property(Property.Type.Crouching)

func update(_delta: float) -> void:
	frame += 1
	print(phase, ' ', frame)
	
	if frame <= actionable:
		pass
	
	match curr_stance:
		1: ## Neutral
			pass
		2: ## Crouching
			print("Crouching")
		3: ## Forward
			print("Forward")
		_:
			print("You f'd up")
	
	if phase == StancePhase.Recovery:
		recov_timer += 1
		if recov_timer >= recovery:
			state_manager.force_transition("Idle")
	
	if frame >= Stance_Timer:
		phase = StancePhase.Recovery
		#ap.play()

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


func _stance_from_command(cmd: String) -> Stance:
	match cmd:
		"Button D": return Stance.Neutral
		"2D":       return Stance.Crouching
		"6D":       return Stance.Forward
		_:          return Stance.None
